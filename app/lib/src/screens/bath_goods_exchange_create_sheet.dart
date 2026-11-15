import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/app_state.dart';
import '../services/icon_service.dart';

/// ゆずりあい・交換の登録シート（FR-7-1相当）。
/// kind: 'give'（ゆずります）/ 'wanted'（探しています）/ 'trade'（交換します）
Future<void> showBathGoodsExchangeCreateSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _CreateSheet(),
  );
}

class _CreateSheet extends StatefulWidget {
  const _CreateSheet();

  @override
  State<_CreateSheet> createState() => _CreateSheetState();
}

class _CreateSheetState extends State<_CreateSheet> {
  final _itemDescription = TextEditingController();
  final _areaName = TextEditingController();
  final _detail = TextEditingController();
  String _kind = 'give';
  String? _photoPath; // 選択した投稿写真（null=未選択, ''=解除）
  bool _submitting = false;

  @override
  void dispose() {
    _itemDescription.dispose();
    _areaName.dispose();
    _detail.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final path = await iconService.pickExchangeItemPhoto(source);
    if (path != null) {
      setState(() => _photoPath = path);
    }
  }

  Future<void> _submit() async {
    if (!_isValid || _submitting) return;
    setState(() => _submitting = true);
    try {
      await appState.registerBathGoodsExchange(
        kind: _kind,
        itemDescription: _itemDescription.text.trim(),
        areaName: _areaName.text.trim(),
        detail: _detail.text.trim(),
        photoPath:
            (_photoPath == null || _photoPath!.isEmpty) ? null : _photoPath,
      );
    } catch (_) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('登録に失敗しました。通信状況を確認してください'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('登録しました。近くのユーザーに表示されます'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ゆずりあい・交換を登録する',
                style: theme.textTheme.titleLarge!
                    .copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'give',
                  icon: Icon(Icons.redeem),
                  label: Text('ゆずります'),
                ),
                ButtonSegment(
                  value: 'wanted',
                  icon: Icon(Icons.search),
                  label: Text('探してます'),
                ),
                ButtonSegment(
                  value: 'trade',
                  icon: Icon(Icons.swap_horiz),
                  label: Text('交換します'),
                ),
              ],
              selected: {_kind},
              onSelectionChanged: (s) => setState(() => _kind = s.first),
            ),
            const SizedBox(height: 4),
            Text(
              _kind == 'give'
                  ? '使わなくなったサウナグッズをゆずる場合の登録です。\n'
                      '※金銭のやりとりは禁止です。受け渡しは銭湯の入り口前や公共の場で行ってください。'
                  : _kind == 'wanted'
                      ? '探しているサウナグッズの登録です。\n'
                          '※個人の住所・連絡先は記入しないでください。DMでやりとりしましょう。'
                      : 'サウナグッズの交換の登録です。\n'
                          '※金銭のやりとりは禁止です。同価値での交換を前提とし、条件はDMで相談してください。',
              style: theme.textTheme.labelSmall!
                  .copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _itemDescription,
              maxLength: 40,
              decoration: const InputDecoration(
                labelText: 'グッズの内容',
                hintText: '例: サウナハット（手編み・中古）',
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),
            const SizedBox(height: 12),

            // ------------------------------ 投稿写真（任意）
            Text('写真（任意。状態が伝わる写真を）',
                style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                _photoPreview(theme),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _pickPhoto(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_outlined,
                            size: 18),
                        label: const Text('ギャラリーから',
                            style: TextStyle(fontSize: 13)),
                      ),
                      const SizedBox(height: 4),
                      OutlinedButton.icon(
                        onPressed: () => _pickPhoto(ImageSource.camera),
                        icon:
                            const Icon(Icons.photo_camera_outlined, size: 18),
                        label: const Text('カメラで撮影',
                            style: TextStyle(fontSize: 13)),
                      ),
                      if (_photoPath != null && _photoPath!.isNotEmpty)
                        TextButton(
                          onPressed: () => setState(() => _photoPath = ''),
                          child: const Text('写真をはずす',
                              style: TextStyle(fontSize: 12)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _areaName,
              maxLength: 30,
              decoration: InputDecoration(
                labelText: _kind == 'wanted' ? '探している地域・イベント名' : '受け渡し希望の地域・イベント名',
                hintText: '例: ○○市周辺 / ○○銭湯の入り口前',
                border: const OutlineInputBorder(),
                counterText: '',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _detail,
              maxLines: 3,
              maxLength: 200,
              decoration: const InputDecoration(
                labelText: '状態・条件・受け渡し方法など',
                hintText: '例: 洗浄済み・2回使用。○○銭湯の入り口前で受け渡しできます',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: (_isValid && !_submitting) ? _submit : null,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text('登録する'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _isValid =>
      _itemDescription.text.trim().isNotEmpty &&
      _areaName.text.trim().isNotEmpty;

  Widget _photoPreview(ThemeData theme) {
    final path = (_photoPath ?? '');
    Widget preview;
    if (path.startsWith('http')) {
      preview = Image.network(path, width: 96, height: 96,
          fit: BoxFit.cover, errorBuilder: (_, _, _) => _emptyPreview());
    } else if (path.isNotEmpty && File(path).existsSync()) {
      preview =
          Image.file(File(path), width: 96, height: 96, fit: BoxFit.cover);
    } else {
      preview = _emptyPreview();
    }
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: preview,
      ),
    );
  }

  Widget _emptyPreview() {
    return Container(
      color: Colors.grey.shade100,
      child: const Center(
        child: Icon(Icons.image_outlined, size: 32, color: Colors.grey),
      ),
    );
  }
}
