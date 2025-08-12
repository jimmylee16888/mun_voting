import 'package:flutter/material.dart';
import 'login_page.dart';
import 'drawer/roll_call_page.dart';
import 'drawer/meeting_page.dart';
import 'drawer/voting_page.dart';
import 'drawer/about_page.dart';
import 'drawer/settings_page.dart';
import 'records_page.dart'; // 📋 紀錄檢視頁

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

  @override
  Widget build(BuildContext context) {
    final pages = [
      RollCallPage(
        username: widget.username,
        selfDelegateName: widget.selfDelegateName,
        delegateList: widget.delegates,
        listName: widget.listName,
        sessionId: widget.sessionId,
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
        sessionId: widget.sessionId,
        isAdmin: widget.isAdmin,
      ),
      const SettingsPage(),
      const AboutPage(),
      RecordsPage(sessionId: widget.sessionId), // 📋 紀錄頁
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('MUN - ${widget.listName}（${widget.username}）'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            tooltip: '通知',
            onPressed: () {
              // TODO: 通知功能
            },
          ),
          IconButton(
            icon: const Icon(Icons.message),
            tooltip: '訊息',
            onPressed: () {
              // TODO: 訊息功能
            },
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
                          ' ${widget.listName}',
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
                    _drawerItem('設定', 3),
                    _drawerItem('關於', 4),
                    _drawerItem('紀錄', 5), // 📋 新增紀錄
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
