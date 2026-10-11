import 'package:equatable/equatable.dart';

/// Authenticated user profile returned by `GET /auth/me`.
class UserProfile extends Equatable {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.role = 'citizen',
  });

  final int id;
  final String name;
  final String email;
  final String role;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'citizen',
    );
  }

  @override
  List<Object?> get props => [id, name, email, role];
}
