class User {
  final int id;
  final String username;
  final String email;
  final String fullName;
  final String userType;
  final bool active;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.fullName,
    required this.userType,
    this.active = true,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      fullName: json['full_name'],
      userType: json['user_type'],
      active: json['active'] ?? true,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'full_name': fullName,
      'user_type': userType,
      'active': active,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}