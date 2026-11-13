import 'export_service_stub.dart'
    if (dart.library.js) 'export_service_web.dart';

class ExportService {
  static bool downloadCsv(String filename, String content) {
    return downloadCsvImpl(filename, content);
  }

  static void openExternalUrl(String url) {
    openExternalUrlImpl(url);
  }
}
