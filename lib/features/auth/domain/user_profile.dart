import 'package:equatable/equatable.dart';

/// Authenticated user profile returned by `GET /api/me`.
class UserProfile extends Equatable {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
  });

  final String id;
  final String name;
  final String email;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
    );
  }

  @override
  List<Object?> get props => [id, name, email];
}
