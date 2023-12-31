import 'package:yaroorm/yaroorm.dart';

class User extends Entity<int, User> {
  final String firstname;
  final String lastname;
  final int age;

  final String homeAddress;

  User({required this.firstname, required this.lastname, required this.age, required this.homeAddress});

  static User fromJson(Map<String, dynamic> json) => User(
      firstname: json['firstname'] as String,
      lastname: json['lastname'] as String,
      age: json['age'] as int,
      homeAddress: json['home_address'] as String)
    ..id = json['id'] as int?;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'firstname': firstname,
        'lastname': lastname,
        'age': age,
        'home_address': homeAddress,
      };
}

final usersTestData = <User>[
  User(firstname: 'Chima', lastname: 'Precious', age: 22, homeAddress: "Lagos, Nigeria"),
  User(firstname: 'Ngozi', lastname: 'Okoro', age: 23, homeAddress: "Lagos, Nigeria"),
  User(firstname: 'Emeka', lastname: 'Eze', age: 24, homeAddress: "Lagos, Nigeria"),
  User(firstname: 'Aisha', lastname: 'Bello', age: 25, homeAddress: "Lagos, Nigeria"),
  User(firstname: 'Oluwaseun', lastname: 'Adeyemi', age: 26, homeAddress: "Lagos, Nigeria"),
  User(firstname: 'Fatima', lastname: 'Mohammed', age: 27, homeAddress: "Lagos, Nigeria"),
  User(firstname: 'Abdul', lastname: 'Ibrahim', age: 28, homeAddress: "Lagos, Nigeria"),
  User(firstname: 'Amina', lastname: 'Sule', age: 29, homeAddress: "Lagos, Nigeria"),
  User(firstname: 'Chukwudi', lastname: 'Okafor', age: 30, homeAddress: "Lagos, Nigeria"),
  User(firstname: 'Chioma', lastname: 'Nwosu', age: 31, homeAddress: "Lagos, Nigeria"),
  User(firstname: 'Yusuf', lastname: 'Aliyu', age: 32, homeAddress: "Lagos, Nigeria"),
  User(firstname: 'Blessing', lastname: 'Okonkwo', age: 33, homeAddress: "Lagos, Nigeria"),
  User(firstname: 'Tunde', lastname: 'Williams', age: 34, homeAddress: "Lagos, Nigeria"),
  User(firstname: 'Rukayat', lastname: 'Sanni', age: 35, homeAddress: "Lagos, Nigeria"),
  User(firstname: 'Segun', lastname: 'Adeleke', age: 36, homeAddress: "Lagos, Nigeria"),
  User(firstname: 'Omotola', lastname: 'Ogunleye', age: 37, homeAddress: "Lagos, Nigeria"),
  User(firstname: 'Mustapha', lastname: 'Omar', age: 38, homeAddress: "Lagos, Nigeria"),
  User(firstname: 'Funke', lastname: 'Adebayo', age: 39, homeAddress: "Lagos, Nigeria"),
  User(firstname: 'Chinedu', lastname: 'Okeke', age: 40, homeAddress: "Abuja, Nigeria"),
  User(firstname: 'Rita', lastname: 'Egwu', age: 41, homeAddress: "Lagos, Nigeria"),
  User(firstname: 'Ibrahim', lastname: 'Bakare', age: 42, homeAddress: "Lagos, Nigeria"),
  User(firstname: 'Grace', lastname: 'Adegoke', age: 43, homeAddress: "Lagos, Nigeria"),
  User(firstname: 'Ahmed', lastname: 'Umar', age: 44, homeAddress: "Lagos, Nigeria"),
  User(firstname: 'Nneka', lastname: 'Okoli', age: 45, homeAddress: "Owerri, Nigeria"),
  User(firstname: 'Abdullahi', lastname: 'Mohammed', age: 46, homeAddress: "Lagos, Nigeria"),
  User(firstname: 'Chidinma', lastname: 'Onyeka', age: 47, homeAddress: "Lagos, Nigeria"),
  User(firstname: 'Bola', lastname: 'Akinwumi', age: 48, homeAddress: "Lagos, Nigeria"),
  User(firstname: 'Haruna', lastname: 'Bello', age: 49, homeAddress: "Lagos, Nigeria"),
  User(firstname: 'Habiba', lastname: 'Yusuf', age: 50, homeAddress: "Lagos, Nigeria"),
  User(firstname: 'Tochukwu', lastname: 'Eze', age: 50, homeAddress: "Lagos, Nigeria"),
  User(firstname: 'Ade', lastname: 'Ogunbanjo', age: 50, homeAddress: "Lagos, Nigeria"),
  User(firstname: 'Zainab', lastname: 'Abubakar', age: 50, homeAddress: "Lagos, Nigeria"),
  User(firstname: 'Chijioke', lastname: 'Nwachukwu', age: 54, homeAddress: "Lagos, Nigeria"),
  User(firstname: 'Folake', lastname: 'Adewale', age: 55, homeAddress: "Lagos, Nigeria"),
  User(firstname: 'Mustafa', lastname: 'Olawale', age: 56, homeAddress: "Lagos, Nigeria"),
  User(firstname: 'Halima', lastname: 'Idris', age: 57, homeAddress: "Lagos, Nigeria"),
  User(firstname: 'Chukwuemeka', lastname: 'Okonkwo', age: 58, homeAddress: "Lagos, Nigeria"),
];
