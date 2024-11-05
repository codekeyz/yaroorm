import 'package:yaroorm/yaroorm.dart';

part 'models.g.dart';

@table
class User with Entity<User> {
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
  }) {
    super.initialize();
  }

  HasMany<User, Post> get posts => hasMany<Post>(#posts);
}

@Table(name: 'posts')
class Post with Entity<Post> {
  @primaryKey
  final int id;

  final String title;
  final String description;

  final String? imageUrl;

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
    this.imageUrl,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
  }) {
    super.initialize();
  }

  HasMany<Post, PostComment> get comments => hasMany<PostComment>(#comments);

  BelongsTo<Post, User> get owner => belongsTo<User>(#owner);
}

@table
class PostComment with Entity<PostComment> {
  @PrimaryKey(autoIncrement: false)
  final String id;

  final String comment;

  @bindTo(Post, onDelete: ForeignKeyAction.cascade)
  final int postId;

  PostComment(this.id, this.comment, {required this.postId}) {
    super.initialize();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'comment': comment,
        'postId': postId,
      };
}
