// ignore_for_file: avoid_print
const String _red = '\x1b[31m';
const String _green = '\x1b[32m';
const String _yellow = '\x1b[33m';
const String _cyan = '\x1b[36m';
const String _gray = '\x1b[90m';
const String _bold = '\x1b[1m';
const String _reset = '\x1b[0m';

class InfraUI {
  static void log(String message) => print(message);
  static void error(String message) => print('$_red$message$_reset');
  static void success(String message) => print('$_green$message$_reset');
  static void warn(String message) => print('$_yellow$message$_reset');
  static void info(String message) => print('$_cyan$message$_reset');
  static void header(String title) =>
      print('$_bold${_cyan}=== ${title.toUpperCase()} ===$_reset');
  static void divider() => print('$_gray${'─' * 60}$_reset');
  static void gray(String message) => print('$_gray$message$_reset');
}
