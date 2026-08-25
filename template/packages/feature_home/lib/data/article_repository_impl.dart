import 'package:core/error/app_error.dart';
import 'package:core/error/app_result.dart';
import 'package:dio/dio.dart';
import 'package:feature_home/data/article_remote_data_source.dart';
import 'package:feature_home/data/mappers/article_mappers.dart';
import 'package:feature_home/domain/article_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:shared/domain/entities/article.dart';

@Injectable(as: ArticleRepository)
class const ArticleRepositoryImpl(final ArticleRemoteDataSource _dataSource)
    implements ArticleRepository {
  @override
  Future<AppResult<List<Article>>> getArticles() async {
    try {
      final remoteArticles = await _dataSource.fetchArticles();
      return Success(remoteArticles.map((it) => it.toArticle()).toList());
    } on DioException catch (exception) {
      return Failure(ApiError(exception.message ?? ""));
    } on Object {
      return const Failure(UnexpectedError());
    }
  }
}
