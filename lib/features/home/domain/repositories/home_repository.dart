import '../../../../core/network/api_result.dart';
import '../entities/home_data.dart';

abstract class HomeRepository {
  Future<ApiResult<HomeData>> getHome({bool forceRefresh = false});
}
