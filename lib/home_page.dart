import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login_page.dart';
// ✅ 避免潛在衝突（就算你不小心重複定義也可擋掉）
import 'drawer/roll_call_page.dart' hide VotingPage;
import 'drawer/voting_page.dart' show VotingPage;

import 'drawer/meeting_page.dart';
import 'drawer/about_page.dart';
import 'drawer/settings_page.dart';
import 'records_page.dart';
import 'drawer/status_overview_page.dart';

class HomePage extends StatefulWidget {
  final String username;
  final String selfDelegateName;
  final List<String> delegates;
  final String listName;
  final String listId;
  final String sessionId;
  final bool isAdmin;

  const HomePage({
    super.key,
    required this.username,
    required this.selfDelegateName,
    required this.delegates,
    required this.listName,
    required this.listId,
    required this.sessionId,
    required this.isAdmin,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedIndex = 0;

  // ✅ 一律用 listId 當 sessionId（確保同一名單共用資料）
  late final String _sessionId = widget.listId;

  @override
  void initState() {
    super.initState();
    _migrateOldKeysIfNeeded();
  }

  Future<void> _migrateOldKeysIfNeeded() async {
    if (widget.sessionId == _sessionId) return;

    final prefs = await SharedPreferences.getInstance();
    final oldAttendKey = 'attendance_data_${widget.sessionId}';
    final oldVoteKey = 'votes_data_${widget.sessionId}';
    final oldLogKey = 'server_records_${widget.sessionId}';

    final newAttendKey = 'attendance_data_$_sessionId';
    final newVoteKey = 'votes_data_$_sessionId';
    final newLogKey = 'server_records_$_sessionId';

    if (!prefs.containsKey(newAttendKey) && prefs.containsKey(oldAttendKey)) {
      final v = prefs.getString(oldAttendKey);
      if (v != null) await prefs.setString(newAttendKey, v);
    }
    if (!prefs.containsKey(newVoteKey) && prefs.containsKey(oldVoteKey)) {
      final v = prefs.getString(oldVoteKey);
      if (v != null) await prefs.setString(newVoteKey, v);
    }
    if (!prefs.containsKey(newLogKey) && prefs.containsKey(oldLogKey)) {
      final v = prefs.getString(oldLogKey);
      if (v != null) await prefs.setString(newLogKey, v);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      RollCallPage(
        username: widget.username,
        selfDelegateName: widget.selfDelegateName,
        delegateList: widget.delegates,
        listName: widget.listName,
        sessionId: _sessionId,
        isAdmin: widget.isAdmin,
      ),
      MeetingPage(
        username: widget.username,
        delegates: widget.delegates,
        isAdmin: widget.isAdmin,
      ),
      VotingPage(
        username: widget.username,
        selfDelegateName: widget.selfDelegateName,
        delegateList: widget.delegates,
        listName: widget.listName, // ← 別漏
        sessionId: _sessionId,
        isAdmin: widget.isAdmin,
      ),
      StatusOverviewPage(
        delegateList: widget.delegates,
        listName: widget.listName, // ← 別漏
        sessionId: _sessionId,
      ),
      const SettingsPage(),
      const AboutPage(),
      RecordsPage(sessionId: _sessionId),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'MUN - ${widget.listName}（${widget.username}） / $_sessionId',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            tooltip: '通知',
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.message),
            tooltip: '訊息',
            onPressed: () {},
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              DrawerHeader(
                margin: EdgeInsets.zero,
                padding: EdgeInsets.zero,
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "MUN Navigation",
                          style: TextStyle(
                            fontSize: 35,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Image.asset('assets/images/logo.png', height: 140),
                        const SizedBox(height: 8),
                        Text(
                          '版本: beta 1.0.0',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  children: [
                    _drawerItem('點名', 0),
                    _drawerItem('會議', 1),
                    _drawerItem('投票', 2),
                    _drawerItem('狀態總覽', 3),
                    _drawerItem('設定', 4),
                    _drawerItem('關於', 5),
                    _drawerItem('紀錄', 6),
                  ],
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('登出', style: TextStyle(fontSize: 16)),
                onTap: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: pages[selectedIndex],
    );
  }

  Widget _drawerItem(String title, int index) {
    return ListTile(
      title: Text(title),
      onTap: () {
        setState(() => selectedIndex = index);
        Navigator.pop(context);
      },
    );
  }
}
