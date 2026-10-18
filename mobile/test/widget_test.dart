import 'package:datingapp/api/dating_api.dart';
import 'package:datingapp/models/account.dart';
import 'package:datingapp/models/chat.dart';
import 'package:datingapp/models/user_profile.dart';
import 'package:datingapp/state/chat_store.dart';
import 'package:datingapp/utils/time_format.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeDatingApi extends DatingApi {
  @override
  Future<ChatMessage> sendMessage(
    String matchId,
    String content, {
    String? mediaUrl,
    String? replyToId,
  }) async {
    return ChatMessage(
      id: 'msg-1',
      text: content,
      isMe: true,
      sentAt: DateTime(2026, 10, 16, 20),
      mediaUrl: mediaUrl,
      replyToId: replyToId,
    );
  }

  @override
  Future<void> markRead(String matchId) async {}

  @override
  Future<List<ChatMessage>> messages(String matchId) async => [];
}

void main() {
  const user = UserProfile(id: 'u1', name: 'Uji', age: 25, city: 'Jakarta', distanceKm: 1, photos: ['x']);

  group('ChatStore', () {
    test('addMatch lalu openWith memindahkan match baru menjadi percakapan', () {
      final store = ChatStore(api: _FakeDatingApi());
      store.addMatch(user, matchId: 'm1');

      expect(store.newMatches, [user]);
      final conversation = store.openWith(user);
      expect(conversation.id, 'm1');
      expect(store.newMatches, isEmpty);
      expect(store.conversations.single, same(conversation));
      expect(store.openWith(user), same(conversation));
      store.dispose();
    });

    test('send menambah pesan ke percakapan', () async {
      final store = ChatStore(api: _FakeDatingApi());
      store.addMatch(user, matchId: 'm1');
      final conversation = store.openWith(user);

      await store.send(conversation, '  Halo!  ');
      expect(conversation.messages.single.text, 'Halo!');
      expect(conversation.messages.single.isMe, isTrue);
      store.dispose();
    });

    test('pesan kosong diabaikan', () async {
      final store = ChatStore(api: _FakeDatingApi());
      store.addMatch(user, matchId: 'm1');
      final conversation = store.openWith(user);
      await store.send(conversation, '   ');
      expect(conversation.messages, isEmpty);
      store.dispose();
    });
  });

  test('Account.fromJson memetakan profil backend', () {
    final account = Account.fromJson({
      'id': 'abc',
      'email': 'budi@mail.com',
      'role': 'user',
      'status': 'active',
      'profile': {
        'full_name': 'Budi',
        'birth_date': '1998-05-10',
        'city': 'Jakarta Selatan',
        'job': 'Product Designer',
        'bio': 'Halo',
        'is_verified': true,
      },
      'preference': {'interested_in': 'female', 'min_age': 21, 'max_age': 35, 'max_distance_km': 25},
      'photos': [
        {'url': 'https://example.com/a.jpg'},
      ],
    });

    expect(account.email, 'budi@mail.com');
    expect(account.profile.name, 'Budi');
    expect(account.profile.age, greaterThanOrEqualTo(27));
    expect(account.profile.photos, ['https://example.com/a.jpg']);
    expect(account.preference?.interestedIn, 'female');
  });

  test('formatChatTime', () {
    final now = DateTime(2026, 10, 16, 20, 0);
    expect(formatChatTime(DateTime(2026, 10, 16, 8, 5), now: now), '08:05');
    expect(formatChatTime(DateTime(2026, 10, 15, 23, 0), now: now), 'Kemarin');
    expect(formatChatTime(DateTime(2026, 10, 1, 9, 0), now: now), '01/10');
  });
}
