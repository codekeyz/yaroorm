import 'package:yaroorm/yaroorm.dart';

part 'models.g.dart';

@table
class User extends Entity<User> {
  @autoIncrementPrimary
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

  HasMany<User, Post> get posts => hasMany<Post>('posts');
}

@Table(name: 'posts')
class Post extends Entity<Post> {
  @autoIncrementPrimary
  final int id;

  final String title;
  final String description;

  @bindTo(User, onUpdate: ForeignKeyAction.cascade, onDelete: ForeignKeyAction.cascade)
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

  HasMany<Post, PostComment> get comments => hasMany<PostComment>('comments');

  BelongsTo<Post, User> get owner => belongsTo<User>('owner');
}

@table
class PostComment extends Entity<PostComment> {
  @PrimaryKey(autoIncrement: false)
  final String id;

  final String comment;

  @bindTo(Post, onDelete: ForeignKeyAction.cascade)
  final int postId;

  PostComment(this.id, this.comment, {required this.postId});

  Map<String, dynamic> toJson() => {
        'id': id,
        'comment': comment,
        'postId': postId,
      };
}
