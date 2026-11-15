import '../models.dart';

/// AI接客のデモ応答ロジック（プロトタイプ用のモック）。
/// 本開発では LLM API に置き換える。このロジックは店舗業態と
/// ユーザーの興味カテゴリからおすすめを案内する最低限のルールベース。
class AiConcierge {
  /// 最初の挨拶（店舗の口調 + ユーザーの興味を踏まえる）
  String greeting(AppUser me, BusinessUser store) {
    final interest = me.interestIds.isNotEmpty ? me.interestIds.first : null;
    final label = interest == null ? null : _categoryLabel(interest);
    final base = '${_opener(store)}'
        '${me.nickname}さん、${store.nickname}（${store.storeType}）のAI接客です。';
    if (label == null) {
      return '$base 銭湯・サウナのことなら何でも聞いてください。';
    }
    return '$base $labelがお好みなんですね。'
        'うちの${_recommend(store)}がおすすめです。';
  }

  /// 店舗タイプごとの口調（本開発では LLM に店舗キャラ設定を渡して生成する）
  String _opener(BusinessUser store) {
    switch (store.storeType) {
      case '銭湯':
        return 'いらっしゃい！駄菓子とペンキ絵もありますよ。';
      case 'スーパー銭湯':
        return 'いらっしゃいませ。サウナ・岩盤浴も完備しています。';
      case '日帰り温泉':
        return 'いらっしゃい。源泉かけ流しをごゆっくりどうぞ。';
      case 'スパ・健康ランド':
        return 'ようこそ。リラックスプールのご案内もできます。';
      case 'サウナ専門店':
        return 'いらっしゃい。ロウリュイベントの案内もしています。';
      case '岩盤浴施設':
        return 'こんにちは。岩盤浴はマイナスイオンたっぷりです。';
      case 'サウナグッズ店':
        return 'いらっしゃい。サウナハット選びもお手伝いします。';
      default:
        return 'いらっしゃいませ。';
    }
  }

  /// ユーザー発話への応答
  String reply(String input, AppUser me, BusinessUser store) {
    final text = input.replaceAll(RegExp(r'\s'), '');
    if (text.contains('予約') || text.contains('来店') || text.contains('利用')) {
      return 'ありがとうございます。土日は混み合うため、'
          '平日の午前中でしたらゆっくりご案内できます。'
          'ご希望の時間をメモしておきますね。'
          '（デモのため実際の予約機能は本開発で提供します）';
    }
    if (text.contains('おすすめ') || text.contains('オススメ')) {
      return '今回は${_recommend(store)}がおすすめです。'
          '湯めぐりの予定があれば教えてください。';
    }
    if (text.contains('サウナ') || text.contains('水風呂') ||
        text.contains('ロウリュ') || text.contains('ととのい')) {
      return '初めての方も歓迎しています。'
          'ととのい方のご相談も一緒に承ります。';
    }
    if (text.contains('料金') || text.contains('いくら') ||
        text.contains('価格')) {
      return 'ご利用内容によって変わりますが、まずは一度お試しいただけます。'
          '詳しいプランは店舗ページをご確認ください（デモの固定値です）。';
    }
    if (text.contains('何時') || text.contains('営業時間')) {
      return '本日は10:00〜18:00で営業しております。'
          '混雑しやすいのは土曜午前です。（デモの固定値です）';
    }
    if (text.contains('駐車場') || text.contains('アクセス')) {
      return '近隣にコインパーキングがあります。'
          '大きな荷物がある場合は事前にご相談ください。';
    }
    return '承知しました。「おすすめ」「料金」「営業時間」「予約」「サウナ」など、'
        '気になることを聞いていただければ答えます。';
  }

  String _recommend(BusinessUser store) {
    switch (store.storeType) {
      case '銭湯':
        return 'ぬるめの湯と駄菓子コーナー';
      case 'スーパー銭湯':
        return '平日の夕方混雑前のサウナ枠';
      case '日帰り温泉':
        return '源泉かけ流しの貸切風呂';
      case 'スパ・健康ランド':
        return '週末の流水プールと塩ラーメンセット';
      case 'サウナ専門店':
        return '今週末のロウリュイベント';
      case '岩盤浴施設':
        return '岩盤浴2周とハーブティーのコース';
      case 'サウナグッズ店':
        return '新作のサウナハットとアロマオイル';
      default:
        return 'おすすめサービス';
    }
  }

  String _categoryLabel(String id) {
    const labels = {
      'sento': '銭湯',
      'super': 'スーパー銭湯',
      'sauna': 'サウナ',
      'loyly': 'ロウリュ・アウフグース',
      'mizuburo': '水風呂',
      'onsen': '日帰り温泉',
      'ganban': '岩盤浴',
      'spaland': 'スパ・健康ランド',
      'saunameal': 'サウナ飯',
      'totonoi': 'ととのい',
      'repeat': 'リピート制サウナ',
      'goods': 'サウナグッズ',
    };
    return labels[id] ?? 'お風呂・サウナのこと';
  }
}

/// グローバルインスタンス（本開発では DI / LLM API クライアントに置き換える）
final AiConcierge aiConcierge = AiConcierge();
