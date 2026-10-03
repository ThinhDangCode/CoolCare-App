class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.phone,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      fullName: (json['fullName'] ?? json['full_name'])?.toString() ?? '',
      role: json['role']?.toString() ?? 'CUSTOMER',
      phone: json['phone']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'fullName': fullName,
    'role': role,
    'phone': phone,
  };

  final String id;
  final String email;
  final String fullName;
  final String role;
  final String? phone;
}

class AuthSession {
  const AuthSession({required this.token, required this.user});

  final String token;
  final AuthUser user;
}
