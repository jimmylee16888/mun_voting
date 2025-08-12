import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../mock_api.dart';

class VotingPage extends StatefulWidget {
  final String username; // 帳號（account）
  final String selfDelegateName; // 此帳號對應代表名稱
  final List<String> delegateList;
  final String sessionId; // 分隔不同 list 的會話 ID
  final bool isAdmin; // 是否為管理員

  const VotingPage({
    super.key,
    required this.username,
    required this.selfDelegateName,
    required this.delegateList,
    required this.sessionId,
    required this.isAdmin,
  });

  @override
  State<VotingPage> createState() => _VotingPageState();
}

class _VotingPageState extends State<VotingPage> {
  Map<String, String> votes = {};
  final List<String> options = ['Yes', 'No', 'Abstain'];

  String get _storeKey => 'votes_data_${widget.sessionId}';

  @override
  void initState() {
    super.initState();
    loadVotes();
  }

  Future<void> saveVotes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storeKey, jsonEncode(votes));
  }

  Future<void> loadVotes() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_storeKey);
    if (jsonStr != null) {
      setState(() {
        votes = Map<String, String>.from(jsonDecode(jsonStr));
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

  Future<void> castVote(String delegateName, String vote) async {
    setState(() {
      votes[delegateName] = vote;
    });
    await saveVotes();
    await _postRecord(action: 'vote', target: delegateName, value: vote);
  }

  Future<void> clearVote(String delegateName) async {
    setState(() {
      votes.remove(delegateName);
    });
    await saveVotes();
    await _postRecord(action: 'vote_clear', target: delegateName, value: '');
  }

  Map<String, int> getVoteCount() {
    final Map<String, int> count = {'Yes': 0, 'No': 0, 'Abstain': 0};
    for (var delegate in widget.delegateList) {
      final v = votes[delegate];
      if (v != null && count.containsKey(v)) {
        count[v] = count[v]! + 1;
      }
    }
    return count;
  }

  // 卡片底色
  Color voteTileColor(String? vote) {
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

  // 按鈕選中顏色
  Color selectedBtnColor(String vote) {
    switch (vote) {
      case 'Yes':
        return Colors.green.shade600;
      case 'No':
        return Colors.red.shade600;
      case 'Abstain':
        return Colors.amber.shade700;
      default:
        return Colors.blueGrey.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = getVoteCount();
    final selfDelegate = widget.selfDelegateName;

    return Scaffold(
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            children: [
              Text(
                "您的代表名稱：$selfDelegate",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              const Text("請進行投票：", style: TextStyle(fontSize: 16)),
              const SizedBox(height: 10),

              // 自己的投票三鍵
              Builder(
                builder: (_) {
                  final current = votes[selfDelegate];
                  return Row(
                    children: options.map((opt) {
                      final isSelected = current == opt;
                      final bg = isSelected
                          ? selectedBtnColor(opt)
                          : Colors.white;
                      final fg = isSelected ? Colors.white : Colors.black87;

                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: InkWell(
                            onTap: () async {
                              if (isSelected) {
                                await clearVote(selfDelegate); // 取消選擇 → 寫後端
                              } else {
                                await castVote(selfDelegate, opt);
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              height: 46,
                              decoration: BoxDecoration(
                                color: bg,
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
                                opt,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: fg,
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

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                "所有代表投票狀態",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),

              // 列表 + 管理員可調整
              ...widget.delegateList.map((delegate) {
                final vote = votes[delegate];
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  decoration: BoxDecoration(
                    color: voteTileColor(vote),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    title: Text(
                      delegate,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    trailing: widget.isAdmin
                        ? SizedBox(
                            width: 200,
                            child: DropdownButtonFormField<String>(
                              value: options.contains(vote) ? vote : null,
                              dropdownColor: voteTileColor(vote),
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                filled: true,
                                fillColor: voteTileColor(vote),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              hint: const Text('尚未投票'),
                              items: options
                                  .map(
                                    (opt) => DropdownMenuItem(
                                      value: opt,
                                      child: Text(opt),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (newVote) async {
                                if (newVote != null) {
                                  await castVote(
                                    delegate,
                                    newVote,
                                  ); // 管理員代操作 → 寫後端
                                }
                              },
                            ),
                          )
                        : Text(vote ?? '尚未投票'),
                  ),
                );
              }),
            ],
          ),

          // 底部統計條
          Positioned(
            left: 10,
            right: 10,
            bottom: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.88),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _statPill('🟢 Yes', result['Yes'] ?? 0),
                  _statPill('🔴 No', result['No'] ?? 0),
                  _statPill('🟡 Abstain', result['Abstain'] ?? 0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statPill(String label, int value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }
}
