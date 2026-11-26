class UserModel {
  final int id;
  final String username;
  final String email;
  final String? displayName;
  final String? avatarUrl;
  final bool isVerified;
  final String? createdAt;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.displayName,
    this.avatarUrl,
    this.isVerified = true,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int? ?? 0,
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      isVerified: json['is_verified'] as bool? ?? true,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'is_verified': isVerified,
      'created_at': createdAt,
    };
  }

  UserModel copyWith({
    String? displayName,
    String? avatarUrl,
  }) {
    return UserModel(
      id: id,
      username: username,
      email: email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isVerified: isVerified,
      createdAt: createdAt,
    );
  }
}
