import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models.dart';
import '../services/app_state.dart';
import '../util/cat_spots.dart';
import '../util/format.dart';
import 'recruitment_create_sheet.dart';

/// 「近くの施設」タブ（湯とも！の特別機能）。
/// 現在地の近くの立ち寄り施設（銭湯・日帰り温泉・スパ・サウナ施設）を近い順に表示する。
/// 各施設はGoogleマップで開けるほか、その場所で直接募集
/// （湯めぐり・イベント・オフ会）をかけることができる。
class SpotPage extends StatefulWidget {
  const SpotPage({super.key});

  @override
  State<SpotPage> createState() => _SpotPageState();
}

class _SpotPageState extends State<SpotPage> {
  String? _anchorKey;
  late Future<List<CatSpot>> _future;
  int _shownCount = spotBatchSize; // 50件ずつ表示（スクロールで増やす）

  void _reloadIfNeeded() {
    final key =
        '${appState.anchorLat.toStringAsFixed(5)},${appState.anchorLng.toStringAsFixed(5)}';
    if (key == _anchorKey) return;
    _anchorKey = key;
    _future = fetchCatSpotsNear(appState.anchorLat, appState.anchorLng);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        _reloadIfNeeded();
        return RefreshIndicator(
          onRefresh: () async {
            final f = fetchCatSpotsNear(appState.anchorLat, appState.anchorLng,
                forceRefresh: true);
            setState(() {
              _anchorKey =
                  '${appState.anchorLat.toStringAsFixed(5)},${appState.anchorLng.toStringAsFixed(5)}';
              _future = f;
              _shownCount = spotBatchSize;
            });
            await f;
          },
          child: FutureBuilder<List<CatSpot>>(
            key: ValueKey(_anchorKey),
            future: _future,
            builder: (context, snapshot) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  const SizedBox(height: 4),
                  Text(
                    '現在地の近くの銭湯・日帰り温泉・スパ・サウナ施設を近い順に表示します。\n マナーと入浴ルールを守って、ととのいましょう。',
                    style: theme.textTheme.bodySmall,
                  ),
                  if (snapshot.connectionState != ConnectionState.done &&
                      !snapshot.hasError)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 12),
                          Text(
                            '周辺の立ち寄りスポットを検索しています…\n'
                            '初回は30秒〜1分ほどかかることがあります',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  if (snapshot.hasError) _errorCard(theme),
                  if (snapshot.hasData) ...[
                    if (snapshot.data!.isEmpty) _emptyCard(theme),
                    for (final s in snapshot.data!.take(_shownCount))
                      _spotCard(context, s),
                    // 50件ずつ表示（「さらに表示」で追加）
                    if (snapshot.data!.length > _shownCount)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: OutlinedButton(
                          onPressed: () => setState(
                              () => _shownCount += spotBatchSize),
                          child: Text(
                              'さらに表示（残り${snapshot.data!.length - _shownCount}件）'),
                        ),
                      ),
                  ],
                  const SizedBox(height: 24),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _openGoogleMaps(CatSpot spot) async {
    try {
      await launchUrl(Uri.parse(googleMapsUrlForSpot(spot)),
          mode: LaunchMode.externalApplication);
    } catch (_) {
      // Googleマップアプリが無い環境では無視
    }
  }

  Widget _errorCard(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        children: [
          Icon(Icons.cloud_off, size: 40, color: Colors.grey.shade500),
          const SizedBox(height: 8),
          Text('施設情報を取得できませんでした。通信状況をご確認ください。',
              style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('再読み込み'),
            onPressed: () => setState(() => _anchorKey = null),
          ),
        ],
      ),
    );
  }

  Widget _emptyCard(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        children: [
          Icon(Icons.hot_tub, size: 40, color: Colors.grey.shade500),
          const SizedBox(height: 8),
          Text('近くに立ち寄りスポットが見つかりませんでした。',
              style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _spotCard(BuildContext context, CatSpot s) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(top: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  spotIcon(s.type),
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.name,
                        style: theme.textTheme.titleMedium!
                            .copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${spotTypeLabel(s.type)} / ${distanceLabel(s.distanceKm)}',
                        style: theme.textTheme.bodySmall!.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (s.openingHours != null) ...[
              const SizedBox(height: 6),
              Text('時間: ${s.openingHours!}',
                  style: theme.textTheme.bodySmall),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    icon: const Icon(Icons.map_outlined, size: 18),
                    label:
                        const Text('Googleマップで開く', style: TextStyle(fontSize: 13)),
                    onPressed: () => _openGoogleMaps(s),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.campaign, size: 18),
                    label: const Text('このスポットで募集',
                        style: TextStyle(fontSize: 13)),
                    onPressed: () =>
                        showRecruitmentCreateSheet(context, initialMeetup: s.name),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// スポット種別の表示ラベル
String spotTypeLabel(String type) {
  switch (type) {
    case 'sento':
      return '銭湯・スーパー銭湯';
    case 'onsen':
      return '日帰り温泉';
    case 'spa':
      return 'スパ・健康ランド';
    case 'sauna':
      return 'サウナ施設';
  }
  return '施設';
}

/// スポット種別のアイコン
IconData spotIcon(String type) {
  switch (type) {
    case 'sento':
      return Icons.hot_tub;
    case 'onsen':
      return Icons.spa;
    case 'spa':
      return Icons.pool;
    case 'sauna':
      return Icons.local_fire_department;
  }
  return Icons.place;
}

