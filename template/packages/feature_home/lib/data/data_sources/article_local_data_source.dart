import 'package:feature_home/data/models/local_article.dart';
import 'package:injectable/injectable.dart';

const _seedArticles = [
  LocalArticle(
    id: "1",
    title: "Welcome to __APP_TITLE__",
    status: "published",
  ),
  LocalArticle(
    id: "2",
    title: "This screen reads from a local data source",
    status: "published",
  ),
  LocalArticle(
    id: "3",
    title: "Swap it for a remote one when you have an API",
    status: "draft",
  ),
];

abstract class ArticleLocalDataSource {
  Future<List<LocalArticle>> readArticles();
}

@Injectable(as: ArticleLocalDataSource)
class const ArticleLocalDataSourceImpl() implements ArticleLocalDataSource {
  @override
  Future<List<LocalArticle>> readArticles() async => _seedArticles;
}
