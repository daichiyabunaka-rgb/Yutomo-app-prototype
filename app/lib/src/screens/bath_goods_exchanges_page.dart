import 'dart:io';

import 'package:flutter/material.dart';

import '../models.dart';
import '../services/app_state.dart';
import '../util/format.dart';
import 'chat_screen.dart';
import 'bath_goods_exchange_create_sheet.dart';
import 'user_detail_screen.dart';
import 'widgets.dart';

/// 「ゆずりあい・交換」タブ: サウナグッズのゆずり合い・交換の情報を近隣で
/// 共有する（FR-7-1〜7-4 相当）。
/// 金銭取引は本アプリでは行わない（銭湯の入り口前・公共の場での受け渡し前提）。
class BathGoodsExchangesPage extends StatefulWidget {
  const BathGoodsExchangesPage({super.key});

  @override
  State<BathGoodsExchangesPage> createState() => _BathGoodsExchangesPageState();
}

class _BathGoodsExchangesPageState extends State<BathGoodsExchangesPage> {
  String _filter = 'all'; // 'all' | 'give' | 'wanted' | 'trade'

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showBathGoodsExchangeCreateSheet(context),
        icon: const Icon(Icons.swap_horiz),
        label: const Text('登録する'),
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: appState,
          builder: (context, _) {
            final all = appState.partsExchanges;
            final items = _filter == 'all'
                ? all
                : all.where((p) => p.kind == _filter).toList();
            return RefreshIndicator(
              onRefresh: () => appState.refreshFromRemote(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'ゆずりあい・交換',
                    style: theme.textTheme.titleLarge!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'all', label: Text('すべて')),
                      ButtonSegment(value: 'give', label: Text('ゆずります')),
                      ButtonSegment(value: 'wanted', label: Text('探してます')),
                      ButtonSegment(value: 'trade', label: Text('交換')),
                    ],
                    selected: {_filter},
                    onSelectionChanged: (s) =>
                        setState(() => _filter = s.first),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '近くで登録された情報を近い順に表示します。使わなくなったサウナハットや'
                    'バス用品のゆずり合い・交換の募集をして、同じ趣味の仲間と'
                    'つながりましょう。',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '※金銭のやりとりは禁止です（フリマアプリを利用してください）。'
                    '受け渡しはイベント会場や公共の場で行い、'
                    '初めて会う場合は人目のある場所を選んでください。',
                    style: theme.textTheme.labelSmall!.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  if (items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          '近くに登録はまだありません。\n'
                          '「登録する」から最初の登録をお願いします。',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ),
                  for (final d in items) _exchangeCard(context, d),
                  const SizedBox(height: 80),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _exchangeCard(BuildContext context, BathGoodsExchange d) {
    final theme = Theme.of(context);
    final poster = appState.userById(d.posterId);
    final isMine = d.posterId == appState.me!.id;
    final now = DateTime.now();
    final giveColor = Colors.teal.shade700;
    final wantedColor = Colors.red.shade700;
    final tradeColor = Colors.indigo.shade700;
    final color =
        d.isGive ? giveColor : (d.isWanted ? wantedColor : tradeColor);
    final bg = d.isGive
        ? Colors.teal.shade50
        : (d.isWanted ? Colors.red.shade50 : Colors.indigo.shade50);
    final border = d.isGive
        ? Colors.teal.shade200
        : (d.isWanted ? Colors.red.shade200 : Colors.indigo.shade200);
    final label = d.isGive
        ? 'ゆずります'
        : (d.isWanted ? '探してます' : '交換');
    return Card(
      margin: const EdgeInsets.only(top: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: border),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(fontSize: 12, color: color),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    d.itemDescription,
                    style: theme.textTheme.titleSmall!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.place, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    d.areaName,
                    style: TextStyle(color: Colors.grey.shade700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.schedule, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 2),
                Text(
                  '${elapsedLabel(d.createdAt, now)}の登録 / '
                  '${appState.partsExchangeDistanceLabel(d)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_hasPhoto(d))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: GestureDetector(
                    onTap: () => _showPhoto(context, d),
                    child: _photoImage(d, 320),
                  ),
                ),
              ),
            if (d.detail.isNotEmpty)
              Text(d.detail, style: theme.textTheme.bodySmall),
            const SizedBox(height: 10),
            Row(
              children: [
                InkWell(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => UserDetailScreen(userId: poster.id),
                    ),
                  ),
                  borderRadius: BorderRadius.circular(12),
                  child: Row(
                    children: [
                      userAvatar(poster.id, size: 32),
                      const SizedBox(width: 8),
                      Text(
                        poster.nickname,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (isMine)
                  TextButton.icon(
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('完了にする'),
                    onPressed: () => _confirmClose(context, d),
                  )
                else
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                    label: const Text('この人にDM', style: TextStyle(fontSize: 13)),
                    onPressed: () async {
                      final room = await appState.getOrCreateDm(poster.id);
                      if (!context.mounted) return;
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ChatScreen(roomId: room.id),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _hasPhoto(BathGoodsExchange d) {
    final p = d.photoPath ?? '';
    if (p.isEmpty) return false;
    if (p.startsWith('http')) return true;
    return File(p).existsSync();
  }

  Widget _photoImage(BathGoodsExchange d, double height) {
    final p = d.photoPath!;
    final Widget image;
    if (p.startsWith('http')) {
      image = Image.network(p,
          height: height,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const SizedBox.shrink());
    } else {
      image = Image.file(File(p),
          height: height,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const SizedBox.shrink());
    }
    return image;
  }

  /// 写真を全画面で見る
  void _showPhoto(BuildContext context, BathGoodsExchange d) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: GestureDetector(
          onTap: () => Navigator.of(dialogContext).pop(),
          child: _photoImage(d, 480),
        ),
      ),
    );
  }

  Future<void> _confirmClose(BuildContext context, BathGoodsExchange d) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('完了にしますか？'),
        content: const Text(
          '受け渡し・交換が成立した場合に設定します。'
          '完了にした登録は一覧から表示されなくなります。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('完了にする'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await appState.closeBathGoodsExchange(d.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('完了にしました。一覧から削除されます'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
