class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.isEmailVerified,
  });

  final String id;
  final String email;
  final String fullName;
  final bool isEmailVerified;

  String get firstName {
    final name = fullName.trim();
    if (name.isEmpty) return 'Pengguna';
    return name.split(RegExp(r'\s+')).first;
  }

  String get displayName {
    final name = fullName.trim();
    if (name.isEmpty) return 'Pengguna';
    return name;
  }

  String get initials {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'CU';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }
}
