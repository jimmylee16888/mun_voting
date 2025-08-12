import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../mock_api.dart';

class RollCallPage extends StatefulWidget {
  final String username; // 帳號（account）
  final String selfDelegateName; // 此帳號對應代表名稱
  final List<String> delegateList;
  final String listName; // ★ 用於組合 key
  final String sessionId; // 分隔不同 list 的會話 ID
  final bool isAdmin; // 是否為管理員

  const RollCallPage({
    super.key,
    required this.username,
    required this.selfDelegateName,
    required this.delegateList,
    required this.listName,
    required this.sessionId,
    required this.isAdmin,
  });

  @override
  State<RollCallPage> createState() => _RollCallPageState();
}

class _RollCallPageState extends State<RollCallPage> {
  // 內層 key ＝ "${listName}::${delegateName}"
  Map<String, String> attendance = {};
  final List<String> statuses = ['Present', 'Present and Voting', 'Absent'];

  String get _storeKey => 'attendance_data_${widget.sessionId}';
  String _k(String name) => '${widget.listName}::${name.trim()}';

  @override
  void initState() {
    super.initState();
    loadAttendance();
  }

  Future<void> saveAttendance() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storeKey, jsonEncode(attendance));
  }

  Future<void> loadAttendance() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_storeKey);
    if (jsonStr != null) {
      setState(() {
        attendance = Map<String, String>.from(jsonDecode(jsonStr));
      });
    }
  }

  Future<void> _postRecord({
    required String action,
    required String target,
    required String value,
  }) async {
    try {
      await MockApi.postRecord(
        DelegateRecord(
          sessionId: widget.sessionId,
          action: action,
          actorAccount: widget.username,
          actorDelegateName: widget.selfDelegateName,
          targetDelegateName: target,
          value: value,
          timestamp: DateTime.now(),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('寫入紀錄失敗：$e')));
    }
  }

  Future<void> setStatus(String delegateName, String status) async {
    setState(() {
      attendance[_k(delegateName)] = status;
    });
    await saveAttendance();
    await _postRecord(
      action: 'attendance',
      target: delegateName,
      value: status,
    );
  }

  Future<void> clearStatus(String delegateName) async {
    setState(() {
      attendance.remove(_k(delegateName));
    });
    await saveAttendance();
    await _postRecord(
      action: 'attendance_clear',
      target: delegateName,
      value: '',
    );
  }

  int getPresentCount() {
    return widget.delegateList.where((d) {
      final s = attendance[_k(d)];
      return s == 'Present' || s == 'Present and Voting';
    }).length;
  }

  int getAbsentCount() {
    return widget.delegateList.where((d) {
      final s = attendance[_k(d)];
      return s == null || s == 'Absent';
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final present = getPresentCount();
    final absent = getAbsentCount();
    final simpleMajority = (present / 2).ceil();
    final twoThirds = (present * 2 / 3).ceil();
    final oneEighth = (present / 8).ceil();

    final selfDelegate = widget.selfDelegateName;

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          children: [
            Text("您的代表名稱：$selfDelegate", style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 20),

            // 自己的三鍵選擇
            Builder(
              builder: (_) {
                final current = attendance[_k(selfDelegate)];
                final selectedSet =
                    (current != null && statuses.contains(current))
                    ? {current}
                    : <String>{};

                return Row(
                  children: statuses.map((status) {
                    final isSelected = selectedSet.contains(status);

                    Color bgColor = Colors.white;
                    Color textColor = Colors.black87;
                    if (isSelected) {
                      switch (status) {
                        case 'Present':
                          bgColor = Colors.lightGreen.shade400;
                          textColor = Colors.white;
                          break;
                        case 'Present and Voting':
                          bgColor = Colors.green.shade400;
                          textColor = Colors.white;
                          break;
                        case 'Absent':
                          bgColor = Colors.red.shade400;
                          textColor = Colors.white;
                          break;
                      }
                    }

                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: InkWell(
                          onTap: () async {
                            if (isSelected) {
                              await clearStatus(selfDelegate);
                            } else {
                              await setStatus(selfDelegate, status);
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            height: 46,
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.transparent
                                    : Colors.grey.shade300,
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              status,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 30),
            const Text("目前各國出席狀況", style: TextStyle(fontSize: 18)),
            const SizedBox(height: 10),

            // 列表 + 管理員可調整
            ...widget.delegateList.map((delegate) {
              final status = attendance[_k(delegate)] ?? '尚未選擇';
              final color = _statusColor(status);

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  title: Text(delegate),
                  trailing: widget.isAdmin
                      ? DropdownButton<String>(
                          value: statuses.contains(attendance[_k(delegate)])
                              ? attendance[_k(delegate)]
                              : null,
                          hint: const Text('尚未選擇'),
                          items: statuses
                              .map(
                                (s) =>
                                    DropdownMenuItem(value: s, child: Text(s)),
                              )
                              .toList(),
                          onChanged: (newStatus) async {
                            if (newStatus != null) {
                              await setStatus(delegate, newStatus);
                            }
                          },
                        )
                      : Text(status),
                ),
              );
            }),
            const SizedBox(height: 80),
          ],
        ),

        // 統計列
        Positioned(
          bottom: 10,
          left: 10,
          right: 10,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Text("🟢 出席：", style: TextStyle(fontSize: 16)),
                          Text(
                            "$present",
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          const Text("🔴 缺席：", style: TextStyle(fontSize: 16)),
                          Text("$absent", style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _thresholdChip(
                      "1/2",
                      (present / 2).ceil(),
                      Colors.blueGrey.shade100,
                    ),
                    _thresholdChip(
                      "2/3",
                      (present * 2 / 3).ceil(),
                      Colors.blue.shade100,
                    ),
                    _thresholdChip(
                      "1/8",
                      (present / 8).ceil(),
                      Colors.indigo.shade100,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _statusColor(String status) {
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

  Widget _thresholdChip(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        "$label：$value",
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }
}
