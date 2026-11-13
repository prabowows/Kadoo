// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

bool downloadCsvImpl(String filename, String content) {
  try {
    final result = js.context.callMethod('downloadCsv', [filename, content]);
    return result == true;
  } catch (_) {
    return false;
  }
}

void openExternalUrlImpl(String url) {
  try {
    js.context.callMethod('openExternalUrl', [url]);
  } catch (_) {}
}
