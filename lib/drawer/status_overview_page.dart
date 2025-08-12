import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StatusOverviewPage extends StatefulWidget {
  final List<String> delegateList;
  final String listName; // ★ 新增
  final String sessionId;

  const StatusOverviewPage({
    super.key,
    required this.delegateList,
    required this.listName, // ★ 新增
    required this.sessionId,
  });

  @override
  State<StatusOverviewPage> createState() => _StatusOverviewPageState();
}

class _StatusOverviewPageState extends State<StatusOverviewPage> {
  Map<String, String> _attendance = {}; // key = "${listName}::${delegateName}"
  Map<String, String> _votes = {}; // key = "${listName}::${delegateName}"
  bool _loading = true;

  String get _attendanceKey => 'attendance_data_${widget.sessionId}';
  String get _voteKey => 'votes_data_${widget.sessionId}';
  String _k(String name) => '${widget.listName}::${name.trim()}';

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();

    final aRaw = prefs.getString(_attendanceKey);
    _attendance = aRaw != null
        ? Map<String, String>.from(jsonDecode(aRaw))
        : <String, String>{};

    final vRaw = prefs.getString(_voteKey);
    _votes = vRaw != null
        ? Map<String, String>.from(jsonDecode(vRaw))
        : <String, String>{};

    setState(() => _loading = false);
  }

  Color _attendanceColor(String? status) {
    switch (status) {
      case 'Present':
        return Colors.lightGreen.shade100;
      case 'Present and Voting':
        return Colors.green.shade100;
      case 'Absent':
        return Colors.red.shade100;
      default:
        return Colors.grey.shade200;
    }
  }

  Color _voteColor(String? vote) {
    switch (vote) {
      case 'Yes':
        return Colors.green.shade50;
      case 'No':
        return Colors.red.shade50;
      case 'Abstain':
        return Colors.amber.shade50;
      default:
        return Colors.grey.shade200;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('狀態總覽'),
        actions: [
          IconButton(
            tooltip: '重新整理',
            icon: const Icon(Icons.refresh),
            onPressed: _loadAll,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAll,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                itemCount: widget.delegateList.length,
                itemBuilder: (_, i) {
                  final name = widget.delegateList[i];
                  final a = _attendance[_k(name)];
                  final v = _votes[_k(name)];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black.withOpacity(0.06)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _attendanceColor(a),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '出席: ${a ?? "尚未選擇"}',
                              style: const TextStyle(fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _voteColor(v),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '投票: ${v ?? "尚未投票"}',
                              style: const TextStyle(fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}
