# 湯とも！（Yutomo）

**銭湯・サウナ好き同士が、趣味・中身ベースでつながる趣味特化型マッチングアプリのプロトタイプです。** 近くの同じ趣味の人（湯とも）を探して湯めぐり・ととのいオフなどに誘い合えます。ともつく！シリーズの第9弾（銭湯・サウナ Edition）で、第1弾: [飯とも！Meshitomo](https://github.com/daichiyabunaka-rgb/Meshitomo-app-prototype)、第2弾: [犬とも！Inutomo](https://github.com/daichiyabunaka-rgb/Inutomo-app-prototype)、第3弾: [釣りとも！Tsuritomo](https://github.com/daichiyabunaka-rgb/Tsuritomo-app-prototype)、第4弾: [ニーアキャット Nekotomo](https://github.com/daichiyabunaka-rgb/Nekotomo-app-prototype)、第5弾: [コスとも！Costomo](https://github.com/daichiyabunaka-rgb/Costomo-app-prototype)、第6弾: [走りとも！Hashitomo](https://github.com/daichiyabunaka-rgb/Hashitomo-app-prototype)、第8弾: [音とも！Ototomo](https://github.com/daichiyabunaka-rgb/Ototomo-app-prototype) の設計を踏襲しています。

ビジネスモデルは、**一般ユーザー（無料）とビジネスユーザー（銭湯・スーパー銭湯・日帰り温泉・サウナ施設などの事業者）** の2層構造です。

## コンセプト・設計原則

| 原則 | 内容 |
|---|---|
| 本人の顔画像禁止 | アイコンは**銭湯・サウナ・浴場風景に関連する画像のみ**許可。本人の素顔がメインの画像はアップロード不可 |
| マナー遵守 | 入浴マナー・施設のルールを常に確認する設計。迷惑行為の募集は禁止文言で排除 |
| 恋愛目的禁止 | 出会い系としての法律が適用されないよう、利用規約で明示的に禁止 |
| 金銭取引禁止 | ゆずりあい・交換は無償の譲り合い・物々交換のみ。売買・オークション的な使い方は禁止 |
| 時限性 | 募集は期限付き（1〜3時間）。期限が来たら自動で消える |
| 距離は粗表示 | 位置は「〜1km / 1〜3km」のようなバンド表示のみ。正確な座標は非公開 |

**注意: モックデータには位置情報が含まれません。** モックの一般ユーザー・店舗は現在地（GPSまたは初期設定の場所）からの相対距離で配置されます。モックユーザーの配置先は端末内データのみに保存され、Supabase には送信されません。Supabase 接続時は Supabase 側のユーザーのデータのみ表示され、モックユーザーは表示されません。

## 実装機能（プロトタイプ）

- メール会員登録 / ログイン / ログアウト（端末内アカウント・セッションの永続化）
- GPS位置情報取得 →（距離バンド付きの）近くの湯とも / 店舗 / コミュニティ・イベントを一覧
- 募集（銭湯・サウナめぐり / イベント・湯めぐり会 / 交流・オフ会（ととのい）。1〜3時間の期限付きで「今から」感を出す）
- 1:1のDM
- コミュニティ・イベント（誰でも作成・参加でき、参加するとチャットが始まる）
- **近くの施設（特別機能）**: 現在地周辺の OpenStreetMap（Overpass API）から、銭湯・スーパー銭湯・日帰り温泉・スパ・健康ランド・サウナ施設を一覧表示。Googleマップで開く・その場で募集がワンタップで可能。民間の飲食店・公園は対象外
- **ゆずりあい・交換（特別機能）**: 使わなくなったサウナグッズ（サウナハット・バスマット・タオル等）を近隣で無償でゆずる・探す・交換するボード。投稿写真・掲載者へのDM・完了（解決済み）機能付き。**金銭取引は禁止**で、受け渡しは銭湯の入り口前・駅前広場など人目のある場所を前提
- 興味カテゴリ（銭湯 / スーパー銭湯 / サウナ / ロウリュ・アウフグース / 水風呂 / 日帰り温泉 / 岩盤浴 / スパ・健康ランド / サウナ飯 / ととのい / リピート制サウナ / サウナグッズ）はDBを通じて全ユーザーに共有される
- アイコン画像の投稿（Supabase Storage の公開バケットに自動リサイズ後アップロード。端末内フォールバック付き）
- **ともつく！シリーズとのアカウント共有**（他のともつく！アプリと同一の Supabase auth を共用。プロフィール・募集・DMは app_id でアプリごとに分離）
- **ともつく！連携**（アプリ横断表示 cross_app_visible・アプリ横断DM）

※ベータ版のため、メール登録確認機能・AI接客機能・ビジネスユーザーのAIチャットはロック中です。

## 構成

```
docs/
  要件定義書_湯とも_v1.md            機能要件・非機能要件・KPI・データモデル
  supabase_multiapp_migration.sql      共有DB化・app_id分離マイグレーション（tomotsuku-memo 0002相当）
  supabase_multiapp_v2_cross_app.sql   ともつく！連携（cross_app_visible。0003相当）
  supabase_yutomo_bath_goods.sql       ゆずりあい・交換テーブル・投稿写真バケットの作成（湯とも！用・0010相当）
app/                            Flutter アプリ（Android / iOS / Web 対応）
  lib/src/screens/             画面（near_page に 募集/人/店舗/施設 の4セクション）
  lib/src/services/            認証・位置情報・Supabase Data Access（app_id フィルタ・RLSを前提）
  lib/src/util/cat_spots.dart   近くの施設取得（Overpass API・ミラーフォールバック・キャッシュ・GoogleマップURL生成）
  lib/src/mock/                 モックユーザー・シード募集（GPS現在地からの相対距離で配置）
tools/make_icon.py              ランチャーアイコン生成スクリプト（Python + Pillow。フラットデザインの温泉マーク）
```

## 起動手順

```powershell
cd app
flutter pub get
flutter run -d chrome          # ブラウザ
flutter run -d <デバイスID>     # Android 端末（flutter devices で確認）
flutter build apk --release     # APK ビルド
```

接続DBは「ともつく！」シリーズ共通の Supabase プロジェクトです（接続情報と鍵の扱いは tomotsuku-memo リポジトリ参照）。

```powershell
flutter build apk --release --dart-define=SUPABASE_URL=https://hlcsuogoghrgqabkaqxm.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=<tomotsuku-memo参照>
```

dart-define を付けない場合はローカルモック（端末内データのみ）で起動します。

静的解析: `flutter analyze` / 自動テスト: `flutter test`

## Supabase 接続の前提

1. **共通DB**: 飯とも！・犬とも！・釣りとも！・ニーアキャット・コスとも！・走りとも！・キャンとも！・音とも！と同じ Supabase プロジェクトを共有します（アカウント〈auth.users〉共通、その他のデータは app_id で分離）。
2. **事前に適用が必要なマイグレーション**: `docs/supabase_multiapp_migration.sql` と `docs/supabase_multiapp_v2_cross_app.sql`（tomotsuku-memo の 0002 / 0003 と同一内容）。
3. **湯とも！用**: `docs/supabase_yutomo_bath_goods.sql` を Supabase Dashboard の SQL Editor で適用してください（bath_goods_exchanges テーブルと bath-goods-photos バケット、services マスタへの 'yutomo' 登録、delete_my_account の更新）。tomotsuku-memo の 0010 マイグレーションと同一内容です。
4. **アイコン投稿バケット**: `icons` バケットはシリーズ共通です（ユーザーごとの `UUID/yutomo/` 名前空間に配置されるため使い回せます）。
5. **施設検索**: OpenStreetMap（Overpass API）を利用。APIキー不要・User-Agent必須。銭湯（amenity=public_bath）・スパ（leisure=water_park）・サウナ（leisure=sauna）のみ検索し、民間の飲食店・公園は対象外。入浴マナー・施設ルールの確認を常に案内します。
6. **画像モデレーション**: アイコンの顔画像検証等は本リリース版で実装予定（他アプリの Human/Animal 判定相当）。

## 運用

- スキーマ変更は必ず [tomotsuku-memo](https://github.com/daichiyabunaka-rgb/tomotsuku-memo)（Private）の master を先に変更し、そこから SQL Editor へ適用する運用ルールに従う
- クライアントには publishable key のみを埋め込む（`--dart-define` 経由）。secret key は絶対にコミットしない
