/// Non-web stub: file downloads are a browser capability.
void downloadTextFile(String filename, String content, {String mime = 'text/csv'}) {
  throw UnsupportedError('File download is only supported on the web build.');
}
