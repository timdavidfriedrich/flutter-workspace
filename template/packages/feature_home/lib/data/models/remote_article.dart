import 'package:dart_mappable/dart_mappable.dart';

part 'remote_article.mapper.dart';

@MappableClass()
class const RemoteArticle({
  required final String id,
  required final String? title,
  required final String status,
}) with RemoteArticleMappable;
