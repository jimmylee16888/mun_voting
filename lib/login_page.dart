import 'package:flutter/material.dart';
import 'home_page.dart';
import 'delegate_list_editor.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// 一份可用的預設 JSON（含兩個名單）
const String sampleJson = '''
{
  "list": [
    {
      "list_name": "UN General Assembly (English)",
      "admin_account": [
        { "account": "admin", "password": "admin" }
      ],
      "delegates": [
        { "delegate_name": "China", "account": "china_2025", "password": "china_2025" },
        { "delegate_name": "France", "account": "france_2025", "password": "france_2025" },
        { "delegate_name": "Russia", "account": "russia_2025", "password": "russia_2025" },
        { "delegate_name": "United Kingdom", "account": "uk_2025", "password": "uk_2025" },
        { "delegate_name": "United States", "account": "usa_2025", "password": "usa_2025" },
        { "delegate_name": "Japan", "account": "japan_2025", "password": "japan_2025" },
        { "delegate_name": "Germany", "account": "germany_2025", "password": "germany_2025" },
        { "delegate_name": "Italy", "account": "italy_2025", "password": "italy_2025" },
        { "delegate_name": "Brazil", "account": "brazil_2025", "password": "brazil_2025" },
        { "delegate_name": "India", "account": "india_2025", "password": "india_2025" },
        { "delegate_name": "Canada", "account": "canada_2025", "password": "canada_2025" },
        { "delegate_name": "Australia", "account": "australia_2025", "password": "australia_2025" },
        { "delegate_name": "South Korea", "account": "korea_2025", "password": "korea_2025" },
        { "delegate_name": "Spain", "account": "spain_2025", "password": "spain_2025" },
        { "delegate_name": "Mexico", "account": "mexico_2025", "password": "mexico_2025" },
        { "delegate_name": "Indonesia", "account": "indonesia_2025", "password": "indonesia_2025" },
        { "delegate_name": "Saudi Arabia", "account": "saudi_2025", "password": "saudi_2025" },
        { "delegate_name": "South Africa", "account": "southafrica_2025", "password": "southafrica_2025" },
        { "delegate_name": "Argentina", "account": "argentina_2025", "password": "argentina_2025" },
        { "delegate_name": "Egypt", "account": "egypt_2025", "password": "egypt_2025" },
        { "delegate_name": "Turkey", "account": "turkey_2025", "password": "turkey_2025" },
        { "delegate_name": "Netherlands", "account": "netherlands_2025", "password": "netherlands_2025" },
        { "delegate_name": "Sweden", "account": "sweden_2025", "password": "sweden_2025" },
        { "delegate_name": "Norway", "account": "norway_2025", "password": "norway_2025" },
        { "delegate_name": "Switzerland", "account": "switzerland_2025", "password": "switzerland_2025" },
        { "delegate_name": "Thailand", "account": "thailand_2025", "password": "thailand_2025" },
        { "delegate_name": "Vietnam", "account": "vietnam_2025", "password": "vietnam_2025" },
        { "delegate_name": "Philippines", "account": "philippines_2025", "password": "philippines_2025" },
        { "delegate_name": "Malaysia", "account": "malaysia_2025", "password": "malaysia_2025" }
      ]
    },
    {
      "list_name": "聯合國大會（中文）",
      "admin_account": [
        { "account": "admin2", "password": "admin2" }
      ],
      "delegates": [
        { "delegate_name": "中國", "account": "china_2025", "password": "china_2025" },
        { "delegate_name": "法國", "account": "france_2025", "password": "france_2025" },
        { "delegate_name": "俄羅斯", "account": "russia_2025", "password": "russia_2025" },
        { "delegate_name": "英國", "account": "uk_2025", "password": "uk_2025" },
        { "delegate_name": "美國", "account": "usa_2025", "password": "usa_2025" },
        { "delegate_name": "日本", "account": "japan_2025", "password": "japan_2025" },
        { "delegate_name": "德國", "account": "germany_2025", "password": "germany_2025" },
        { "delegate_name": "義大利", "account": "italy_2025", "password": "italy_2025" },
        { "delegate_name": "巴西", "account": "brazil_2025", "password": "brazil_2025" },
        { "delegate_name": "印度", "account": "india_2025", "password": "india_2025" },
        { "delegate_name": "加拿大", "account": "canada_2025", "password": "canada_2025" },
        { "delegate_name": "澳洲", "account": "australia_2025", "password": "australia_2025" },
        { "delegate_name": "南韓", "account": "korea_2025", "password": "korea_2025" },
        { "delegate_name": "西班牙", "account": "spain_2025", "password": "spain_2025" },
        { "delegate_name": "墨西哥", "account": "mexico_2025", "password": "mexico_2025" },
        { "delegate_name": "印尼", "account": "indonesia_2025", "password": "indonesia_2025" },
        { "delegate_name": "沙烏地阿拉伯", "account": "saudi_2025", "password": "saudi_2025" },
        { "delegate_name": "南非", "account": "southafrica_2025", "password": "southafrica_2025" },
        { "delegate_name": "阿根廷", "account": "argentina_2025", "password": "argentina_2025" },
        { "delegate_name": "埃及", "account": "egypt_2025", "password": "egypt_2025" },
        { "delegate_name": "土耳其", "account": "turkey_2025", "password": "turkey_2025" },
        { "delegate_name": "荷蘭", "account": "netherlands_2025", "password": "netherlands_2025" },
        { "delegate_name": "瑞典", "account": "sweden_2025", "password": "sweden_2025" },
        { "delegate_name": "挪威", "account": "norway_2025", "password": "norway_2025" },
        { "delegate_name": "瑞士", "account": "switzerland_2025", "password": "switzerland_2025" },
        { "delegate_name": "泰國", "account": "thailand_2025", "password": "thailand_2025" },
        { "delegate_name": "越南", "account": "vietnam_2025", "password": "vietnam_2025" },
        { "delegate_name": "菲律賓", "account": "philippines_2025", "password": "philippines_2025" },
        { "delegate_name": "馬來西亞", "account": "malaysia_2025", "password": "malaysia_2025" }
      ]
    }
  ]
}
''';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  String? errorText;
  int selectedListIndex = 0;

  // 這些資料全都跟著「目前選到的 list」重建，避免跨 list 汙染
  List<Map<String, dynamic>> lists = [];
  List<String> currentDelegates = [];
  Map<String, String> currentUsers = {}; // account -> password（含 admin）
  Map<String, String> accountToDelegate = {}; // account -> delegate_name

  @override
  void initState() {
    super.initState();
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    // 首次啟動寫入預設
    if (!prefs.containsKey('delegate_json')) {
      await prefs.setString('delegate_json', sampleJson);
    }

    final jsonStr = prefs.getString('delegate_json')!;
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;
    final loaded = (data['list'] as List)
        .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
        .toList();

    final savedIndex = prefs.getInt('selected_list_index') ?? 0;

    setState(() {
      lists = loaded;
      selectedListIndex = (savedIndex >= 0 && savedIndex < lists.length)
          ? savedIndex
          : 0;
    });

    _rebuildListScopedData(); // 依目前索引重建登入資料
  }

  void _rebuildListScopedData() {
    if (lists.isEmpty) {
      currentDelegates = [];
      currentUsers = {};
      accountToDelegate = {};
      return;
    }

    final list = lists[selectedListIndex];

    final delegates = (list['delegates'] as List).cast<Map<String, dynamic>>();
    currentDelegates = delegates
        .map((d) => (d['delegate_name'] ?? '') as String)
        .toList();

    currentUsers = {
      for (var d in delegates)
        (d['account'] ?? '') as String: (d['password'] ?? '') as String,
    };

    accountToDelegate = {
      for (var d in delegates)
        (d['account'] ?? '') as String: (d['delegate_name'] ?? '') as String,
    };

    final admins = (list['admin_account'] as List).cast<Map<String, dynamic>>();
    for (var a in admins) {
      currentUsers[(a['account'] ?? '') as String] =
          (a['password'] ?? '') as String;
    }
  }

  Future<void> _saveSelectedIndex() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selected_list_index', selectedListIndex);
  }

  String _listIdFor(int index) {
    // 你可以改成更穩定的 slug 或 UUID；先用 index 即可
    return 'list_$index';
  }

  void _login() {
    final account = usernameController.text.trim();
    final password = passwordController.text.trim();

    if (currentUsers[account] == password) {
      final list = lists[selectedListIndex];
      final admins = (list['admin_account'] as List)
          .cast<Map<String, dynamic>>();
      final isAdmin = admins.any((a) => a['account'] == account);

      _saveSelectedIndex();

      final listId = _listIdFor(selectedListIndex);
      final sessionId = '$listId|$account';

      // ★ 找出代表名稱，找不到就用帳號
      final selfDelegateName = accountToDelegate[account] ?? account;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomePage(
            username: account,
            selfDelegateName: selfDelegateName, // ★ 必傳
            delegates: currentDelegates,
            listName: list['list_name'] ?? '',
            listId: listId,
            sessionId: sessionId,
            isAdmin: isAdmin,
          ),
        ),
      );
    } else {
      setState(() => errorText = '登入失敗，請檢查帳號與密碼');
    }
  }

  Future<void> _resetToDefault() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('delegate_json');
    await prefs.setString('delegate_json', sampleJson);
    await prefs.setInt('selected_list_index', 0);
    await _loadFromPrefs();
    setState(() {
      errorText = null;
      usernameController.clear();
      passwordController.clear();
    });
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('✅ 已還原預設名單')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final listNames = lists
        .map<String>((l) => (l['list_name'] ?? 'Unnamed') as String)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('模擬聯合國登入'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DelegateListEditor()),
              ).then((_) => _loadFromPrefs()); // 返回後重載
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/images/logo.png', height: 100),
                const SizedBox(height: 20),
                DropdownButton<int>(
                  value: selectedListIndex,
                  onChanged: (int? newIndex) {
                    if (newIndex == null) return;
                    setState(() {
                      selectedListIndex = newIndex;
                      // 切換 list 時，重建 list-scoped 的登入資料
                      _rebuildListScopedData();
                      // 把使用者輸入也清掉，避免殘留
                      usernameController.clear();
                      passwordController.clear();
                      errorText = null;
                    });
                  },
                  items: List.generate(listNames.length, (index) {
                    return DropdownMenuItem<int>(
                      value: index,
                      child: Text(listNames[index]),
                    );
                  }),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(labelText: 'Username'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                ),
                if (errorText != null) ...[
                  const SizedBox(height: 10),
                  Text(errorText!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 20),
                ElevatedButton(onPressed: _login, child: const Text('登入')),
                TextButton(
                  onPressed: _resetToDefault,
                  child: const Text('還原預設名單'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
