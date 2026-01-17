class UserModel {
  int? id;
  String name;
  String email;
  String profileImage;
  String password; // Store password for login validation

  UserModel({
    this.id,
    required this.name,
    required this.email,
    required this.profileImage,
    required this.password,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profileImage': profileImage,
      'password': password,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      profileImage: map['profileImage'] ?? '',
      password: map['password'] ?? '',
    );
  }
}