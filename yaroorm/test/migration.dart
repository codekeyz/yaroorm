import 'package:test/test.dart';
import 'package:yaroorm/src/database/driver/sqlite_driver.dart';
import 'package:yaroorm/src/database/entity.dart';

import 'fixtures/test_data.dart';
import 'migration.reflectable.dart';

@EntityMeta(table: 'user_articles')
class Article extends Entity<int, Entity> {
  final String name;
  final int ownerId;

  Article(this.name, this.ownerId);

  @override
  Map<String, dynamic> toJson() => {'name': name, 'ownerId': ownerId};
}

class ArticleComment extends Entity<String, ArticleComment> {
  final int articleId;
  final int userId;

  ArticleComment(this.articleId, this.userId);

  @override
  Map<String, dynamic> toJson() => {'articleId': articleId, 'userId': userId};
}

void main() {
  initializeReflectable();

  group('Table Blueprint', () {
    //
    group('`foreignKey` should resolve for ', () {
      //
      test('class with entity meta', () {
        final articleTableBlueprint = SqliteTableBlueprint()
          ..string('name')
          ..integer('ownerId');

        final userForeignKey = articleTableBlueprint.foreign<Article, User>('ownerId');
        expect(userForeignKey.table, 'user_articles');
        expect(userForeignKey.column, 'ownerId');
        expect(userForeignKey.foreignTable, 'users');
        expect(userForeignKey.foreignTableColumn, 'id');

        final statement = SqliteSerializer().acceptForeignKey(articleTableBlueprint, userForeignKey);
        expect(statement, 'ownerId INTEGER REFERENCES users(id)');
      });

      test('class with no meta', () {
        final foreignKey2 = SqliteTableBlueprint().foreign<ArticleComment, User>('userId');
        expect(foreignKey2.table, 'article_comments');
        expect(foreignKey2.column, 'userId');
        expect(foreignKey2.foreignTable, 'users');
        expect(foreignKey2.foreignTableColumn, 'id');
      });

      test('custom foreign reference column', () {
        final foreignKey3 =
            SqliteTableBlueprint().foreign<ArticleComment, User>('userId', reference: 'custom_id_on_user');
        expect(foreignKey3.table, 'article_comments');
        expect(foreignKey3.column, 'userId');
        expect(foreignKey3.foreignTable, 'users');
        expect(foreignKey3.foreignTableColumn, 'custom_id_on_user');
      });
    });
  });
}
