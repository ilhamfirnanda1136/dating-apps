/// Profil publik yang tampil di kartu swipe, likes, dan chat.
/// [const] constructor = objek bisa dibuat saat compile jika semua argumen konstan.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.city,
    required this.distanceKm,
    required this.photos,
    this.bio = '',
    this.job,
    this.interests = const [],
    this.isVerified = false,
    this.isOnline = false,
    this.likedYou = false,
  });

  final String id;
  final String name;
  final int age;
  final String city;
  final int distanceKm;
  final List<String> photos;
  final String bio;
  final String? job;
  final List<String> interests;
  final bool isVerified;
  final bool isOnline;

  /// True jika orang ini sudah like kita (backend yang mengisi).
  final bool likedYou;

  /// Foto pertama, atau string kosong (NetImage akan tampilkan placeholder).
  String get avatar => photos.isEmpty ? '' : photos.first;

  /// JSON discover kadang `photos: ["url"]`, kadang `photos: [{ url }]`.
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final photosJson = json['photos'] as List<dynamic>? ?? [];
    final photos = photosJson.map((item) {
      if (item is String) return item;
      if (item is Map) return item['url']?.toString() ?? '';
      return '';
    }).where((url) => url.isNotEmpty).toList();

    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String? ?? json['full_name'] as String? ?? 'Pengguna',
      age: (json['age'] as num?)?.toInt() ?? 18,
      city: json['city'] as String? ?? '',
      distanceKm: (json['distance_km'] as num?)?.toInt() ?? 0,
      job: json['job'] as String?,
      bio: json['bio'] as String? ?? '',
      isVerified: json['is_verified'] == true,
      likedYou: json['liked_you'] == true,
      photos: photos,
    );
  }
}
