import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 行為類型
/// - attendance / vote：設定值
/// - attendance_clear / vote_clear：清空值
class DelegateRecord {
  final String sessionId; // 區分不同 list 的會話
  final String action; // 行為類型
  final String actorAccount; // 操作者帳號（誰送出的）
  final String actorDelegateName; // 操作者對應代表名（登入者）
  final String targetDelegateName; // 被變更的代表（管理員改別人時用）
  final String value; // 狀態或投票內容（清空時可為空字串）
  final DateTime timestamp; // 變更時間

  DelegateRecord({
    required this.sessionId,
    required this.action,
    required this.actorAccount,
    required this.actorDelegateName,
    required this.targetDelegateName,
    required this.value,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'sessionId': sessionId,
    'action': action,
    'actorAccount': actorAccount,
    'actorDelegateName': actorDelegateName,
    'targetDelegateName': targetDelegateName,
    'value': value,
    'timestamp': timestamp.toIso8601String(),
  };

  factory DelegateRecord.fromJson(Map<String, dynamic> json) {
    return DelegateRecord(
      sessionId: json['sessionId'] as String,
      action: json['action'] as String,
      actorAccount: json['actorAccount'] as String,
      actorDelegateName: json['actorDelegateName'] as String,
      targetDelegateName: json['targetDelegateName'] as String,
      value: json['value'] as String? ?? '',
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

class MockApi {
  static String _logKey(String sessionId) => 'server_records_$sessionId';

  /// 模擬「送到後端」：把紀錄 append 到本地 JSON 陣列
  static Future<void> postRecord(DelegateRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _logKey(record.sessionId);

    final raw = prefs.getString(key);
    final List<dynamic> list = raw != null ? jsonDecode(raw) : <dynamic>[];

    list.add(record.toJson());
    await prefs.setString(key, jsonEncode(list));

    // === 若將來要接真後端，在這裡改成 http.post(...) ===
    // await http.post(Uri.parse('https://your.api/records'),
    //   headers: {'Content-Type': 'application/json'},
    //   body: jsonEncode(record.toJson()),
    // );
  }

  /// 查詢目前紀錄（給你 debug 或做簡易後台）
  static Future<List<DelegateRecord>> listRecords(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_logKey(sessionId));
    if (raw == null) return [];
    final List<dynamic> list = jsonDecode(raw);
    return list
        .map((e) => DelegateRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 清空某個 session 的紀錄
  static Future<void> clear(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_logKey(sessionId));
  }
}
