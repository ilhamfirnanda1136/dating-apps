import 'package:flutter/widgets.dart';

import '../api/api_exception.dart';
import '../api/auth_api.dart';
import '../api/dating_api.dart';
import '../api/token_storage.dart';
import '../models/account.dart';
import '../models/user_profile.dart';

/// State global akun yang sedang login.
///
/// [ChangeNotifier] = pola "ada data berubah, beri tahu UI".
/// Setiap kali kita panggil [notifyListeners], widget yang listen
/// (lewat [SessionScope] / InheritedNotifier) akan [build] ulang.
class SessionStore extends ChangeNotifier {
  SessionStore({AuthApi? api, DatingApi? datingApi, TokenStorage? storage})
      : _api = api ?? AuthApi(storage: storage),
        _datingApi = datingApi ?? DatingApi(storage: storage),
        _storage = storage ?? TokenStorage();

  final AuthApi _api;
  final DatingApi _datingApi;
  final TokenStorage _storage;

  TokenStorage get storage => _storage;

  /// Null artinya belum login / sesi hangus.
  Account? account;

  /// True saat splash masih cek token di penyimpanan lokal.
  bool restoring = true;

  bool get isLoggedIn => account != null;
  UserProfile get profile => account?.profile ?? const UserProfile(
        id: 'guest',
        name: 'Pengguna',
        age: 18,
        city: '',
        distanceKm: 0,
        photos: [],
      );

  /// Dipanggil di SplashScreen: kalau ada token, ambil /me.
  /// [on ApiException] = token rusak/kedaluwarsa → anggap logout.
  Future<void> restore() async {
    restoring = true;
    notifyListeners();
    try {
      final token = await _storage.readAccess();
      final refresh = await _storage.readRefresh();
      if (token == null && refresh == null) {
        account = null;
        return;
      }
      account = await _api.me();
    } on ApiException {
      account = null;
      await _storage.clear();
    } finally {
      restoring = false;
      notifyListeners();
    }
  }

  Future<void> login({required String email, required String password}) async {
    final session = await _api.login(email: email, password: password);
    account = session.account;
    notifyListeners();
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
    required String birthDate,
    required String gender,
    required String interestedIn,
  }) async {
    final session = await _api.register(
      fullName: fullName,
      email: email,
      password: password,
      birthDate: birthDate,
      gender: gender,
      interestedIn: interestedIn,
    );
    account = session.account;
    notifyListeners();
  }

  Future<void> updateProfile({
    required String fullName,
    String? bio,
    String? city,
    String? job,
  }) async {
    account = await _api.updateProfile(fullName: fullName, bio: bio, city: city, job: job);
    notifyListeners();
  }

  Future<void> addPhoto(String url) async {
    account = await _datingApi.addPhoto(url);
    notifyListeners();
  }

  Future<void> updatePreferences({
    required int minAge,
    required int maxAge,
    required int maxDistanceKm,
  }) async {
    account = await _datingApi.updatePreferences(
      minAge: minAge,
      maxAge: maxAge,
      maxDistanceKm: maxDistanceKm,
    );
    notifyListeners();
  }

  Future<void> logout() async {
    await _api.logout();
    account = null;
    notifyListeners();
  }
}

/// Menyediakan [SessionStore] ke seluruh subtree.
///
/// [of] = *depend*: widget akan rebuild saat store notify.
/// [read] = *tidak* depend: cocok di onPressed / initState agar tidak
/// rebuild berlebihan. Panggil [read] hanya kalau tidak perlu dengar perubahan.
class SessionScope extends InheritedNotifier<SessionStore> {
  const SessionScope({super.key, required SessionStore store, required super.child})
      : super(notifier: store);

  static SessionStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SessionScope>()!.notifier!;

  static SessionStore read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<SessionScope>()!.notifier!;
}
