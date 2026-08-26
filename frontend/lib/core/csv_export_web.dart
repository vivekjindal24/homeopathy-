import 'dart:convert';
import 'dart:html' as html;

/// Downloads [content] as a file named [filename] in the browser.
/// Web-only implementation; see csv_export_stub.dart for other platforms.
void downloadTextFile(String filename, String content, {String mime = 'text/csv'}) {
  final blob = html.Blob([utf8.encode(content)], mime);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
}
