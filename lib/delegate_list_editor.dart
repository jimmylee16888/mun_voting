import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'mock_api.dart';

class DelegateListEditor extends StatefulWidget {
  const DelegateListEditor({super.key});

  @override
  State<DelegateListEditor> createState() => _DelegateListEditorState();
}

class _DelegateListEditorState extends State<DelegateListEditor> {
  // 明確型別，避免 dynamic 帶來的型別錯誤
  List<Map<String, dynamic>> lists = [];
  int selectedListIndex = 0;

  // 只對 delegate_name 使用 controller，避免 ListView 回收導致文字閃動
  // 以 list 的 index 做 key；每個 list 對應一組 controllers
  final Map<int, List<TextEditingController>> _delegateNameCtrls = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    // 釋放所有 controllers
    for (final entry in _delegateNameCtrls.entries) {
      for (final c in entry.value) {
        c.dispose();
      }
    }
    _delegateNameCtrls.clear();
    super.dispose();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('delegate_json');

    if (jsonStr != null) {
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
    } else {
      // 寫入一份極簡預設
      final sampleData = {
        "list": [
          {
            "list_name": "🇨🇳 中文 GA 名單",
            "admin_account": [
              {"account": "admin", "password": "admin"},
            ],
            "delegates": List.generate(
              5,
              (i) => {
                "delegate_name": "國家 ${i + 1}",
                "account": "ga_user${i + 1}",
                "password": "ga_user${i + 1}",
              },
            ),
          },
        ],
      };
      await prefs.setString('delegate_json', jsonEncode(sampleData));
      setState(() {
        lists = (sampleData['list'] as List)
            .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
            .toList();
        selectedListIndex = 0;
      });
    }

    _rebuildAllNameControllers();
  }

  void _rebuildAllNameControllers() {
    // 釋放舊的
    for (final entry in _delegateNameCtrls.entries) {
      for (final c in entry.value) {
        c.dispose();
      }
    }
    _delegateNameCtrls.clear();

    for (var i = 0; i < lists.length; i++) {
      final delegates =
          (lists[i]['delegates'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      _delegateNameCtrls[i] = delegates
          .map<TextEditingController>(
            (d) => TextEditingController(text: d['delegate_name'] ?? ''),
          )
          .toList();
    }
    setState(() {}); // 重新渲染
  }

  Future<void> _saveData() async {
    // 把 controller 內容同步回 lists
    for (var i = 0; i < lists.length; i++) {
      final ctrls = _delegateNameCtrls[i] ?? [];
      final delegates = (lists[i]['delegates'] as List)
          .cast<Map<String, dynamic>>();
      for (var j = 0; j < delegates.length && j < ctrls.length; j++) {
        delegates[j]['delegate_name'] = ctrls[j].text.trim();
      }
    }

    try {
      await MockApi.saveDelegateList(lists, selectedListIndex);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('✅ 名單已送出後端（Mock）')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ 儲存失敗：$e')));
      }
    }
  }

  Future<void> _addNewList() async {
    setState(() {
      lists.add({
        'list_name': 'New List ${lists.length + 1}',
        'admin_account': <Map<String, dynamic>>[],
        'delegates': <Map<String, dynamic>>[],
      });
      selectedListIndex = lists.length - 1;
      _delegateNameCtrls[selectedListIndex] = <TextEditingController>[];
    });
  }

  Future<void> _deleteCurrentList() async {
    if (lists.length <= 1) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('⚠️ 至少要保留一個名單')));
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('刪除確認'),
        content: Text(
          '確定要刪除「${lists[selectedListIndex]['list_name'] ?? '未命名'}」嗎？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('刪除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (ok != true) return;

    setState(() {
      lists.removeAt(selectedListIndex);
      // 刪掉後重新建立 controllers（避免 index 變動導致對應錯亂）
      _rebuildAllNameControllers();
      selectedListIndex = 0;
    });
  }

  void _addDelegate() {
    setState(() {
      final target = lists[selectedListIndex];
      (target['delegates'] as List).add({
        'delegate_name': '',
        'account': '',
        'password': '',
      });
      (_delegateNameCtrls[selectedListIndex] ??= []).add(
        TextEditingController(),
      );
    });
  }

  void _removeDelegate(int index) {
    setState(() {
      final target = lists[selectedListIndex];
      (target['delegates'] as List).removeAt(index);
      _delegateNameCtrls[selectedListIndex]?.removeAt(index)?.dispose();
    });
  }

  void _addAdmin() {
    setState(() {
      final target = lists[selectedListIndex];
      (target['admin_account'] as List).add({'account': '', 'password': ''});
    });
  }

  void _removeAdmin(int index) {
    setState(() {
      final target = lists[selectedListIndex];
      (target['admin_account'] as List).removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final listNames = lists
        .map((l) => (l['list_name'] ?? 'Unnamed') as String)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('編輯代表名單'),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _saveData),
        ],
      ),
      body: lists.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('選擇名單：'),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButton<int>(
                        value: selectedListIndex,
                        onChanged: (int? newIndex) {
                          if (newIndex == null) return;
                          setState(() {
                            selectedListIndex = newIndex;
                          });
                        },
                        items: List.generate(listNames.length, (index) {
                          return DropdownMenuItem<int>(
                            value: index,
                            child: Text(listNames[index]),
                          );
                        }),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: _addNewList,
                      tooltip: '新增名單',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: _deleteCurrentList,
                      tooltip: '刪除目前名單',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: lists[selectedListIndex]['list_name'] ?? '',
                  decoration: const InputDecoration(
                    labelText: '名單名稱',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => lists[selectedListIndex]['list_name'] = v,
                ),

                const SizedBox(height: 20),
                const Text(
                  '代表名單',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ..._buildDelegateTiles(),

                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('新增代表'),
                  onPressed: _addDelegate,
                ),

                const Divider(height: 32),
                const Text(
                  '管理員帳號',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ..._buildAdminTiles(),

                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('新增管理員'),
                  onPressed: _addAdmin,
                ),
              ],
            ),
    );
  }

  List<Widget> _buildDelegateTiles() {
    final delegates = (lists[selectedListIndex]['delegates'] as List)
        .cast<Map<String, dynamic>>();
    final ctrls = _delegateNameCtrls[selectedListIndex] ?? [];

    return List<Widget>.generate(delegates.length, (index) {
      final d = delegates[index];
      final nameCtrl = (index < ctrls.length)
          ? ctrls[index]
          : TextEditingController(text: d['delegate_name'] ?? '');

      // 若 controller 不存在（例如外部資料改變），補齊一次
      if (index >= ctrls.length) {
        ctrls.add(nameCtrl);
        _delegateNameCtrls[selectedListIndex] = ctrls;
      }

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Delegate Name'),
                onChanged: (val) => d['delegate_name'] = val,
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: d['account'] ?? '',
                decoration: const InputDecoration(labelText: 'Account'),
                onChanged: (val) => d['account'] = val,
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: d['password'] ?? '',
                decoration: const InputDecoration(labelText: 'Password'),
                onChanged: (val) => d['password'] = val,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _removeDelegate(index),
                  tooltip: '刪除代表',
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  List<Widget> _buildAdminTiles() {
    final admins = (lists[selectedListIndex]['admin_account'] as List)
        .cast<Map<String, dynamic>>();

    return List<Widget>.generate(admins.length, (index) {
      final a = admins[index];
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              TextFormField(
                initialValue: a['account'] ?? '',
                decoration: const InputDecoration(labelText: 'Admin Account'),
                onChanged: (val) => a['account'] = val,
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: a['password'] ?? '',
                decoration: const InputDecoration(labelText: 'Password'),
                onChanged: (val) => a['password'] = val,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _removeAdmin(index),
                  tooltip: '刪除管理員',
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
