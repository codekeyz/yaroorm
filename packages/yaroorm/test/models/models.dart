import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:yaroorm/yaroorm.dart';
import 'package:yaroorm/src/reflection.dart';

part 'models.g.dart';

@CopyWith()
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

// @CopyWith()
// @Table('posts')
// class Post extends Entity {
//   @primaryKey
//   final int id;

//   final String title;
//   final String description;

//   final int userId;

//   @createdAtCol
//   final DateTime createdAt;

//   @updatedAtCol
//   final DateTime updatedAt;

//   Post(
//     this.id,
//     this.title,
//     this.description, {
//     required this.userId,
//     required this.createdAt,
//     required this.updatedAt,
//   });

//   // HasMany<PostComment> get comments => hasMany<PostComment>();
// }


// @Table('post_comments', enableTimestamps: true)
// class PostComment extends Entity<String, PostComment> {
//   final String comment;
//   final int? postId;

//   PostComment(this.comment, {this.postId});
// }
