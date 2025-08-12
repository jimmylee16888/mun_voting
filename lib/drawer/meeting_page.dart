// meeting_page.dart
import 'dart:async';
import 'package:flutter/material.dart';

class MeetingPage extends StatefulWidget {
  final String username;
  final List<String> delegates;
  final bool isAdmin; // 只有管理員可以控制

  const MeetingPage({
    super.key,
    required this.username,
    required this.delegates,
    required this.isAdmin,
  });

  @override
  State<MeetingPage> createState() => _MeetingPageState();
}

class _MeetingPageState extends State<MeetingPage> {
  // 模式
  String _mode = '常設發言名單'; // 常設發言名單 / 正式磋商 / 自由磋商

  // 名單
  final List<String> speakingList = [];
  String? selectedDelegate;

  // 時間（秒）
  int eachTimeSeconds = 60; // 每位時間（常設/正式）
  int totalTimeSeconds = 300; // 總時長（正式/自由）

  // 倒數顯示
  int currentCountdown = 60; // 主倒數（常設/正式）
  int generalCountdown = 300; // 總時長倒數（正式/自由）

  // 計時器
  Timer? _perTimer;
  Timer? _generalTimer;
  bool isCounting = false;

  bool get canControl => widget.isAdmin;

  @override
  void initState() {
    super.initState();
    currentCountdown = eachTimeSeconds;
    generalCountdown = totalTimeSeconds;
  }

  @override
  void dispose() {
    _perTimer?.cancel();
    _generalTimer?.cancel();
    super.dispose();
  }

  // ===== 控制：只有管理員可用 =====
  void _start() {
    if (!canControl) return;
    _stop();
    setState(() => isCounting = true);

    // 自由磋商：只有總時長倒數
    if (_mode == '自由磋商') {
      _generalTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (generalCountdown <= 1) {
          _stop();
          _switchToDefault();
        } else {
          setState(() => generalCountdown--);
        }
      });
      return;
    }

    // 正式/常設：總時長(正式才有) + 個人倒數
    if (_mode != '常設發言名單') {
      _generalTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (generalCountdown <= 1) {
          _stop();
          _switchToDefault();
        } else {
          setState(() => generalCountdown--);
        }
      });
    }

    _perTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (currentCountdown <= 1) {
        _next();
      } else {
        setState(() => currentCountdown--);
      }
    });
  }

  void _stop() {
    _perTimer?.cancel();
    _generalTimer?.cancel();
    setState(() => isCounting = false);
  }

  void _next() {
    if (!canControl || _mode == '自由磋商') return;
    if (speakingList.isNotEmpty) {
      setState(() {
        speakingList.removeAt(0);
        currentCountdown = eachTimeSeconds;
      });
    }
  }

  void _switchToDefault() {
    _stop();
    setState(() {
      _mode = '常設發言名單';
      currentCountdown = eachTimeSeconds;
      generalCountdown = totalTimeSeconds;
      speakingList.clear();
    });
  }

  String _fmt(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final ss = (s % 60).toString().padLeft(2, '0');
    return '$m:$ss';
  }

  // ===== 會議設定（簡潔明瞭）=====
  Future<void> _openSettingsDialog() async {
    if (!canControl) return;

    String tmpMode = _mode;
    final totalMinCtrl = TextEditingController(
      text: (totalTimeSeconds ~/ 60).toString(),
    );
    final eachSecCtrl = TextEditingController(text: eachTimeSeconds.toString());

    final applied = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('會議設定'),
          content: StatefulBuilder(
            builder: (context, setLocal) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    value: '常設發言名單',
                    groupValue: tmpMode,
                    onChanged: (v) => setLocal(() => tmpMode = v!),
                    title: const Text('常設發言名單'),
                  ),
                  RadioListTile<String>(
                    value: '正式磋商',
                    groupValue: tmpMode,
                    onChanged: (v) => setLocal(() => tmpMode = v!),
                    title: const Text('正式磋商'),
                  ),
                  RadioListTile<String>(
                    value: '自由磋商',
                    groupValue: tmpMode,
                    onChanged: (v) => setLocal(() => tmpMode = v!),
                    title: const Text('自由磋商'),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: totalMinCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: '總時長(分鐘)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (tmpMode != '自由磋商')
                        Expanded(
                          child: TextField(
                            controller: eachSecCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: '每位(秒)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('套用'),
            ),
          ],
        );
      },
    );

    if (applied == true) {
      final newTotalMin = int.tryParse(totalMinCtrl.text.trim());
      final newEachSec = int.tryParse(eachSecCtrl.text.trim());
      _stop();
      setState(() {
        _mode = tmpMode;
        if (newTotalMin != null && newTotalMin > 0) {
          totalTimeSeconds = newTotalMin * 60;
        }
        if (_mode != '自由磋商' && newEachSec != null && newEachSec > 0) {
          eachTimeSeconds = newEachSec;
        }
        speakingList.clear();
        currentCountdown = eachTimeSeconds;
        generalCountdown = totalTimeSeconds;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final available = widget.delegates
        .where((d) => !speakingList.contains(d))
        .toList();
    final current = speakingList.isNotEmpty ? speakingList.first : '尚無代表';
    final scheme = Theme.of(context).colorScheme;

    final isFree = _mode == '自由磋商';

    return Scaffold(
      appBar: AppBar(
        title: Text('MUN - ${widget.isAdmin ? "管理員" : "代表"}'),
        actions: [
          if (canControl)
            IconButton(
              tooltip: '會議設定',
              icon: const Icon(Icons.settings),
              onPressed: _openSettingsDialog,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ===== 計時卡片 =====
          _SoftCard(
            child: Column(
              children: [
                // 自由磋商：只顯示總時長
                if (isFree) ...[
                  const Text('總時長', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(
                    _fmt(generalCountdown),
                    style: const TextStyle(fontSize: 42, color: Colors.red),
                  ),
                ] else ...[
                  const Text('現在發言', style: TextStyle(fontSize: 16)),
                  Text(
                    current,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30, // 放大
                      fontWeight: FontWeight.w700,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _fmt(currentCountdown),
                    style: const TextStyle(fontSize: 38, color: Colors.red),
                  ),
                  if (_mode == '正式磋商') ...[
                    const SizedBox(height: 6),
                    Text(
                      '⏳ 總時長：${_fmt(generalCountdown)}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ],

                const SizedBox(height: 12),

                // 控制鍵（僅管理員）
                if (canControl)
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      FilledButton.icon(
                        onPressed: _start,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('開始'),
                      ),
                      TextButton.icon(
                        onPressed: _stop,
                        icon: const Icon(Icons.pause),
                        label: const Text('暫停'),
                      ),
                      if (!isFree)
                        FilledButton.tonalIcon(
                          onPressed: speakingList.isNotEmpty ? _next : null,
                          icon: const Icon(Icons.skip_next),
                          label: const Text('下一位'),
                        ),
                    ],
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Divider(),

          // ===== 發言名單（自由磋商不顯示）=====
          if (!isFree) ...[
            const Text('📄 發言名單', style: TextStyle(fontSize: 18)),
            if (speakingList.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: Text('尚無代表在名單中', style: TextStyle(color: Colors.grey)),
              ),

            ...speakingList.map(
              (d) => _SoftCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: ListTile(
                  title: Text(d),
                  trailing: canControl
                      ? IconButton(
                          icon: const Icon(
                            Icons.remove_circle,
                            color: Colors.red,
                          ),
                          onPressed: () =>
                              setState(() => speakingList.remove(d)),
                        )
                      : null,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 新增代表（僅管理員）
            if (canControl)
              Row(
                children: [
                  Expanded(
                    child: DropdownButton<String>(
                      value: selectedDelegate,
                      hint: const Text('選擇代表'),
                      isExpanded: true,
                      items: available
                          .map(
                            (d) => DropdownMenuItem(value: d, child: Text(d)),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => selectedDelegate = val),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.tonal(
                    onPressed: (selectedDelegate != null)
                        ? () => setState(() {
                            speakingList.add(selectedDelegate!);
                            selectedDelegate = null;
                          })
                        : null,
                    child: const Text('加入'),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }
}

/* ===== 共用：簡潔卡片（無毛玻璃） ===== */
class _SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry radius;

  const _SoftCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = const BorderRadius.all(Radius.circular(20)),
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.black.withOpacity(0.03)),
      ),
      child: child,
    );
  }
}
