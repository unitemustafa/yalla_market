import '../../../core/network/api_result.dart';
import 'app_media.dart';
import 'app_media_repository.dart';

class LoadAppMedia {
  const LoadAppMedia(this.repository);
  final AppMediaRepository repository;
  Future<ApiResult<AppMedia>> call() => repository.load();
}
