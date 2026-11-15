import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:yutomo/main.dart';
import 'package:yutomo/src/models.dart';
import 'package:yutomo/src/screens/chat_screen.dart';
import 'package:yutomo/src/services/ai_concierge.dart';
import 'package:yutomo/src/services/app_state.dart';
import 'package:yutomo/src/services/auth_service.dart';
import 'package:yutomo/src/util/cat_spots.dart';
import 'package:yutomo/src/util/format.dart';
import 'package:yutomo/src/util/mock_persist.dart' as persist;
import 'package:yutomo/src/util/share_text.dart';

AppUser _testUser(AppState state, {String id = 'me', String nickname = 'テスト太郎'}) {
  return AppUser(
    id: id,
    nickname: nickname,
    decade: '30代',
    gender: 'male',
    iconCategoryId: 'sento',
    interestIds: const ['sento'],
    bio: 'テスト',
    lat: state.anchorLat,
    lng: state.anchorLng,
  );
}

void main() {
  group('format utils', () {
    test('距離は粗いバンド表示になる（FR-2-2）', () {
      expect(distanceLabel(0.3), '〜1km');
      expect(distanceLabel(2.4), '1〜3km');
      expect(distanceLabel(4.9), '3〜5km');
      expect(distanceLabel(7.2), '5〜10km');
      expect(distanceLabel(23.0), '10km〜');
    });

    test('残り時間ラベル', () {
      final now = DateTime(2026, 2, 1, 12, 0);
      expect(remainingLabel(now.add(const Duration(minutes: 42)), now),
          '残り42分');
      expect(remainingLabel(now.add(const Duration(hours: 2)), now),
          '残り2時間');
      expect(
          remainingLabel(now.add(const Duration(hours: 1, minutes: 20)), now),
          '残り1時間20分');
      expect(remainingLabel(now.subtract(const Duration(minutes: 1)), now),
          '終了');
    });

    test('経過時間ラベル', () {
      final now = DateTime(2026, 2, 1, 12, 0);
      expect(elapsedLabel(now.subtract(const Duration(seconds: 30)), now),
          'たった今');
      expect(
          elapsedLabel(now.subtract(const Duration(minutes: 42)), now),
          '42分前');
      expect(
          elapsedLabel(now.subtract(const Duration(hours: 5)), now),
          '5時間前');
      expect(elapsedLabel(now.subtract(const Duration(days: 2)), now),
          '2日前');
    });
  });

  group('share_text（SNS共有文）', () {
    test('招待文にニックネームとURLが入る', () {
      final t = inviteText('サウナのあきら');
      expect(t, contains('サウナのあきら'));
      expect(t, contains(kAppUrl));
      expect(t, contains('完全無料'));
    });

    test('募集の共有文にタイトルと集合場所が入る', () {
      final t = recruitmentShareText('今から湯めぐり', 'スーパー銭湯 大浴城');
      expect(t, contains('今から湯めぐり'));
      expect(t, contains('スーパー銭湯 大浴城'));
      expect(t, contains(kAppUrl));
    });

    test('同業者向けの紹介文に店舗名と業態と無料表記が入る', () {
      final t = businessInviteText('銭湯 桜の湯', '銭湯');
      expect(t, contains('銭湯 桜の湯'));
      expect(t, contains('銭湯'));
      expect(t, contains('無料'));
      expect(t, contains(kAppUrl));
    });
  });

  group('近くの施設（湯とも！特別機能）', () {
    // 東京駅（35.6812, 139.7671）を現在地としたOverpassレスポンスの例
    const overpassJson = '''
{
  "version": 0.6, "generator": "Overpass API",
  "elements": [
    {"type": "node", "id": 201, "lat": 35.70, "lon": 139.78,
     "tags": {"amenity": "public_bath", "name": "A 銭湯 桜の湯"}},
    {"type": "way", "id": 203,
     "center": {"lat": 35.67, "lon": 139.76},
     "tags": {"amenity": "public_bath", "bath:type": "onsen", "name": "B 湯の花荘"}},
    {"type": "node", "id": 204, "lat": 35.66, "lon": 139.75,
     "tags": {"leisure": "water_park", "name": "C スパ・健康ランド 大浴城"}},
    {"type": "node", "id": 208, "lat": 35.71, "lon": 139.78,
     "tags": {"leisure": "sauna", "name": "D サウナ専門店 むくむく"}},
    {"type": "node", "id": 205, "lat": 35.68, "lon": 139.77,
     "tags": {"amenity": "public_bath"}},
    {"type": "node", "id": 206, "lat": 35.69, "lon": 139.79,
     "tags": {"amenity": "cafe", "name": "E 喫茶まるのうち"}},
    {"type": "node", "id": 207, "lat": 35.69, "lon": 139.78,
     "tags": {"leisure": "park", "name": "F 中央公園"}}
  ]
}
''';

    test('実在データのパース: 銭湯・温泉・スパ・サウナを種別判定する', () {
      final spots = parseOverpassResponse(overpassJson, 35.6812, 139.7671);
      final names = spots.map((s) => s.name).toList();
      expect(names, contains('A 銭湯 桜の湯')); // amenity=public_bath
      expect(names, contains('B 湯の花荘')); // bath:type=onsen
      expect(names, contains('C スパ・健康ランド 大浴城')); // leisure=water_park
      expect(names, contains('D サウナ専門店 むくむく')); // leisure=sauna
      // 名称のない施設は対象外
      expect(spots.any((s) => s.name.contains('名称未登録')), isFalse);
      // 民間の飲食店・公園は対象外
      expect(spots.any((s) => s.name.contains('喫茶')), isFalse);
      expect(spots.any((s) => s.name.contains('公園')), isFalse);
    });

    test('結果は現在地からの距離の昇順に並ぶ', () {
      final spots = parseOverpassResponse(overpassJson, 35.6812, 139.7671);
      expect(spots.length, greaterThanOrEqualTo(2));
      for (var i = 1; i < spots.length; i++) {
        expect(spots[i - 1].distanceKm,
            lessThanOrEqualTo(spots[i].distanceKm));
      }
    });

    test('種別判定できる（sento / onsen / spa / sauna）', () {
      final spots = parseOverpassResponse(overpassJson, 35.6812, 139.7671);
      final sento = spots.firstWhere((s) => s.name == 'A 銭湯 桜の湯');
      expect(sento.type, 'sento');
      expect(sento.isSento, isTrue);
      final onsen = spots.firstWhere((s) => s.name == 'B 湯の花荘');
      expect(onsen.type, 'onsen');
      final spa = spots.firstWhere((s) => s.name == 'C スパ・健康ランド 大浴城');
      expect(spa.type, 'spa');
      final sauna = spots.firstWhere((s) => s.name == 'D サウナ専門店 むくむく');
      expect(sauna.type, 'sauna');
    });

    test('Googleマップ用URLはスポットの座標で組み立てられる', () {
      final spots = parseOverpassResponse(overpassJson, 35.6812, 139.7671);
      final spot = spots.first;
      final url = googleMapsUrlForSpot(spot);
      expect(url, startsWith('https://www.google.com/maps/search/'));
      expect(url, contains('${spot.lat},${spot.lng}'));
    });

    test('Overpassクエリは銭湯・スパ・サウナを含み飲食店や公園を含まない', () {
      final q = buildOverpassQuery(35.6812, 139.7671, radiusKm: 5);
      expect(q, contains('"amenity"="public_bath"'));
      expect(q, contains('"leisure"="water_park"'));
      expect(q, contains('"leisure"="sauna"'));
      // 民間の飲食店・公園は検索しない
      expect(q, isNot(contains('"amenity"="cafe"')));
      expect(q, isNot(contains('"leisure"="park"')));
      // relation を含む bbox クエリは重すぎて各サーバーが502/504を返すため除外
      expect(q, isNot(contains('relation')));
    });

    test('施設データのキャッシュ変換（Map⇔CatSpot）は往復できる', () {
      final spots = parseOverpassResponse(overpassJson, 35.6812, 139.7671);
      for (final s in spots) {
        final restored = catSpotFromMap(catSpotToMap(s));
        expect(restored.osmId, s.osmId);
        expect(restored.name, s.name);
        expect(restored.type, s.type);
        expect(restored.lat, s.lat);
        expect(restored.lng, s.lng);
        expect(restored.openingHours, s.openingHours);
      }
    });
  });

  group('端末内スナップショット（モック永続化）', () {
    test('募集・ゆずりあい・コミュニティは保存用Mapとの往復ができる', () {
      final now = DateTime(2026, 3, 1, 12, 0);
      final rec = Recruitment(
        id: 'r-1',
        hostId: 'me',
        genreId: 'tour',
        title: 'テストの募集',
        body: '本文',
        meetup: 'テスト銭湯 番台前',
        capacity: 3,
        createdAt: now,
        expiresAt: now.add(const Duration(hours: 1)),
        memberIds: const ['me'],
      );
      final restored = persist.recruitmentFromMap(
          persist.recruitmentToMap(rec));
      expect(restored!.id, rec.id);
      expect(restored.title, rec.title);
      expect(restored.memberIds, rec.memberIds);

      final item = BathGoodsExchange(
        id: 'cx-1',
        posterId: 'me',
        kind: 'give',
        itemDescription: 'テストサウナハット（手編み・中古）',
        areaName: 'テスト駅',
        detail: '公共の駐車場で受け渡し',
        lat: 35.0,
        lng: 139.0,
        createdAt: now,
        photoPath: '/data/user/0/parts_item_photos/item_photo_1.jpg',
      );
      final restoredItem = persist.partsExchangeFromMap(
          persist.partsExchangeToMap(item));
      expect(restoredItem!.kind, 'give');
      expect(restoredItem.photoPath, item.photoPath);
      expect(restoredItem.createdAt, item.createdAt);

      final com = Community(
        id: 'c-1',
        ownerId: 'me',
        name: 'テスト部',
        description: '説明',
        linkedStore: null,
        createdAt: now,
        memberIds: const {'me'},
      );
      final restoredCom = persist.communityFromMap(
          persist.communityToMap(com));
      expect(restoredCom!.name, com.name);
      expect(restoredCom.memberIds, com.memberIds);
    });

    test('prune: 他アカウントと期限切れの募集は復元されない', () {
      final now = DateTime.now();
      final rec = Recruitment(
        id: 'r-mine',
        hostId: 'me',
        genreId: 'tour',
        title: '自分の募集',
        body: '',
        meetup: '駅',
        capacity: 2,
        createdAt: now,
        expiresAt: now.add(const Duration(hours: 2)),
        memberIds: const ['me'],
      );
      final expired = Recruitment(
        id: 'r-expired',
        hostId: 'me',
        genreId: 'tour',
        title: '期限切れ',
        body: '',
        meetup: '駅',
        capacity: 2,
        createdAt: now.subtract(const Duration(hours: 5)),
        expiresAt: now.subtract(const Duration(hours: 1)),
        memberIds: const ['me'],
      );
      final othersItem = BathGoodsExchange(
        id: 'pd-other',
        posterId: 'someone-else',
        kind: 'give',
        itemDescription: '他人の投稿',
        areaName: 'どこか',
        detail: '',
        lat: 35.0,
        lng: 139.0,
        createdAt: now,
      );
      final myItem = BathGoodsExchange(
        id: 'pd-mine',
        posterId: 'me',
        kind: 'give',
        itemDescription: '自分の投稿',
        areaName: 'どこか',
        detail: '',
        lat: 35.0,
        lng: 139.0,
        createdAt: now,
      );
      final snapshot = {
        'recruitments': [rec, expired].map(persist.recruitmentToMap).toList(),
        'partsExchanges': [othersItem, myItem].map(persist.partsExchangeToMap).toList(),
      };
      final pruned = persist.pruneSnapshotToOwner(snapshot, 'me');
      final recIds =
          (pruned['recruitments'] as List).map((e) => e['id'] as String).toList();
      expect(recIds, ['r-mine']); // 期限切れは捨てる
      final itemIds =
          (pruned['partsExchanges'] as List).map((e) => e['id'] as String).toList();
      expect(itemIds, ['pd-mine']); // 他人の投稿は捨てる
    });
  });

  group('AuthService（モック認証）', () {
    test('会員登録するとログイン状態になり、ログアウト・再ログインができる',
        () async {
      SharedPreferences.setMockInitialValues({});
      final auth = AuthService();
      await auth.init();

      // 会員登録 → 同時にログインされる
      await auth.register(
        email: 'Test@Example.com',
        password: 'secret123',
        nickname: '太郎',
        decade: '30代',
        gender: 'male',
        iconCategoryId: 'sento',
        interestIds: const ['sento'],
        bio: 'テスト',
      );
      expect(auth.sessionEmail, 'test@example.com'); // 小文字化して保存
      expect(auth.sessionNickname(), '太郎');

      // ログアウト → セッション消えるがアカウントは残る
      await auth.logout();
      expect(auth.hasSession, isFalse);
      await auth.login('test@example.com', 'secret123');
      expect(auth.hasSession, isTrue);

      // 誤パスワードは拒否される
      await expectLater(
        auth.login('test@example.com', 'wrong-pw'),
        throwsA(isA<AuthException>()),
      );

      // 同 email の再登録は拒否される
      await expectLater(
        auth.register(
          email: 'test@example.com',
          password: 'x',
          nickname: '二郎',
          decade: '20代',
          gender: 'male',
          iconCategoryId: 'sento',
          interestIds: const ['sento'],
          bio: '',
        ),
        throwsA(isA<AuthException>()),
      );
    });

    test('セッションからユーザーを復元できる', () async {
      SharedPreferences.setMockInitialValues({});
      final auth = AuthService();
      await auth.init();
      await auth.register(
        email: 'a@b.com',
        password: 'secret123',
        nickname: '花子',
        decade: '20代',
        gender: 'female',
        iconCategoryId: 'goods',
        interestIds: const ['goods'],
        bio: 'テスト',
      );
      final user = await auth.buildSessionUser(lat: 35.0, lng: 139.0);
      expect(user, isNotNull);
      expect(user!.nickname, '花子');
      expect(user.lat, 35.0);
    });
  });

  group('AiConcierge（AI接客デモ）', () {
    final me = AppUser(
      id: 'me',
      nickname: '太郎',
      decade: '30代',
      gender: 'male',
      iconCategoryId: 'sauna',
      interestIds: const ['sauna'],
      bio: 'テスト',
      lat: 35.0,
      lng: 139.0,
    );
    final store = BusinessUser(
      id: 'b-sento-sakura',
      nickname: '銭湯 桜の湯',
      decade: '経営者',
      gender: 'undisclosed',
      iconCategoryId: 'sento',
      interestIds: const [],
      bio: 'デモ店舗',
      lat: 35.0,
      lng: 139.0,
      storeType: '銭湯',
    );

    test('挨拶は店舗の口調とユーザーの興味を踏まえて案内する', () {
      final g = aiConcierge.greeting(me, store);
      expect(g, contains('いらっしゃい')); // 銭湯の口調
      expect(g, contains('太郎'));
      expect(g, contains('銭湯 桜の湯'));
      expect(g, contains('ぬるめの湯と駄菓子コーナー'));
    });

    test('口調は店舗タイプごとに変わる', () {
      final rest = BusinessUser(
        id: 'b-sauna-mokumoku',
        nickname: 'サウナ専門店 むくむく',
        decade: '経営者',
        gender: 'undisclosed',
        iconCategoryId: 'sauna',
        interestIds: const [],
        bio: 'デモ店舗',
        lat: 35.0,
        lng: 139.0,
        storeType: 'サウナ専門店',
      );
      expect(aiConcierge.greeting(me, rest), contains('ロウリュ'));
    });

    test('キーワードに応じた応答をする（おすすめ/料金/予約/unknown）', () {
      final ai = aiConcierge;
      expect(ai.reply('おすすめは？', me, store), contains('ぬるめの湯と駄菓子コーナー'));
      expect(ai.reply('予約したいです', me, store), contains('平日'));
      // どのキーワードにも当てはまらない場合は案内を返す
      expect(ai.reply('こんにちは', me, store), contains('おすすめ'));
    });
  });

  group('AppState（ドメイン状態）', () {
    test('ログインすると近くの募集・一般・ビジネスユーザーが見える', () {
      final state = AppState();
      expect(state.me, isNull);
      expect(state.activeRecruitments(), isEmpty);

      state.attachUser(_testUser(state), reseed: true);
      expect(state.me, isNotNull);
      expect(state.activeRecruitments(), isNotEmpty);
      expect(state.generalUsers, isNotEmpty);
      expect(state.businessUsers, isNotEmpty);
      // ビジネスユーザーは募集一覧の host には出てこない
      expect(
        state.activeRecruitments().every(
            (r) => state.userById(r.hostId).isBusiness == false),
        isTrue,
      );
    });

    test('GPS適用でモックが現在地周囲に再配置される', () {
      final state = AppState();
      state.attachUser(_testUser(state), reseed: true);
      state.applyGps(43.0, 141.0);
      expect(state.gpsAvailable, isTrue);
      // 一般ユーザーは現在地（anchor）から粗いバンド内に並ぶ
      for (final u in state.generalUsers) {
        final km = haversineKm(state.anchorLat, state.anchorLng, u.lat, u.lng);
        expect(km, lessThan(6.0));
      }
    });

    test('募集を作ると期限付きで立ち一覧に載る', () async {
      final state = AppState();
      state.attachUser(_testUser(state), reseed: true);
      final rec = await state.createRecruitment(
        genreId: 'tour',
        title: 'テストの募集',
        body: '本文',
        meetup: 'テスト駅',
        capacity: 2,
        expiryHours: 2,
      );
      expect(rec.isActiveAt(DateTime.now()), isTrue);
      expect(state.activeRecruitments().map((r) => r.id), contains(rec.id));
      expect(state.recruitmentDistanceLabel(rec), 'あなたの募集');
    });

    test('他人の募集への応募は数秒後に承認され部屋ができる（デモ挙動）', () async {
      final state = AppState();
      state.attachUser(_testUser(state), reseed: true);
      final target = state
          .activeRecruitments()
          .firstWhere((r) => r.hostId != state.me!.id);
      state.applyTo(target.id, message: 'よろしくお願いします');
      expect(state.myPendingApplication(target.id), isNotNull);
      await Future<void>.delayed(const Duration(seconds: 4));
      expect(state.myRooms, isNotEmpty);
      expect(state.messagesOf(state.myRooms.first.id), isNotEmpty);
    });

    test('存在しない応募の承認 / 却下は無視される', () {
      final state = AppState();
      state.attachUser(_testUser(state), reseed: true);
      state.acceptApplication('nonexistent');
      state.declineApplication('nonexistent');
      expect(state.myRooms, isEmpty);
    });

    test('投稿アイコン画像は GPS・プロフィール更新でも保持される', () {
      final state = AppState();
      state.attachUser(_testUser(state), reseed: true);
      state.updateProfile(
        nickname: 'テスト太郎',
        decade: '30代',
        gender: 'male',
        iconCategoryId: 'sento',
        interestIds: const ['sento'],
        bio: 'テスト',
        iconImagePath: '/data/user/0/app/icons/icon_1.jpg',
      );
      expect(state.me!.iconImagePath, isNotEmpty);
      state.applyGps(43.0, 141.0);
      expect(state.me!.iconImagePath, isNotEmpty);
    });

    test('DM: 同一相手との部屋は再利用され、違う相手は別の部屋になる', () async {
      final state = AppState();
      state.attachUser(_testUser(state), reseed: true);
      final other = state.generalUsers.first;
      final dm1 = await state.getOrCreateDm(other.id);
      final dm2 = await state.getOrCreateDm(other.id);
      expect(dm1.id, dm2.id);
      final other2 = state.generalUsers[1];
      final dm3 = await state.getOrCreateDm(other2.id);
      expect(dm3.id, isNot(dm1.id));
      expect(state.myRooms.where((r) => r.isDm), hasLength(2));
      expect(state.lastMessageOf(dm1.id), isNotEmpty); // system メッセージ
    });

    test('リアルタイム着信は重複せず、他人のメッセージは未読が増える',
        () async {
      final state = AppState();
      state.attachUser(_testUser(state), reseed: true);
      final other = state.generalUsers.first;
      final room = await state.getOrCreateDm(other.id);
      final before = state.unreadByRoom[room.id] ?? 0;
      final msg = ChatMessage(
        id: 'incoming-1',
        roomId: room.id,
        senderId: other.id,
        body: 'こんにちは',
        sentAt: DateTime.now(),
      );
      state.handleIncomingMessage(room.id, msg);
      state.handleIncomingMessage(room.id, msg); // 重複着信
      expect(
          state.messagesOf(room.id)
              .where((m) => m.id == 'incoming-1'),
          hasLength(1));
      expect(state.unreadByRoom[room.id], before + 1);
    });

    test('コミュニティ: モックでは参加中シードがあり、参加すると部屋ができる',
        () async {
      final state = AppState();
      state.attachUser(_testUser(state), reseed: true);
      expect(state.communities, isNotEmpty);
      final target =
          state.communities.firstWhere((c) => !c.memberIds.contains('me'));
      final before = state.myRooms.length;
      await state.joinCommunity(target.id);
      expect(state.myCommunities.map((c) => c.id), contains(target.id));
      expect(state.myRooms.length, before + 1);
      final room = state.myRooms
          .firstWhere((r) => r.communityId == target.id);
      expect(room.isCommunity, isTrue);
      // コミュニティチャットに投稿できる
      await state.sendCommunityMessage(target.id, 'こんにちは');
      expect(state.lastMessageOf(room.id), contains('こんにちは'));
    });

    test('コミュニティ作成とイベント企画（誰でも作成できる）', () async {
      final state = AppState();
      state.attachUser(_testUser(state), reseed: true);
      final created = await state.createCommunity(
        name: 'テスト同好会',
        description: 'テスト用',
        linkedStore: null,
      );
      expect(created.memberIds, contains('me'));
      // 作成者は自動で参加し、チャット部屋ができている
      expect(state.myRooms.where((r) => r.communityId == created.id),
          isNotEmpty);
      final event = await state.createEvent(
        communityId: created.id,
        title: 'テストオフ会',
        body: '',
        eventTime: '来週土曜',
        locationName: '駅前',
        capacity: 3,
      );
      final stored = state.eventsOf(created.id);
      expect(stored, hasLength(1));
      expect(stored.first.id, event.id);
      expect(stored.first.participantIds, contains('me')); // 主催は自動参加
    });

    test('イベントへの参加・取消ができる', () async {
      final state = AppState();
      state.attachUser(_testUser(state), reseed: true);
      // シード済みコミュニティ（自分未参加の c-shooting）のイベントへ参加する
      final community =
          state.communities.firstWhere((c) => c.id == 'c-tour');
      final target = state.eventsOf(community.id).first;
      await state.joinEvent(target.id);
      expect(state.eventsOf(community.id).first.participantIds,
          contains('me'));
      await state.leaveEvent(target.id);
      expect(state.eventsOf(community.id).first.participantIds,
          isNot(contains('me')));
    });

    test('興味カテゴリをユーザーが自由に追加できる（重複名は拒否）', () async {
      SharedPreferences.setMockInitialValues({});
      final state = AppState();
      state.attachUser(_testUser(state), reseed: true);
      // attachUser 内で loadCategories が走る
      final before = state.categories.length;
      final created =
          await state.addCategory(label: 'ロウリュ研究会', iconName: 'hot_tub');
      expect(created, isNotNull);
      expect(state.categories.length, before + 1);
      expect(state.categories.any((c) => c.label == 'ロウリュ研究会'), isTrue);
      // 未知のIDはフォールバック表示（例外にならない）
      final unknown = state.categoryOf('made-on-other-device');
      expect(unknown.label, 'made-on-other-device');
      // 同名カテゴリは拒否される
      final dup =
          await state.addCategory(label: 'ロウリュ研究会', iconName: 'spa');
      expect(dup, isNull);
      expect(state.categories.length, before + 1);
    });

    test('ブロックすると相手のプロフィール・募集・DM部屋が非表示になる（解除で戻る）',
        () async {
      SharedPreferences.setMockInitialValues({});
      final state = AppState();
      state.attachUser(_testUser(state), reseed: true);
      final hostId = state
          .activeRecruitments()
          .firstWhere((r) => r.hostId != state.me!.id)
          .hostId;
      // ブロック前: 一覧に見え、DM部屋も見える
      expect(state.generalUsers.any((u) => u.id == hostId), isTrue);
      expect(
          state.activeRecruitments().any((r) => r.hostId == hostId), isTrue);
      final dm = await state.getOrCreateDm(hostId);
      expect(state.myRooms.any((r) => r.id == dm.id), isTrue);

      await state.blockUser(hostId);
      expect(state.isBlocked(hostId), isTrue);
      expect(state.generalUsers.any((u) => u.id == hostId), isFalse);
      expect(
          state.activeRecruitments().any((r) => r.hostId == hostId), isFalse);
      expect(state.myRooms.any((r) => r.id == dm.id), isFalse);

      await state.unblockUser(hostId);
      expect(state.isBlocked(hostId), isFalse);
      expect(state.generalUsers.any((u) => u.id == hostId), isTrue);
      expect(
          state.activeRecruitments().any((r) => r.hostId == hostId), isTrue);
      expect(state.myRooms.any((r) => r.id == dm.id), isTrue);
    });

    test('ブロック一覧は端末に保存され、アプリ再起動でも復元される', () async {
      SharedPreferences.setMockInitialValues({});
      final state1 = AppState();
      state1.attachUser(_testUser(state1), reseed: true);
      final target = state1.generalUsers.first;
      await state1.blockUser(target.id);

      // 新しいインスタンス（= アプリ再起動）でも復元される
      final state2 = AppState();
      await state2.loadBlockedUsers();
      expect(state2.isBlocked(target.id), isTrue);
      expect(state2.blockedUserIds, contains(target.id));
    });

    test('コミュニティは近い順に並ぶ（メンバー内の最寄り距離でソート）', () {
      final state = AppState();
      state.attachUser(_testUser(state), reseed: true);
      final sorted = state.nearbyCommunities;
      expect(sorted, isNotEmpty);
      for (var i = 1; i < sorted.length; i++) {
        expect(state.communityDistanceKm(sorted[i - 1]),
            lessThanOrEqualTo(state.communityDistanceKm(sorted[i])));
      }
      // 全コミュニティが距離を持っている（シードのメンバーは現在地周囲に配置済み）
      for (final c in sorted) {
        expect(state.communityDistanceKm(c).isFinite, isTrue);
        expect(state.communityDistanceLabel(c), isNotEmpty);
      }
    });

    test('ゆずりあい・交換: シードは近い順に並び、ゆずる・探す両方を含む', () {
      final state = AppState();
      state.attachUser(_testUser(state), reseed: true);
      final items = state.partsExchanges;
      expect(items, isNotEmpty);
      expect(items.any((p) => p.isGive), isTrue);
      expect(items.any((p) => p.isWanted), isTrue);
      final me = state.me!;
      double km(BathGoodsExchange p) => haversineKm(me.lat, me.lng, p.lat, p.lng);
      for (var i = 1; i < items.length; i++) {
        expect(km(items[i - 1]), lessThanOrEqualTo(km(items[i])));
      }
      for (final p in items) {
        // 相対配置されているので全シードが現在地の近くにある
        expect(km(p), lessThan(6.0));
        expect(state.partsExchangeDistanceLabel(p), isNotEmpty);
      }
    });

    test('ゆずりあい・交換: 登録して一覧に出し、完了で消える', () async {
      final state = AppState();
      state.attachUser(_testUser(state), reseed: true);
      final created = await state.registerBathGoodsExchange(
        kind: 'give',
        itemDescription: 'テストサウナハット（中古）',
        areaName: 'テスト銭湯前',
        detail: 'テスト銭湯の入り口前で受け渡せます',
        photoPath: '/data/item_photos/item_photo_1.jpg',
      );
      expect(created.isGive, isTrue);
      expect(created.photoPath, '/data/item_photos/item_photo_1.jpg');
      expect(
          state.partsExchanges.any((p) => p.id == created.id), isTrue);
      await state.closeBathGoodsExchange(created.id);
      expect(
          state.partsExchanges.any((p) => p.id == created.id), isFalse);
    });  });

  group('models', () {
    test('Recruitment の期限切れ / 満員状態（FR-2-1）', () {
      final now = DateTime(2026, 2, 1, 12, 0);
      final rec = Recruitment(
        id: 'r-x',
        hostId: 'h',
        genreId: 'tour',
        title: 't',
        body: 'b',
        meetup: 'm',
        capacity: 2,
        createdAt: now,
        expiresAt: now.add(const Duration(hours: 2)),
        memberIds: const ['h'],
      );
      expect(rec.isActiveAt(now), isTrue);
      expect(rec.statusAt(now), RecStatus.active);
      expect(rec.statusAt(now.add(const Duration(hours: 3))),
          RecStatus.expired);

      final full = Recruitment(
        id: rec.id,
        hostId: rec.hostId,
        genreId: rec.genreId,
        title: rec.title,
        body: rec.body,
        meetup: rec.meetup,
        capacity: rec.capacity,
        createdAt: rec.createdAt,
        expiresAt: rec.expiresAt,
        memberIds: const ['h', 'x'],
      );
      expect(full.isActiveAt(now), isFalse);
      expect(full.statusAt(now), RecStatus.fulfilled);
      expect(full.remainingSlots, 0);
    });
  });

  testWidgets('未ログインではログイン画面が出る', (tester) async {
    await tester.pumpWidget(const YutomoApp());
    expect(find.text('湯とも！'), findsOneWidget);
    expect(find.text('ログイン'), findsWidgets);
    expect(find.text('はじめての方は会員登録へ'), findsOneWidget);
    expect(find.text('会員登録'), findsNothing);

    // 会員登録へ遷移できる
    await tester.tap(find.text('はじめての方は会員登録へ'));
    await tester.pumpAndSettle();
    expect(find.text('会員登録'), findsWidgets);
    // 同意前は先へ進めない（FR-1-4, 1.2）
    final next = find
        .ancestor(of: find.text('プロフィール入力へ'),
            matching: find.byType(FilledButton))
        .first;
    expect(tester.widget<FilledButton>(next).enabled, isFalse);
  });

  testWidgets('DMは承認不要で即座に部屋が開く（回帰テスト）', (tester) async {
    // DM部屋は募集と紐付かない（recruitmentId が空）のため、
    // チャット画面は募集を必須として扱ってはならない
    appState.attachUser(_testUser(appState), reseed: true);
    final other = appState.generalUsers.first;
    final room = await appState.getOrCreateDm(other.id);
    expect(room.isDm, isTrue);
    expect(room.recruitmentId, isEmpty);

    await tester.pumpWidget(
      MaterialApp(home: ChatScreen(roomId: room.id)),
    );
    await tester.pump();
    expect(find.text('部屋が見つかりません'), findsNothing);
    expect(find.text('DM（1:1）'), findsOneWidget);
    expect(find.text(other.nickname), findsOneWidget);

    // チャット画面のタイマーを破棄するため別の画面に差し替える
    await tester.pumpWidget(const SizedBox());
  });
}
