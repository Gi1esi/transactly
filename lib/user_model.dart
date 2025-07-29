
class User {
  int? userId;
  String firstName;
  String lastName;

  User({this.userId, required this.firstName, required this.lastName});

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'first_name': firstName,
      'last_name': lastName,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      userId: map['user_id'],
      firstName: map['first_name'],
      lastName: map['last_name'],
    );
  }
}
