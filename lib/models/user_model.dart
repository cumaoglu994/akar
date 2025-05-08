class User {
  final String id;
  final String? name;
  final String? email;
  final String? phone;
  final String? address;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastLogin;
  final bool? isAnonymous;

  User({
    required this.id,
    this.name,
    this.email,
    this.phone,
    this.address,
    this.createdAt,
    this.updatedAt,
    this.lastLogin,
    this.isAnonymous,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String,
      name: map['name'] as String?,
      email: map['email'] as String?,
      phone: map['phone'] as String?,
      address: map['address'] as String?,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : null,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null,
      lastLogin: map['last_login'] != null ? DateTime.parse(map['last_login'] as String) : null,
      isAnonymous: map['is_anonymous'] as bool?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
      'is_anonymous': isAnonymous,
    };
  }
} 