import '../models/account.dart';
import 'api_client.dart';
import 'token_storage.dart';

/// Hasil login/register: akun + sepasang JWT.
class AuthSession {
  const AuthSession({required this.account, required this.tokens});

  final Account account;
  final AuthTokens tokens;
}

/// Endpoint otentikasi: login, daftar, /me, logout.
class AuthApi {
  AuthApi({ApiClient? client, TokenStorage? storage})
      : _client = client ?? ApiClient(storage: storage),
        _storage = storage ?? TokenStorage();

  final ApiClient _client;
  final TokenStorage _storage;

  Future<AuthSession> login({required String email, required String password}) {
    return _authenticate('/auth/login', {'email': email.trim(), 'password': password});
  }

  Future<AuthSession> register({
    required String fullName,
    required String email,
    required String password,
    required String birthDate,
    required String gender,
    required String interestedIn,
  }) {
    // Nama field harus snake_case sesuai kontrak backend.
    return _authenticate('/auth/register', {
      'full_name': fullName.trim(),
      'email': email.trim(),
      'password': password,
      'birth_date': birthDate,
      'gender': gender,
      'interested_in': interestedIn,
    });
  }

  /// Profil pengguna yang sedang login.
  Future<Account> me() async {
    final body = await _client.get('/me');
    return Account.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<Account> updateProfile({
    required String fullName,
    String? bio,
    String? city,
    String? job,
  }) async {
    final body = await _client.put('/me/profile', body: {
      'full_name': fullName,
      'bio': bio,
      'city': city,
      'job': job,
    });
    return Account.fromJson(body['data'] as Map<String, dynamic>);
  }

  /// Logout di server (cabut refresh token) lalu hapus token lokal.
  /// [finally] menjamin token lokal tetap dibersihkan meski request gagal.
  Future<void> logout() async {
    final refresh = await _storage.readRefresh();
    try {
      if (refresh != null) {
        await _client.postEmpty('/auth/logout', body: {'refresh_token': refresh});
      }
    } finally {
      await _storage.clear();
    }
  }

  /// Login dan register punya bentuk respons yang sama.
  /// [auth: false] karena belum punya access token.
  Future<AuthSession> _authenticate(String path, Map<String, dynamic> payload) async {
    final body = await _client.post(path, body: payload, auth: false);
    final data = body['data'] as Map<String, dynamic>;
    final tokens = AuthTokens.fromJson(data['tokens'] as Map<String, dynamic>);
    await _storage.save(accessToken: tokens.accessToken, refreshToken: tokens.refreshToken);
    return AuthSession(
      account: Account.fromJson(data['user'] as Map<String, dynamic>),
      tokens: tokens,
    );
  }
}
