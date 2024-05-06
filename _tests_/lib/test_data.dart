import 'package:yaroorm_tests/src/models.dart';

typedef UserData = ({String firstname, String lastname, int age, String homeAddress});

final usersList = <NewUser>[
  /// Ghana Users - [6]
  NewUser(
    firstname: 'Kofi',
    lastname: 'Duke',
    age: 22,
    homeAddress: "Accra, Ghana",
  ),
  NewUser(
    firstname: 'Foo',
    lastname: 'Bar',
    age: 23,
    homeAddress: "Kumasi, Ghana",
  ),
  NewUser(
    firstname: 'Bar',
    lastname: 'Moo',
    age: 24,
    homeAddress: "Cape Coast, Ghana",
  ),
  NewUser(
    firstname: 'Kee',
    lastname: 'Koo',
    age: 25,
    homeAddress: "Accra, Ghana",
  ),
  NewUser(
    firstname: 'Poo',
    lastname: 'Paa',
    age: 26,
    homeAddress: "Accra, Ghana",
  ),
  NewUser(
    firstname: 'Merh',
    lastname: 'Moor',
    age: 27,
    homeAddress: "Accra, Ghana",
  ),

  /// Nigerian Users - [22]
  NewUser(firstname: 'Abdul', lastname: 'Ibrahim', age: 28, homeAddress: "Owerri, Nigeria"),
  NewUser(firstname: 'Amina', lastname: 'Sule', age: 29, homeAddress: "Owerri, Nigeria"),
  NewUser(firstname: 'Chukwudi', lastname: 'Okafor', age: 30, homeAddress: "Lagos, Nigeria"),
  NewUser(firstname: 'Chioma', lastname: 'Nwosu', age: 31, homeAddress: "Lagos, Nigeria"),
  NewUser(firstname: 'Yusuf', lastname: 'Aliyu', age: 32, homeAddress: "Owerri, Nigeria"),
  NewUser(firstname: 'Blessing', lastname: 'Okonkwo', age: 33, homeAddress: "Owerri, Nigeria"),
  NewUser(firstname: 'Tunde', lastname: 'Williams', age: 34, homeAddress: "Abuja, Nigeria"),
  NewUser(firstname: 'Rukayat', lastname: 'Sanni', age: 35, homeAddress: "Abuja, Nigeria"),
  NewUser(firstname: 'Segun', lastname: 'Adeleke', age: 36, homeAddress: "Lagos, Nigeria"),
  NewUser(firstname: 'Abdullahi', lastname: 'Mohammed', age: 46, homeAddress: "Lagos, Nigeria"),
  NewUser(firstname: 'Chidinma', lastname: 'Onyeka', age: 47, homeAddress: "Owerri, Nigeria"),
  NewUser(firstname: 'Bola', lastname: 'Akinwumi', age: 48, homeAddress: "Owerri, Nigeria"),
  NewUser(firstname: 'Haruna', lastname: 'Bello', age: 49, homeAddress: "Lagos, Nigeria"),
  NewUser(firstname: 'Habiba', lastname: 'Yusuf', age: 50, homeAddress: "Owerri, Nigeria"),
  NewUser(firstname: 'Tochukwu', lastname: 'Eze', age: 50, homeAddress: "Lagos, Nigeria"),
  NewUser(firstname: 'Ade', lastname: 'Ogunbanjo', age: 50, homeAddress: "Owerri, Nigeria"),
  NewUser(firstname: 'Zainab', lastname: 'Abubakar', age: 50, homeAddress: "Lagos, Nigeria"),
  NewUser(firstname: 'Chijioke', lastname: 'Nwachukwu', age: 54, homeAddress: "Owerri, Nigeria"),
  NewUser(firstname: 'Folake', lastname: 'Adewale', age: 55, homeAddress: "Owerri, Nigeria"),
  NewUser(firstname: 'Mustafa', lastname: 'Olawale', age: 56, homeAddress: "Lagos, Nigeria"),
  NewUser(firstname: 'Halima', lastname: 'Idris', age: 57, homeAddress: "Lagos, Nigeria"),
  NewUser(firstname: 'Chukwuemeka', lastname: 'Okonkwo', age: 58, homeAddress: "Abuja, Nigeria"),

  /// Kenyan Users - [9]
  NewUser(firstname: 'Kevin', lastname: 'Luke', age: 37, homeAddress: "Nairobi, Kenya"),
  NewUser(firstname: 'Foop', lastname: 'Farr', age: 38, homeAddress: "CBD, Kenya"),
  NewUser(firstname: 'Koin', lastname: 'Karl', age: 39, homeAddress: "Mumbasa, Kenya"),
  NewUser(firstname: 'Moo', lastname: 'Maa', age: 40, homeAddress: "Westlands, Kenya"),
  NewUser(firstname: 'Merh', lastname: 'Merh', age: 41, homeAddress: "Nairobi, Kenya"),
  NewUser(firstname: 'Ibrahim', lastname: 'Bakare', age: 42, homeAddress: "Nairobi, Kenya"),
  NewUser(firstname: 'Grace', lastname: 'Adegoke', age: 43, homeAddress: "Nairobi, Kenya"),
  NewUser(firstname: 'Ahmed', lastname: 'Umar', age: 44, homeAddress: "Nairobi, Kenya"),
  NewUser(firstname: 'Nneka', lastname: 'Okoli', age: 45, homeAddress: "Nairobi, Kenya"),
];
