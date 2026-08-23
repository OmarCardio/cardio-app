import 'dart:io';
import 'dart:convert';

class OfflineTransfer {
  HttpServer? _server;

  /// Lance un mini-serveur Web autonome sur l'ordinateur/téléphone sans Internet
  Future<String> startLocalServer(String patientId, String textContent) async {
    await stopServer();
    _server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);

    _server!.listen((HttpRequest request) {
      request.response
        ..headers.contentType = ContentType.html
        ..write('''
          <!DOCTYPE html>
          <html dir="rtl" lang="ar">
          <head>
            <meta charset="UTF-8">
            <title>Fiche Patient - $patientId</title>
            <style>
              body { font-family: sans-serif; padding: 20px; background: #f4f6f9; }
              .card { background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 5px rgba(0,0,0,0.1); }
              h1 { color: #0284c7; }
            </style>
          </head>
          <body>
            <div class="card">
              <h1>بطاقة المريض: $patientId</h1>
              <p>$textContent</p>
            </div>
          </body>
          </html>
        ''')
        ..close();
    });

    return 'http://${_server!.address.address}:8080';
  }

  Future<void> stopServer() async {
    if (_server != null) {
      await _server!.close(force: true);
      _server = null;
    }
  }

  /// Génère le texte compressé pour le QR code
  static String generateQrPayload(String patientId, List<String> moduleIds) {
    final Map<String, dynamic> data = {'p': patientId, 'm': moduleIds};
    return base64Url.encode(utf8.encode(jsonEncode(data)));
  }
}
