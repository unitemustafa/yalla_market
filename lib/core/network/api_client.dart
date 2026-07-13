import 'package:dio/dio.dart';

import '../session/account_inactive_notifier.dart';
import '../session/session_deadline_controller.dart';
import '../session/session_expired_notifier.dart';
import '../session/session_metadata.dart';
import '../storage/token_store.dart';
import 'api_endpoints.dart';
import 'dio_factory.dart';

class ApiClient {
  ApiClient({
    Dio? dio,
    Dio? refreshDio,
    SessionExpiredNotifier? sessionExpiredNotifier,
    AccountInactiveNotifier? accountInactiveNotifier,
    SessionDeadlineController? sessionDeadlineController,
    required TokenStore tokenStore,
  }) : _dio = dio ?? DioFactory.create(),
       _tokenStore = tokenStore,
       _accountInactiveNotifier =
           accountInactiveNotifier ?? AccountInactiveNotifier.instance,
       _refreshDio = refreshDio ?? Dio(DioFactory.baseOptions()),
       _sessionDeadlineController =
           sessionDeadlineController ??
           SessionDeadlineController(
             tokenStore: tokenStore,
             sessionExpiredNotifier:
                 sessionExpiredNotifier ?? SessionExpiredNotifier.instance,
           ) {
    _dio.interceptors.add(
      InterceptorsWrapper(onRequest: _onRequest, onError: _onError),
    );
  }

  final Dio _dio;
  final Dio _refreshDio;
  final TokenStore _tokenStore;
  final AccountInactiveNotifier _accountInactiveNotifier;
  final SessionDeadlineController _sessionDeadlineController;
  Future<StoredAuthTokens>? _refreshInFlight;

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final response = await _dio.get<Object?>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
    return _unwrap<T>(response.data);
  }

  Future<T> post<T>(String path, {Object? data, Options? options}) async {
    final response = await _dio.post<Object?>(
      path,
      data: data,
      options: options,
    );
    return _unwrap<T>(response.data);
  }

  Future<T> patch<T>(String path, {Object? data, Options? options}) async {
    final response = await _dio.patch<Object?>(
      path,
      data: data,
      options: options,
    );
    return _unwrap<T>(response.data);
  }

  Future<T> put<T>(String path, {Object? data, Options? options}) async {
    final response = await _dio.put<Object?>(
      path,
      data: data,
      options: options,
    );
    return _unwrap<T>(response.data);
  }

  Future<T> delete<T>(String path, {Object? data, Options? options}) async {
    final response = await _dio.delete<Object?>(
      path,
      data: data,
      options: options,
    );
    return _unwrap<T>(response.data);
  }

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra['skipAuth'] == true) {
      handler.next(options);
      return;
    }
    if (_accountInactiveNotifier.isInactive &&
        options.extra['allowAfterInactive'] != true) {
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.cancel,
          error: 'account_inactive',
        ),
      );
      return;
    }

    try {
      var tokens = await _tokenStore.read();
      if (tokens != null) {
        final usable = await _sessionDeadlineController.activate(tokens);
        if (!usable) {
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.cancel,
            error: 'session_expired',
          );
        }
        if (tokens.accessExpiresSoon(DateTime.now()) &&
            !_isRefreshRequest(options)) {
          tokens = await _refreshTokens(tokens);
        }
        _synchronizeAuthRequest(options, tokens);
        options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
      }
    } catch (error) {
      if (!_accountInactiveNotifier.isInactive) {
        await _expireSession();
      }
      handler.reject(
        error is DioException
            ? error
            : DioException(
                requestOptions: options,
                error: error,
                type: DioExceptionType.unknown,
              ),
      );
      return;
    }

    handler.next(options);
  }

  Future<void> _onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    if (_isAccountInactiveResponse(error.response?.data)) {
      if (_isClientLoginRequest(error.requestOptions)) {
        await _sessionDeadlineController.clearSession();
      } else {
        await _disableAccount();
      }
      handler.next(error);
      return;
    }

    final request = error.requestOptions;
    final alreadyRetried = request.extra['authRetried'] == true;
    if (error.response?.statusCode != 401 || _isRefreshRequest(request)) {
      handler.next(error);
      return;
    }
    if (alreadyRetried) {
      await _expireSession();
      handler.next(error);
      return;
    }

    final tokens = await _tokenStore.read();
    if (tokens == null) {
      handler.next(error);
      return;
    }

    try {
      if (!await _sessionDeadlineController.activate(tokens)) {
        handler.next(error);
        return;
      }
      final requestAuthorization = request.headers['Authorization']?.toString();
      final expectedAuthorization = 'Bearer ${tokens.accessToken}';
      final recovered = requestAuthorization != expectedAuthorization
          ? tokens
          : await _refreshTokens(tokens);
      request.extra['authRetried'] = true;
      _synchronizeAuthRequest(request, recovered);
      request.headers['Authorization'] = 'Bearer ${recovered.accessToken}';
      final retryResponse = await _dio.fetch<Object?>(request);
      handler.resolve(retryResponse);
    } catch (refreshError) {
      if (!_accountInactiveNotifier.isInactive) {
        await _expireSession();
      }
      handler.next(refreshError is DioException ? refreshError : error);
    }
  }

  Future<StoredAuthTokens> _refreshTokens(StoredAuthTokens current) async {
    var pending = _refreshInFlight;
    if (pending != null) return pending;

    final latest = await _tokenStore.read();
    if (latest == null) {
      throw StateError('Authentication session is no longer available.');
    }
    if (latest.refreshToken != current.refreshToken) {
      _validateSessionContinuity(current, latest);
      return latest;
    }

    pending = _refreshInFlight;
    if (pending != null) return pending;

    final operation = _performRefresh(current);
    _refreshInFlight = operation;
    try {
      return await operation;
    } finally {
      if (identical(_refreshInFlight, operation)) {
        _refreshInFlight = null;
      }
    }
  }

  Future<StoredAuthTokens> _performRefresh(StoredAuthTokens current) async {
    if (!await _sessionDeadlineController.activate(current)) {
      throw StateError('Session expired.');
    }

    late final Response<Object?> response;
    try {
      response = await _refreshDio.post<Object?>(
        ApiEndpoints.refreshToken,
        data: {'refreshToken': current.refreshToken},
        options: Options(extra: const {'skipAuth': true}),
      );
    } on DioException catch (error) {
      if (_isAccountInactiveResponse(error.response?.data)) {
        await _disableAccount();
      }
      rethrow;
    }

    final payload = _unwrap<Map<String, dynamic>>(response.data);
    final next = tokensFromApiPayload(payload);
    _validateSessionContinuity(current, next);
    await _tokenStore.save(next);
    await _sessionDeadlineController.activate(next);
    return next;
  }

  void _validateSessionContinuity(
    StoredAuthTokens current,
    StoredAuthTokens next,
  ) {
    if (current.mode != next.mode ||
        current.sessionStartedAt != next.sessionStartedAt ||
        current.absoluteExpiresAt != next.absoluteExpiresAt) {
      throw const FormatException('Refresh changed session identity.');
    }
  }

  bool _isRefreshRequest(RequestOptions options) {
    return _normalizedPath(options.path) == ApiEndpoints.refreshToken ||
        options.extra['skipAuth'] == true;
  }

  bool _isClientLoginRequest(RequestOptions options) {
    return _normalizedPath(options.path) == ApiEndpoints.clientLogin;
  }

  void _synchronizeAuthRequest(
    RequestOptions request,
    StoredAuthTokens tokens,
  ) {
    if (_normalizedPath(request.path) != ApiEndpoints.logout) return;
    final data = request.data;
    if (data is Map<String, dynamic> && data.containsKey('refreshToken')) {
      data['refreshToken'] = tokens.refreshToken;
    }
  }

  String _normalizedPath(String path) {
    return path.replaceFirst(RegExp(r'/+$'), '');
  }

  Future<void> _expireSession() {
    return _sessionDeadlineController.expireSession();
  }

  Future<void> _disableAccount() async {
    await _accountInactiveNotifier.inactivateAfter(
      _sessionDeadlineController.clearSession,
    );
  }

  bool _isAccountInactiveResponse(Object? data) {
    if (data is! Map) return false;
    return data['code']?.toString() == 'account_inactive';
  }

  T _unwrap<T>(Object? data) {
    final unwrapped = data is Map<String, dynamic> && data.containsKey('data')
        ? data['data']
        : data;
    return unwrapped as T;
  }
}

StoredAuthTokens tokensFromApiPayload(Map<String, dynamic> json) {
  final session = _asJsonMap(json['session']);
  if (session == null) {
    throw const FormatException('Missing authentication session metadata.');
  }

  final mode = AuthSessionMode.parse(session['mode']);
  final remember = session['remember'];
  if (remember is! bool || remember != mode.isRemembered) {
    throw const FormatException('Invalid authentication session metadata.');
  }

  final absoluteExpiresAt = _dateFromJson(session['absoluteExpiresAt']);
  if (mode == AuthSessionMode.temporary && absoluteExpiresAt == null) {
    throw const FormatException('Missing temporary session deadline.');
  }
  if (mode == AuthSessionMode.persistent && absoluteExpiresAt != null) {
    throw const FormatException('Persistent session has an absolute deadline.');
  }

  final tokens = StoredAuthTokens(
    accessToken: _requiredToken(json, 'accessToken', 'access_token'),
    refreshToken: _requiredToken(json, 'refreshToken', 'refresh_token'),
    accessExpiresAt: _requiredDate(session, 'accessExpiresAt'),
    refreshExpiresAt: _requiredDate(session, 'refreshExpiresAt'),
    sessionStartedAt: _requiredDate(session, 'startedAt'),
    mode: mode,
    absoluteExpiresAt: absoluteExpiresAt,
  );
  if (tokens.accessExpiresAt.isAfter(tokens.sessionDeadline) ||
      tokens.refreshExpiresAt.isAfter(tokens.sessionDeadline)) {
    throw const FormatException('Token expiry exceeds the session deadline.');
  }
  return tokens;
}

Map<String, dynamic>? _asJsonMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

String _requiredToken(
  Map<String, dynamic> json,
  String primary,
  String alternate,
) {
  final value = json[primary] ?? json[alternate];
  if (value is String && value.trim().isNotEmpty) return value;
  throw FormatException('Missing $primary.');
}

DateTime _requiredDate(Map<String, dynamic> json, String key) {
  final date = _dateFromJson(json[key]);
  if (date != null) return date;
  throw FormatException('Missing $key.');
}

DateTime? _dateFromJson(Object? value) {
  if (value is! String || value.trim().isEmpty) return null;
  return DateTime.tryParse(value)?.toUtc();
}
