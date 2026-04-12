class UserModel {
  final String id;
  final String name;
  final String email;
  final String authProvider;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.authProvider,
  });

  String get initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (parts.length == 1 && parts.first.length >= 2) {
      return parts.first.substring(0, 2).toUpperCase();
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return 'BT';
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      authProvider:
          json['authProvider'] as String? ??
          json['provider'] as String? ??
          'email',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'authProvider': authProvider,
    };
  }
}
