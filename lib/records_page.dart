import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'mock_api.dart';

class RecordsPage extends StatefulWidget {
  final String sessionId;

  const RecordsPage({super.key, required this.sessionId});

  @override
  State<RecordsPage> createState() => _RecordsPageState();
}

class _RecordsPageState extends State<RecordsPage> {
  List<DelegateRecord> _all = [];
  bool _loading = true;

  final _searchCtrl = TextEditingController();
  String _actionFilter = 'All'; // All | attendance | vote

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await MockApi.listRecords(widget.sessionId);
    // 依時間新到舊
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    setState(() {
      _all = list;
      _loading = false;
    });
  }

  Future<void> _clear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('清空紀錄'),
        content: const Text('確定要清空本 session 的所有紀錄嗎？此動作無法復原。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('清空'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await MockApi.clear(widget.sessionId);
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('已清空紀錄')));
    }
  }

  void _copyJson() {
    final jsonList = _filtered().map((e) => e.toJson()).toList();
    final text = jsonList.toString();
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('已複製 JSON 到剪貼簿')));
  }

  List<DelegateRecord> _filtered() {
    final q = _searchCtrl.text.trim().toLowerCase();
    return _all.where((r) {
      final passAction = _actionFilter == 'All' || r.action == _actionFilter;
      if (!passAction) return false;
      if (q.isEmpty) return true;
      final hay = [
        r.actorAccount,
        r.actorDelegateName,
        r.targetDelegateName,
        r.value,
        r.action,
        r.timestamp.toIso8601String(),
      ].join(' ').toLowerCase();
      return hay.contains(q);
    }).toList();
  }

  Color _badgeColor(String action) {
    switch (action) {
      case 'attendance':
        return Colors.blueGrey.shade100;
      case 'vote':
        return Colors.indigo.shade100;
      default:
        return Colors.grey.shade200;
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered();

    return Scaffold(
      appBar: AppBar(
        title: const Text('代表紀錄（Mock 後端）'),
        actions: [
          IconButton(
            tooltip: '重新整理',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: '複製目前列表為 JSON',
            onPressed: _loading ? null : _copyJson,
            icon: const Icon(Icons.copy_all),
          ),
          IconButton(
            tooltip: '清空本 session 紀錄',
            onPressed: _loading ? null : _clear,
            icon: const Icon(Icons.delete_outline),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // 篩選列
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Row(
              children: [
                // 動作過濾
                SizedBox(
                  width: 160,
                  child: DropdownButtonFormField<String>(
                    value: _actionFilter,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'All', child: Text('全部動作')),
                      DropdownMenuItem(
                        value: 'attendance',
                        child: Text('出席狀態'),
                      ),
                      DropdownMenuItem(value: 'vote', child: Text('投票')),
                    ],
                    onChanged: (v) =>
                        setState(() => _actionFilter = v ?? 'All'),
                  ),
                ),
                const SizedBox(width: 12),
                // 搜尋
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: '搜尋（帳號 / 代表 / 值 / 時間）',
                      prefixIcon: const Icon(Icons.search),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // 計數
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _loading ? '載入中…' : '共 ${list.length} 筆（全部：${_all.length}）',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // 列表
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : list.isEmpty
                ? const Center(child: Text('目前沒有符合條件的紀錄'))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final r = list[i];
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.fromLTRB(
                            12,
                            10,
                            12,
                            10,
                          ),
                          title: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _badgeColor(r.action),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(r.action),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  r.value,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '操作者：${r.actorAccount}（${r.actorDelegateName}）',
                                  style: const TextStyle(fontSize: 13),
                                ),
                                Text(
                                  '對象：${r.targetDelegateName}',
                                  style: const TextStyle(fontSize: 13),
                                ),
                                Text(
                                  '時間：${r.timestamp.toLocal()}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
