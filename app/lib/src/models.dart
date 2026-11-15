import 'package:flutter/material.dart';

/// 募集ジャンル
class Genre {
  final String id;
  final String label;
  final IconData icon;
  const Genre(this.id, this.label, this.icon);
}

const List<Genre> genres = [
  Genre('tour', '銭湯・サウナめぐり', Icons.hot_tub),
  Genre('event', 'イベント・湯めぐり会', Icons.celebration),
  Genre('talk', '交流・オフ会（ととのい）', Icons.groups),
];

Genre genreById(String id) => genres.firstWhere((g) => g.id == id);

/// ともつく！シリーズ（趣味特化型マッチングアプリ群）の共通定義。
/// 飯とも！・犬とも！・釣りとも！・ニーアキャット・コスとも！・湯とも！は同一のSupabase
/// プロジェクト・アカウントを共有し、このapp_idで各アプリのデータを識別する。
const Map<String, String> tomoTskuAppNames = {
  'meshitomo': '飯とも！',
  'inutomo': '犬とも！',
  'tsuritomo': '釣りとも！',
  'nekotomo': 'ニーアキャット',
  'costomo': 'コスとも！',
  'hashitomo': '走りとも！',
  'campotomo': 'キャンとも！',
  'ototomo': '音とも！',
  'yutomo': '湯とも！',
  'supotomo': 'スポとも！',
  'janotomo': '雀とも！',
  'gametomo': 'ゲーとも！',
};

/// 興味カテゴリ。
/// `interestCategories` は初期セット（デフォルト）。ユーザーは自由に
/// カテゴリを追加でき（AppState.categoryRegistry）、Supabase モードでは
/// 全ユーザーに共有される。
class InterestCategory {
  final String id;
  final String label;
  final IconData icon;
  const InterestCategory(this.id, this.label, this.icon);
}

const List<InterestCategory> interestCategories = [
  InterestCategory('sento', '銭湯', Icons.hot_tub),
  InterestCategory('super', 'スーパー銭湯', Icons.storefront),
  InterestCategory('sauna', 'サウナ', Icons.local_fire_department),
  InterestCategory('loyly', 'ロウリュ・アウフグース', Icons.air),
  InterestCategory('mizuburo', '水風呂', Icons.water_drop),
  InterestCategory('onsen', '日帰り温泉', Icons.spa),
  InterestCategory('ganban', '岩盤浴', Icons.whatshot),
  InterestCategory('spaland', 'スパ・健康ランド', Icons.pool),
  InterestCategory('saunameal', 'サウナ飯', Icons.restaurant),
  InterestCategory('totonoi', 'ととのい', Icons.self_improvement),
  InterestCategory('repeat', 'リピート制サウナ', Icons.replay),
  InterestCategory('goods', 'サウナグッズ', Icons.checkroom),
];

/// カスタムカテゴリのアイコン候補（名前でDB保存するため定数マップ）。
/// 本アプリは銭湯・サウナに特化するため、アイコンもお風呂・サウナ系のみとする
/// （その他の趣味は別アプリで展開する方針）。
const Map<String, IconData> categoryIconChoices = {
  'hot_tub': Icons.hot_tub,
  'storefront': Icons.storefront,
  'fire': Icons.local_fire_department,
  'air': Icons.air,
  'water_drop': Icons.water_drop,
  'spa': Icons.spa,
  'whatshot': Icons.whatshot,
  'pool': Icons.pool,
  'restaurant': Icons.restaurant,
  'self_improvement': Icons.self_improvement,
  'replay': Icons.replay,
  'checkroom': Icons.checkroom,
  'star': Icons.star,
  'sparkle': Icons.auto_awesome,
};

/// アイコン名から IconData を引く（未登録の名前はデフォルトを返す）
IconData categoryIconByName(String? name) =>
    categoryIconChoices[name] ?? Icons.hot_tub;

/// プロトタイプ用のモック現在地（本開発では端末の GPS + geohash に置き換える）
class MockLocation {
  final String id;
  final String name;
  final double lat;
  final double lng;
  const MockLocation(this.id, this.name, this.lat, this.lng);
}

const List<MockLocation> mockLocations = [
  MockLocation('tokyo', '東京駅', 35.6812, 139.7671),
  MockLocation('yurakucho', '有楽町', 35.6748, 139.7629),
  MockLocation('akiba', '秋葉原', 35.7023, 139.7745),
  MockLocation('shibuya', '渋谷', 35.6580, 139.7016),
  MockLocation('shinjuku', '新宿', 35.6896, 139.7006),
  MockLocation('shinagawa', '品川', 35.6285, 139.7394),
];

/// 近くの施設（「近くの立ち寄り施設を探す」機能:
/// 銭湯・スーパー銭湯・日帰り温泉・スパ・サウナ施設）。
/// 実データは OpenStreetMap（Overpass API）から現在地周辺で取得する。
class CatSpot {
  final String osmId; // 例: 'way/12345'
  final String name;
  final String type; // 'sento'（銭湯・スーパー銭湯） | 'onsen'（日帰り温泉・湯治） | 'spa'（スパ・健康ランド） | 'sauna'（サウナ施設）
  final double lat;
  final double lng;
  final double distanceKm; // 現在地からの距離
  final String? openingHours;

  const CatSpot({
    required this.osmId,
    required this.name,
    required this.type,
    required this.lat,
    required this.lng,
    required this.distanceKm,
    this.openingHours,
  });

  bool get isSento => type == 'sento';
}

class AppUser {
  final String id;
  final String nickname;
  final String decade; // 例: '20代'。ビジネスユーザーは '経営者'
  final String gender; // 'male' | 'female' | 'undisclosed'
  final String iconCategoryId; // 趣味アイコン（顔画像は禁止）
  final String? iconImagePath; // 端末内に保存した投稿アイコン画像（あれば優先表示）
  final List<String> interestIds;
  final String bio;
  final double lat;
  final double lng;
  final String? websiteUrl; // 公開URL（例: 店のホームページ）
  final String? snsNote; // SNS（例: 'X: @yutomo_official / IG: yutomo'）
  final String? phone; // ビジネスユーザー（店舗）の電話番号。タップで発信
  final String? appSource; // このプロフィール行の由来アプリ（自分のアプリなら null）
  final bool crossAppVisible; // ともつく！全体に表示する設定（この行の値）

  const AppUser({
    required this.id,
    required this.nickname,
    required this.decade,
    required this.gender,
    required this.iconCategoryId,
    required this.interestIds,
    required this.bio,
    required this.lat,
    required this.lng,
    this.iconImagePath,
    this.websiteUrl,
    this.snsNote,
    this.phone,
    this.appSource,
    this.crossAppVisible = false,
  });

  String get genderLabel => const {'male': '男性', 'female': '女性'}.containsKey(gender)
      ? const {'male': '男性', 'female': '女性'}[gender]!
      : '非公開';

  bool get isBusiness => false;

  /// 他のともつく！アプリ由来のプロフィール行か
  bool get isOtherApp => appSource != null;

  /// 由来アプリの表示名（例: '釣りとも！'）
  String get appSourceLabel =>
      isOtherApp ? (tomoTskuAppNames[appSource] ?? appSource!) : '';

  /// 位置だけ変えたコピーを返す
  AppUser withPosition(double newLat, double newLng) {
    return AppUser(
      id: id,
      nickname: nickname,
      decade: decade,
      gender: gender,
      iconCategoryId: iconCategoryId,
      interestIds: interestIds,
      bio: bio,
      lat: newLat,
      lng: newLng,
      iconImagePath: iconImagePath,
      websiteUrl: websiteUrl,
      snsNote: snsNote,
      phone: phone,
      appSource: appSource,
      crossAppVisible: crossAppVisible,
    );
  }
}

/// ビジネスユーザー（店舗。一般ユーザー登録と分離された登録フローで作られる）
class BusinessUser extends AppUser {
  final String storeType; // 例: 'スーパー銭湯'

  const BusinessUser({
    required super.id,
    required super.nickname,
    required super.decade,
    required super.gender,
    required super.iconCategoryId,
    required super.interestIds,
    required super.bio,
    required super.lat,
    required super.lng,
    required this.storeType,
    super.iconImagePath,
    super.websiteUrl,
    super.snsNote,
    super.phone,
    super.appSource,
    super.crossAppVisible,
  });

  @override
  bool get isBusiness => true;

  @override
  AppUser withPosition(double newLat, double newLng) {
    return BusinessUser(
      id: id,
      nickname: nickname,
      decade: decade,
      gender: gender,
      iconCategoryId: iconCategoryId,
      interestIds: interestIds,
      bio: bio,
      lat: newLat,
      lng: newLng,
      storeType: storeType,
      iconImagePath: iconImagePath,
      websiteUrl: websiteUrl,
      snsNote: snsNote,
      phone: phone,
      appSource: appSource,
      crossAppVisible: crossAppVisible,
    );
  }
}

enum RecStatus { active, fulfilled, expired, cancelled }

class Recruitment {
  final String id;
  final String hostId;
  final String genreId;
  final String title;
  final String body;
  final String meetup;
  final int capacity;
  final DateTime createdAt;
  final DateTime expiresAt;
  final List<String> memberIds; // host を含む

  const Recruitment({
    required this.id,
    required this.hostId,
    required this.genreId,
    required this.title,
    required this.body,
    required this.meetup,
    required this.capacity,
    required this.createdAt,
    required this.expiresAt,
    required this.memberIds,
  });

  bool get isFull => memberIds.length >= capacity;

  bool isActiveAt(DateTime now) =>
      now.isBefore(expiresAt) && !isFull && memberIds.isNotEmpty;

  int get remainingSlots => capacity - memberIds.length;

  RecStatus statusAt(DateTime now) {
    if (isFull) return RecStatus.fulfilled;
    if (!now.isBefore(expiresAt)) return RecStatus.expired;
    return RecStatus.active;
  }
}

enum JoinStatus { pending, accepted, declined }

class JoinApplication {
  final String id;
  final String recruitmentId;
  final String applicantId;
  final String message;
  JoinStatus status;
  final DateTime createdAt;

  JoinApplication({
    required this.id,
    required this.recruitmentId,
    required this.applicantId,
    required this.message,
    required this.status,
    required this.createdAt,
  });
}

class ChatRoom {
  final String id;
  final String recruitmentId; // DM・コミュニティの場合は空文字
  final List<String> memberIds;
  final DateTime createdAt;
  final String type; // 'group' | 'dm' | 'community'
  final String? communityId; // コミュニティチャットの場合

  ChatRoom({
    required this.id,
    required this.recruitmentId,
    required this.memberIds,
    required this.createdAt,
    this.type = 'group',
    this.communityId,
  });

  bool get isDm => type == 'dm';

  bool get isCommunity => type == 'community';
}

/// コミュニティ（クラブ・イベント企画・店舗のファンコミュニティ）。
/// 誰でも作成でき、参加するとコミュニティチャットが開ける（FR-6-1〜6-3）。
class Community {
  final String id;
  final String ownerId;
  final String name;
  final String description;
  final String? linkedStore; // 店舗ファンコミュニティの場合の店舗名
  final DateTime createdAt;
  final Set<String> memberIds;

  Community({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.description,
    required this.linkedStore,
    required this.createdAt,
    required this.memberIds,
  });

  Community copyWith({
    Set<String>? memberIds,
    String? name,
    String? description,
  }) {
    return Community(
      id: id,
      ownerId: ownerId,
      name: name ?? this.name,
      description: description ?? this.description,
      linkedStore: linkedStore,
      createdAt: createdAt,
      memberIds: memberIds ?? this.memberIds,
    );
  }
}

/// コミュニティ内で企画されるイベント・クラブ
class CommunityEvent {
  final String id;
  final String communityId;
  final String hostId;
  final String title;
  final String body;
  final String eventTime; // ベータでは自由記述（例: '3/14 19:00〜'）
  final String locationName;
  final int capacity;
  final DateTime createdAt;
  final Set<String> participantIds;

  CommunityEvent({
    required this.id,
    required this.communityId,
    required this.hostId,
    required this.title,
    required this.body,
    required this.eventTime,
    required this.locationName,
    required this.capacity,
    required this.createdAt,
    required this.participantIds,
  });

  bool get isFull => participantIds.length >= capacity;

  CommunityEvent copyWith({Set<String>? participantIds}) {
    return CommunityEvent(
      id: id,
      communityId: communityId,
      hostId: hostId,
      title: title,
      body: body,
      eventTime: eventTime,
      locationName: locationName,
      capacity: capacity,
      createdAt: createdAt,
      participantIds: participantIds ?? this.participantIds,
    );
  }
}

/// サウナグッズの「ゆずりあい・交換」掲示板（近隣での情報共有）。
/// kind: 'give'   = サウナグッズをゆずります
///       'wanted' = サウナグッズを探しています
///       'trade'  = 交換します
/// 金銭取引は行わない（銭湯の入り口前・駅前広場での受け渡し・ゆずり合い前提）。
class BathGoodsExchange {
  final String id;
  final String posterId;
  final String kind; // 'give' | 'wanted' | 'trade'
  final String itemDescription; // グッズ名（サウナハット・バスマット・タオル等の状態など）
  final String areaName; // 受け渡し希望地域やイベント名
  final String detail; // 状態・受け渡し方法の自由記述
  final String? photoPath; // 投稿写真（端末内パス or 公開URL）
  final double lat;
  final double lng;
  final DateTime createdAt;
  bool closed; // 完了（受け渡し・交換が成立した等）

  BathGoodsExchange({
    required this.id,
    required this.posterId,
    required this.kind,
    required this.itemDescription,
    required this.areaName,
    required this.detail,
    required this.lat,
    required this.lng,
    required this.createdAt,
    this.photoPath,
    this.closed = false,
  });

  /// ゆずります
  bool get isGive => kind == 'give';

  /// 探しています
  bool get isWanted => kind == 'wanted';

  /// 交換します
  bool get isTrade => kind == 'trade';
}

class ChatMessage {
  final String id;
  final String roomId;
  final String senderId; // system の場合 'system'
  final String body;
  final DateTime sentAt;
  final bool isSystem;

  ChatMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.body,
    required this.sentAt,
    this.isSystem = false,
  });
}
