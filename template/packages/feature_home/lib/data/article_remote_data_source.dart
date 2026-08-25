import 'package:dio/dio.dart';
import 'package:feature_home/data/models/remote_article.dart';
import 'package:injectable/injectable.dart';

abstract class ArticleRemoteDataSource {
  Future<List<RemoteArticle>> fetchArticles();
}

@Injectable(as: ArticleRemoteDataSource)
class const ArticleRemoteDataSourceImpl(final Dio _dio)
    implements ArticleRemoteDataSource {
  @override
  Future<List<RemoteArticle>> fetchArticles() async {
    final response = await _dio.get<List<dynamic>>("/articles");
    final data = response.data ?? const <dynamic>[];
    return data
        .cast<Map<String, dynamic>>()
        .map(RemoteArticleMapper.fromMap)
        .toList();
  }
}
