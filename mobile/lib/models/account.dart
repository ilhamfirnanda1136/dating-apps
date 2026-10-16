import 'user_profile.dart';

/// Hitung usia dari `YYYY-MM-DD`. Kalau ulang tahun tahun ini belum lewat, kurangi 1.
int ageFromBirthDate(String? birthDate, {DateTime? now}) {
  if (birthDate == null || birthDate.length < 10) return 18;
  final birth = DateTime.tryParse(birthDate);
  if (birth == null) return 18;
  final current = now ?? DateTime.now();
  var age = current.year - birth.year;
  if (current.month < birth.month || (current.month == birth.month && current.day < birth.day)) {
    age--;
  }
  return age;
}

/// Preferensi pencarian (filter Discover): gender, usia, jarak.
class AccountPreference {
  const AccountPreference({
    required this.interestedIn,
    this.minAge = 18,
    this.maxAge = 99,
    this.maxDistanceKm = 50,
  });

  final String interestedIn;
  final int minAge;
  final int maxAge;
  final int maxDistanceKm;

  factory AccountPreference.fromJson(Map<String, dynamic>? json) {
    return AccountPreference(
      interestedIn: json?['interested_in'] as String? ?? 'all',
      minAge: (json?['min_age'] as num?)?.toInt() ?? 18,
      maxAge: (json?['max_age'] as num?)?.toInt() ?? 99,
      maxDistanceKm: (json?['max_distance_km'] as num?)?.toInt() ?? 50,
    );
  }
}

/// Akun lengkap dari GET /me: user + profil + foto + preferensi.
class Account {
  const Account({
    required this.id,
    required this.email,
    required this.role,
    required this.status,
    required this.profile,
    this.phone,
    this.preference,
  });

  final String id;
  final String email;
  final String? phone;
  final String role;
  final String status;
  final UserProfile profile;
  final AccountPreference? preference;

  /// Backend mengirim nested JSON. Kita ratakan jadi [UserProfile] yang dipakai UI.
  factory Account.fromJson(Map<String, dynamic> json) {
    final profileJson = json['profile'] as Map<String, dynamic>? ?? {};
    final photosJson = json['photos'] as List<dynamic>? ?? [];
    final photos = photosJson
        .whereType<Map>()
        .map((item) => item['url']?.toString() ?? '')
        .where((url) => url.isNotEmpty)
        .toList();

    return Account(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      role: json['role'] as String? ?? 'user',
      status: json['status'] as String? ?? 'active',
      preference: AccountPreference.fromJson(json['preference'] as Map<String, dynamic>?),
      profile: UserProfile(
        id: json['id'] as String,
        name: profileJson['full_name'] as String? ?? 'Pengguna',
        age: ageFromBirthDate(profileJson['birth_date'] as String?),
        city: profileJson['city'] as String? ?? '',
        distanceKm: 0,
        job: profileJson['job'] as String?,
        bio: profileJson['bio'] as String? ?? '',
        isVerified: profileJson['is_verified'] == true,
        photos: photos,
      ),
    );
  }
}

/// Sepasang JWT. Access untuk request, refresh untuk perpanjang sesi.
class AuthTokens {
  const AuthTokens({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
    );
  }
}
