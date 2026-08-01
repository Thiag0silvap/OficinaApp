import 'dart:io';

import 'package:url_launcher/url_launcher.dart';

class WhatsAppService {
  static String normalizePhone(String phone) {
    var digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0')) digits = digits.substring(1);
    if (!digits.startsWith('55')) digits = '55$digits';
    return digits;
  }

  static Future<void> openChat({
    required String phone,
    required String message,
  }) async {
    final normalized = normalizePhone(phone);
    final encodedMessage = Uri.encodeComponent(message);

    final appUri = Uri.parse(
      'whatsapp://send?phone=$normalized&text=$encodedMessage',
    );
    final webUri = Uri.parse(
      'https://wa.me/$normalized?text=$encodedMessage',
    );

    final openedApp = await launchUrl(
      appUri,
      mode: LaunchMode.externalApplication,
    );
    if (openedApp) return;

    final openedWeb = await launchUrl(
      webUri,
      mode: LaunchMode.externalApplication,
    );
    if (!openedWeb) {
      throw Exception('Não foi possível abrir o WhatsApp.');
    }
  }

  /// Mobile: compartilha PDF e abre WhatsApp com mensagem
  /// Desktop: comportamento original (só abre o chat)
  static Future<void> sendPdfViaWhatsApp({
    required String filePath,
    required String phone,
    required String message,
    required String clienteNome,
  }) async {
    if (Platform.isAndroid || Platform.isIOS) {
      // No mobile compartilha o arquivo direto — o usuário escolhe o app
      // (WhatsApp, Telegram, Drive, e-mail, etc)
      await openChat(phone: phone, message: message);
      return;
    }

    // Desktop: comportamento original
    await openChat(phone: phone, message: message);
  }
}