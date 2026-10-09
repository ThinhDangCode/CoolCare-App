/// Authenticated customer data returned by the CoolCare API.
class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.phone,
    this.dateOfBirth,
    this.gender,
    this.avatarUrl,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      fullName: (json['fullName'] ?? json['full_name'])?.toString() ?? '',
      role: json['role']?.toString() ?? 'CUSTOMER',
      phone: json['phone']?.toString(),
      dateOfBirth: _normalizeDate(json['dateOfBirth']),
      gender: json['gender']?.toString(),
      avatarUrl: json['avatarUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'fullName': fullName,
    'role': role,
    'phone': phone,
    'dateOfBirth': dateOfBirth,
    'gender': gender,
    'avatarUrl': avatarUrl,
  };

  final String id;
  final String email;
  final String fullName;
  final String role;
  final String? phone;
  final String? dateOfBirth;
  final String? gender;
  final String? avatarUrl;

  static String? _normalizeDate(dynamic value) {
    final raw = value?.toString().trim();
    if (raw == null || raw.isEmpty) return null;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    final date = raw.contains('T') ? parsed.toLocal() : parsed;
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}

class AuthSession {
  const AuthSession({required this.token, required this.user});

  final String token;
  final AuthUser user;
}
