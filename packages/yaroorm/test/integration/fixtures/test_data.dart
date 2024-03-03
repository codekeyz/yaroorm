import 'package:yaroorm/yaroorm.dart';

class User extends Entity<int, User> {
  String firstname;
  String lastname;
  int age;

  @TableColumn(name: 'home_address')
  String homeAddress;

  User({
    required this.firstname,
    required this.lastname,
    required this.age,
    required this.homeAddress,
  });

  HasMany<Post> get posts => hasMany<Post>();
}

@Table(name: 'posts', enableTimestamps: true)
class Post extends Entity<int, Post> {
  String title;
  String description;

  final int? userId;

  Post(this.title, this.description, {this.userId});

  HasMany<PostComment> get comments => hasMany<PostComment>();
}

@Table(name: 'post_comments', enableTimestamps: true)
class PostComment extends Entity<String, PostComment> {
  final String comment;
  final int? postId;

  PostComment(this.comment, {this.postId});
}

final usersList = <User>[
  /// Ghana Users - [6]
  User(
      firstname: 'Kofi',
      lastname: 'Duke',
      age: 22,
      homeAddress: "Accra, Ghana"),
  User(
      firstname: 'Foo', lastname: 'Bar', age: 23, homeAddress: "Kumasi, Ghana"),
  User(
      firstname: 'Bar',
      lastname: 'Moo',
      age: 24,
      homeAddress: "Cape Coast, Ghana"),
  User(firstname: 'Kee', lastname: 'Koo', age: 25, homeAddress: "Accra, Ghana"),
  User(firstname: 'Poo', lastname: 'Paa', age: 26, homeAddress: "Accra, Ghana"),
  User(
      firstname: 'Merh',
      lastname: 'Moor',
      age: 27,
      homeAddress: "Accra, Ghana"),

  /// Nigerian Users - [22]
  User(
      firstname: 'Abdul',
      lastname: 'Ibrahim',
      age: 28,
      homeAddress: "Owerri, Nigeria"),
  User(
      firstname: 'Amina',
      lastname: 'Sule',
      age: 29,
      homeAddress: "Owerri, Nigeria"),
  User(
      firstname: 'Chukwudi',
      lastname: 'Okafor',
      age: 30,
      homeAddress: "Lagos, Nigeria"),
  User(
      firstname: 'Chioma',
      lastname: 'Nwosu',
      age: 31,
      homeAddress: "Lagos, Nigeria"),
  User(
      firstname: 'Yusuf',
      lastname: 'Aliyu',
      age: 32,
      homeAddress: "Owerri, Nigeria"),
  User(
      firstname: 'Blessing',
      lastname: 'Okonkwo',
      age: 33,
      homeAddress: "Owerri, Nigeria"),
  User(
      firstname: 'Tunde',
      lastname: 'Williams',
      age: 34,
      homeAddress: "Abuja, Nigeria"),
  User(
      firstname: 'Rukayat',
      lastname: 'Sanni',
      age: 35,
      homeAddress: "Abuja, Nigeria"),
  User(
      firstname: 'Segun',
      lastname: 'Adeleke',
      age: 36,
      homeAddress: "Lagos, Nigeria"),
  User(
      firstname: 'Abdullahi',
      lastname: 'Mohammed',
      age: 46,
      homeAddress: "Lagos, Nigeria"),
  User(
      firstname: 'Chidinma',
      lastname: 'Onyeka',
      age: 47,
      homeAddress: "Owerri, Nigeria"),
  User(
      firstname: 'Bola',
      lastname: 'Akinwumi',
      age: 48,
      homeAddress: "Owerri, Nigeria"),
  User(
      firstname: 'Haruna',
      lastname: 'Bello',
      age: 49,
      homeAddress: "Lagos, Nigeria"),
  User(
      firstname: 'Habiba',
      lastname: 'Yusuf',
      age: 50,
      homeAddress: "Owerri, Nigeria"),
  User(
      firstname: 'Tochukwu',
      lastname: 'Eze',
      age: 50,
      homeAddress: "Lagos, Nigeria"),
  User(
      firstname: 'Ade',
      lastname: 'Ogunbanjo',
      age: 50,
      homeAddress: "Owerri, Nigeria"),
  User(
      firstname: 'Zainab',
      lastname: 'Abubakar',
      age: 50,
      homeAddress: "Lagos, Nigeria"),
  User(
      firstname: 'Chijioke',
      lastname: 'Nwachukwu',
      age: 54,
      homeAddress: "Owerri, Nigeria"),
  User(
      firstname: 'Folake',
      lastname: 'Adewale',
      age: 55,
      homeAddress: "Owerri, Nigeria"),
  User(
      firstname: 'Mustafa',
      lastname: 'Olawale',
      age: 56,
      homeAddress: "Lagos, Nigeria"),
  User(
      firstname: 'Halima',
      lastname: 'Idris',
      age: 57,
      homeAddress: "Lagos, Nigeria"),
  User(
      firstname: 'Chukwuemeka',
      lastname: 'Okonkwo',
      age: 58,
      homeAddress: "Abuja, Nigeria"),

  /// Kenyan Users - [9]
  User(
      firstname: 'Kevin',
      lastname: 'Luke',
      age: 37,
      homeAddress: "Nairobi, Kenya"),
  User(firstname: 'Foop', lastname: 'Farr', age: 38, homeAddress: "CBD, Kenya"),
  User(
      firstname: 'Koin',
      lastname: 'Karl',
      age: 39,
      homeAddress: "Mumbasa, Kenya"),
  User(
      firstname: 'Moo',
      lastname: 'Maa',
      age: 40,
      homeAddress: "Westlands, Kenya"),
  User(
      firstname: 'Merh',
      lastname: 'Merh',
      age: 41,
      homeAddress: "Nairobi, Kenya"),
  User(
      firstname: 'Ibrahim',
      lastname: 'Bakare',
      age: 42,
      homeAddress: "Nairobi, Kenya"),
  User(
      firstname: 'Grace',
      lastname: 'Adegoke',
      age: 43,
      homeAddress: "Nairobi, Kenya"),
  User(
      firstname: 'Ahmed',
      lastname: 'Umar',
      age: 44,
      homeAddress: "Nairobi, Kenya"),
  User(
      firstname: 'Nneka',
      lastname: 'Okoli',
      age: 45,
      homeAddress: "Nairobi, Kenya"),
];
