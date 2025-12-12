class User {
  final String id;
  final String email;
  final String name;
  final String phoneNumber;
  final String role;
  final bool isLocked;

  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.phoneNumber,
    required this.role,
    required this.isLocked,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['userId']?.toString() ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? 'Unknown',
      phoneNumber: json['phoneNumber'] ?? '',
      role: json['role'] ?? 'customer',
      // safely handle null or missing booleans
      isLocked: json['isLocked'] == true,
    );
  }
}
