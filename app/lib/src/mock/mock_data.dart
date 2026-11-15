import 'dart:math' as math;

import '../models.dart';

/// モックユーザーは「anchor（中心点）からの相対距離」で配置する。
/// anchor には実 GPS で取得した現在地が入り、どこにいても近くの湯とも候補が並ぶ。
class _MockSpec {
  final String id;
  final String nickname;
  final String decade;
  final String gender;
  final String iconCategoryId;
  final List<String> interestIds;
  final String bio;
  final double northKm; // anchor からの北方向距離
  final double eastKm; // anchor からの東方向距離

  const _MockSpec(this.id, this.nickname, this.decade, this.gender,
      this.iconCategoryId, this.interestIds, this.bio, this.northKm,
      this.eastKm);
}

const List<_MockSpec> _specs = [
  _MockSpec(
    'u-sento-ken',
    '銭湯のけん',
    '30代',
    'male',
    'sento',
    ['sento', 'super', 'saunameal'],
    '地元の銭湯をはしごしています。ペンキ絵とマッサージ椅子が好きです。',
    0.6,
    0.2,
  ),
  _MockSpec(
    'u-sauna-akira',
    'サウナのあきら',
    '40代',
    'male',
    'sauna',
    ['sauna', 'loyly', 'totonoi'],
    'オールサウナ歴を伸ばしています。ロウリュイベントは外しません。',
    -0.3,
    -0.1,
  ),
  _MockSpec(
    'u-onsen-nana',
    '温泉のなな',
    '20代',
    'female',
    'onsen',
    ['onsen', 'totonoi', 'repeat'],
    '日帰り温泉巡りが趣味です。源泉かけ流しに弱いです。',
    0.15,
    -0.4,
  ),
  _MockSpec(
    'u-mizuburo-sora',
    '水風呂のそら',
    '20代',
    'undisclosed',
    'mizuburo',
    ['sauna', 'mizuburo', 'ganban'],
    '水風呂10分でととのう派です。ととのい方を見せ合える人を探しています。',
    -0.7,
    0.5,
  ),
  _MockSpec(
    'u-ganban-miu',
    '岩盤浴のみう',
    '20代',
    'female',
    'ganban',
    ['ganban', 'spaland', 'saunameal'],
    '岩盤浴とサウナ飯の組み合わせが至上の喜びです。',
    1.2,
    -0.9,
  ),
  _MockSpec(
    'u-saunameal-kei',
    'サウナ飯のけい',
    '30代',
    'undisclosed',
    'saunameal',
    ['saunameal', 'super', 'sento'],
    'サウナ語ったあとの塩ラーメンが最高です。ごはん仲間を募集しています。',
    -1.1,
    1.0,
  ),
  _MockSpec(
    'u-spaland-hina',
    'スパ好きのひな',
    '30代',
    'female',
    'spaland',
    ['spaland', 'onsen', 'goods'],
    '週末は健康ランドの朝風呂です。流水プールで泳ぐのも好きです。',
    0.9,
    0.35,
  ),
  _MockSpec(
    'u-goods-kyo',
    'グッズ集めのきょう',
    '40代',
    'male',
    'goods',
    ['goods', 'repeat', 'loyly'],
    'サウナハットとタオルを集めています。お気に入り情報交換歓迎です。',
    0.45,
    -1.3,
  ),
];

class _BusinessSpec {
  final String id;
  final String nickname;
  final String iconCategoryId;
  final String storeType;
  final String bio;
  final double northKm;
  final double eastKm;

  const _BusinessSpec(this.id, this.nickname, this.iconCategoryId,
      this.storeType, this.bio, this.northKm, this.eastKm);
}

const List<_BusinessSpec> _businessSpecs = [
  _BusinessSpec(
    'b-sento-sakura',
    '銭湯 桜の湯',
    'sento',
    '銭湯',
    '創業60年の昔ながらの銭湯。ペンキ絵の富士山風呂とぬるめの湯があります。',
    0.8,
    0.9,
  ),
  _BusinessSpec(
    'b-super-daiyoku',
    'スーパー銭湯 大浴城',
    'spaland',
    'スーパー銭湯',
    'サウナ3種・岩盤浴完備。休憩処とお食事処も併設しています。',
    -0.5,
    1.1,
  ),
  _BusinessSpec(
    'b-onsen-yunohana',
    '日帰り温泉 湯の花荘',
    'onsen',
    '日帰り温泉',
    '源泉かけ流しの日帰り入浴。貸切風呂も予約できます。',
    1.5,
    -0.6,
  ),
  _BusinessSpec(
    'b-goods-mokumoku',
    'サウナグッズの店 もくもく',
    'goods',
    'サウナグッズ店',
    'サウナハットやアロマオイルの販売。ロウリュイベントも不定期開催。',
    -1.4,
    -0.8,
  ),
];

const double _kmPerDegLat = 111.32;

AppUser _specToUser(_MockSpec s, double anchorLat, double anchorLng) {
  final cos =
      math.cos(anchorLat * math.pi / 180.0).abs().clamp(0.01, 1.0);
  return AppUser(
    id: s.id,
    nickname: s.nickname,
    decade: s.decade,
    gender: s.gender,
    iconCategoryId: s.iconCategoryId,
    interestIds: s.interestIds,
    bio: s.bio,
    lat: anchorLat + s.northKm / _kmPerDegLat,
    lng: anchorLng + s.eastKm / (_kmPerDegLat * cos),
  );
}

BusinessUser _specToBusiness(
    _BusinessSpec s, double anchorLat, double anchorLng) {
  final cos =
      math.cos(anchorLat * math.pi / 180.0).abs().clamp(0.01, 1.0);
  return BusinessUser(
    id: s.id,
    nickname: s.nickname,
    decade: '経営者',
    gender: 'undisclosed',
    iconCategoryId: s.iconCategoryId,
    interestIds: const [],
    bio: s.bio,
    lat: anchorLat + s.northKm / _kmPerDegLat,
    lng: anchorLng + s.eastKm / (_kmPerDegLat * cos),
    storeType: s.storeType,
  );
}

/// 現在地を中心にモックユーザー（一般 + ビジネス）を配置する。
List<AppUser> buildMockUsers(double anchorLat, double anchorLng) {
  return [
    for (final s in _specs) _specToUser(s, anchorLat, anchorLng),
    for (final s in _businessSpecs) _specToBusiness(s, anchorLat, anchorLng),
  ];
}

/// シード募集（起動時刻からの残り時間で作るので、いつ開いても「今から」感が出る）。
/// host は generalUsers（モック一般ユーザー）から id で引く。
List<Recruitment> seedRecruitments(DateTime now, List<AppUser> generalUsers) {
  Recruitment make({
    required String hostId,
    required String genreId,
    required String title,
    required String body,
    required String meetup,
    required int capacity,
    required int minutesLeft,
  }) {
    return Recruitment(
      id: 'r-$hostId',
      hostId: hostId,
      genreId: genreId,
      title: title,
      body: body,
      meetup: meetup,
      capacity: capacity,
      createdAt: now.subtract(const Duration(minutes: 15)),
      expiresAt: now.add(Duration(minutes: minutesLeft)),
      memberIds: [hostId],
    );
  }

  return [
    make(
      hostId: 'u-sento-ken',
      genreId: 'tour',
      title: '今夜、近くの銭湯をめぐりませんか',
      body: 'はしごコースを2件予定しています。ぬるめ派も熱め派も歓迎です。',
      meetup: '銭湯 桜の湯 番台前',
      capacity: 4,
      minutesLeft: 105,
    ),
    make(
      hostId: 'u-sauna-akira',
      genreId: 'event',
      title: 'ロウリュ祭に同行しませんか',
      body: '大浴城のロウリュイベントに参戦します。アウフグースの後の水風呂が最高です。',
      meetup: 'スーパー銭湯 大浴城 3F サウナ受付',
      capacity: 3,
      minutesLeft: 70,
    ),
    make(
      hostId: 'u-saunameal-kei',
      genreId: 'event',
      title: 'サウナ語りのあと、食事会しませんか',
      body: '大浴城のレストランで塩ラーメンを予定しています。語るのが好きな人大歓迎。',
      meetup: 'スーパー銭湯 大浴城 レストラン前',
      capacity: 4,
      minutesLeft: 160,
    ),
    make(
      hostId: 'u-onsen-nana',
      genreId: 'event',
      title: '日帰り温泉の湯めぐり会',
      body: '湯の花荘でゆっくり帰りも予定しています。お風呂の後の休憩も大事です。',
      meetup: '日帰り温泉 湯の花荘 正面玄関',
      capacity: 4,
      minutesLeft: 95,
    ),
    make(
      hostId: 'u-ganban-miu',
      genreId: 'talk',
      title: '岩盤浴のはしご同伴者募集',
      body: '岩盤浴2周のあとサウナでととのえる方を探しています。水分補給は多めに。',
      meetup: 'スーパー銭湯 大浴城 岩盤浴受付',
      capacity: 4,
      minutesLeft: 130,
    ),
    make(
      hostId: 'u-mizuburo-sora',
      genreId: 'talk',
      title: 'ととのい方を研究する会、参加者募集',
      body: 'オイルの塗り方や水風呂の入り比べを見せ合う会です。初心者も歓迎。',
      meetup: '銭湯 桜の湯 脱衣所前のベンチ',
      capacity: 3,
      minutesLeft: 45,
    ),
  ];
}

/// ゆずりあい・交換のシード。anchor（現在地）からの相対距離で配置する。
/// id が 'cx-seed-' 始まりのものは GPS 更新のたびに再配置される
/// （AppState.applyGps を参照）。
class _ExchangeSeedSpec {
  final String id;
  final String posterId;
  final String kind;
  final String itemDescription;
  final String areaName;
  final String detail;
  final double northKm;
  final double eastKm;
  final Duration age;
  const _ExchangeSeedSpec(this.id, this.posterId, this.kind,
      this.itemDescription, this.areaName, this.detail, this.northKm,
      this.eastKm, this.age);
}

const List<_ExchangeSeedSpec> _exchangeSeedSpecs = [
  _ExchangeSeedSpec(
    'cx-seed-1',
    'u-goods-kyo',
    'give',
    'サウナハット（使用済み・洗浄済み）',
    '銭湯 桜の湯 周辺',
    '手編みのものが増えたので1個ゆずります。'
        '手渡し前提です。',
    0.3,
    -0.6,
    Duration(hours: 2),
  ),
  _ExchangeSeedSpec(
    'cx-seed-2',
    'u-mizuburo-sora',
    'wanted',
    'サウナ用ロングマットを探しています',
    '駅前広場 周辺',
    'バスマットの長めのものを探しています。不要グッズとの'
        '交換の対応も可能です。DMお待ちしています。',
    -0.2,
    0.8,
    Duration(hours: 5),
  ),
  _ExchangeSeedSpec(
    'cx-seed-3',
    'u-sauna-akira',
    'trade',
    'サウナ用アロマオイルと バスタオルを交換します',
    '市役所裏の公園 周辺',
    '香りの好みが変わったので交換希望です。状態は写真で'
        '送ります。公共の場所で受け渡しできます。',
    -0.9,
    -0.3,
    Duration(hours: 26),
  ),
];

List<BathGoodsExchange> buildSeedBathGoodsExchanges(
    DateTime now, double anchorLat, double anchorLng) {
  final cos = (anchorLat * math.pi / 180.0).abs().clamp(0.01, 1.0);
  return [
    for (final s in _exchangeSeedSpecs)
      BathGoodsExchange(
        id: s.id,
        posterId: s.posterId,
        kind: s.kind,
        itemDescription: s.itemDescription,
        areaName: s.areaName,
        detail: s.detail,
        lat: anchorLat + s.northKm / _kmPerDegLat,
        lng: anchorLng + s.eastKm / (_kmPerDegLat * cos),
        createdAt: now.subtract(s.age),
      ),
  ];
}

/// モックの返信候補（デモの自動応答に使う。本開発では Supabase Realtime に置換）
const List<String> mockReplies = [
  'よろしくお願いします！',
  '次の湯めぐり、楽しみですね。',
  '先に着いてロッカーを押さえておきますね。',
  'コースはぬるめの湯から回りましょうか。',
];

/// モックの応募メッセージ
const List<String> mockApplyMessages = [
  '参加したいです！湯仲間を探していました。',
  '同じ浴場によく通っているので嬉しいです。',
  'この近くのサウナイベントによく参戦しています。',
];
