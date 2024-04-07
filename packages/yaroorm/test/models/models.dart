import 'package:yaroorm/src/database/driver/pgsql_driver.dart';
import 'package:yaroorm/src/database/driver/sqlite_driver.dart';
import 'package:yaroorm/yaroorm.dart';

part 'models.g.dart';

@Table('users')
class User extends Entity {
  @primaryKey
  final int id;

  final String firstname;
  final String lastname;
  final int age;

  @TableColumn(name: 'home_address')
  final String homeAddress;

  User({
    required this.id,
    required this.firstname,
    required this.lastname,
    required this.age,
    required this.homeAddress,
  });

  // HasMany<Post> get posts => hasMany<Post>();
}

@Table('posts')
class Post extends Entity {
  @primaryKey
  final int id;

  final String title;
  final String description;

  @reference(
    User,
    name: 'user_id',
    onUpdate: ForeignKeyAction.cascade,
    onDelete: ForeignKeyAction.cascade,
  )
  final int userId;

  @createdAtCol
  final DateTime createdAt;

  @updatedAtCol
  final DateTime updatedAt;

  Post(
    this.id,
    this.title,
    this.description, {
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  // HasMany<PostComment> get comments => hasMany<PostComment>();
}

@Table('post_comments')
class PostComment extends Entity {
  @primaryKey
  final String id;
  final String comment;
  final int? postId;

  PostComment(this.id, this.comment, {this.postId});
}
