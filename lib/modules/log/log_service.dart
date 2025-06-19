class LogService {
  static final List<String> _errors = [];

  static void addError(String msg) {
    _errors.add('[${DateTime.now().toIso8601String()}] $msg');
  }

  static List<String> get errors => List.unmodifiable(_errors);
} 