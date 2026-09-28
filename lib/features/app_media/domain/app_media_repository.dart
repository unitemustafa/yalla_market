import '../../../core/network/api_result.dart';
import 'app_media.dart';

abstract class AppMediaRepository {
  Future<ApiResult<AppMedia>> load();
}
