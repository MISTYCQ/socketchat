class User {
  final String username;
  final bool isOnline;
  final DateTime? lastSeen;

  const User({
    required this.username,
    this.isOnline = false,
    this.lastSeen,
  });

  User copyWith({
    String? username,
    bool? isOnline,
    DateTime? lastSeen,
  }) {
    return User(
      username: username ?? this.username,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.username == username;
  }

  @override
  int get hashCode => username.hashCode;
}