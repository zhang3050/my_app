// log_service.dart
// 全局异常日志服务，支持写入和只读获取
class LogService {
  static final List<String> _errors = []; // 错误日志列表

  /// 添加异常日志，带时间戳
  static void addError(String msg) {
    _errors.add('[${DateTime.now().toIso8601String()}] $msg');
  }

  /// 获取所有异常日志（只读）
  static List<String> get errors => List.unmodifiable(_errors);
} 