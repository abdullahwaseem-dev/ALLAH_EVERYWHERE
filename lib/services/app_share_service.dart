import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:allah_everywhere/utils/utils/logging/logger.dart';

/// Store listings for this app.
class AppLinks {
  AppLinks._();

  static const appName = 'ALLAH Everywhere';
  static const androidPackage = 'com.allaheverywhere.app';
  static const appStoreId = '6811425021';

  static const playStoreUrl = 'https://play.google.com/store/apps/details?id=$androidPackage';
  static const appStoreUrl = 'https://apps.apple.com/app/id$appStoreId';
}

/// Sharing and store actions that behave correctly on both platforms.
class AppShareService {
  AppShareService._();

  /// The rect the iOS share sheet anchors to. share_plus rejects an empty
  /// rect whenever UIKit gives the share sheet a popover (iPad, and iPhone on
  /// iOS 26), which is why "Share the App" silently did nothing on iOS.
  /// Uses [context]'s own box when it has one, else a 1x1 rect at the
  /// screen centre - either is non-empty and inside the root view.
  static Rect originFor(BuildContext context) {
    final box = context.findRenderObject();
    if (box is RenderBox && box.hasSize && !box.size.isEmpty) {
      return box.localToGlobal(Offset.zero) & box.size;
    }
    final size = MediaQuery.sizeOf(context);
    return Rect.fromCenter(center: size.center(Offset.zero), width: 1, height: 1);
  }

  static String get downloadText =>
      'Download ${AppLinks.appName}:\n'
      'Google Play: ${AppLinks.playStoreUrl}\n'
      'App Store: ${AppLinks.appStoreUrl}';

  static Future<void> shareApp(BuildContext context) async {
    final origin = originFor(context);
    try {
      await SharePlus.instance.share(ShareParams(
        text: 'Check out ${AppLinks.appName} - Quran, Hadith, prayer times, Qibla, and more in one app.\n\n$downloadText',
        subject: AppLinks.appName,
        sharePositionOrigin: origin,
      ));
    } catch (e) {
      VoidLogger.error('Failed to share app', e);
      if (context.mounted) _snack(context, 'Could not open the share sheet. Please try again.');
    }
  }

  /// Shares a PNG through the system share sheet, which lists WhatsApp
  /// (Status or a chat), Instagram (Story, Feed, or Direct) and every other
  /// installed target.
  static Future<bool> shareImage(BuildContext context, Uint8List png, {String? text}) async {
    final origin = originFor(context);
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/allah_everywhere_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(png, flush: true);
      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path, mimeType: 'image/png')],
        text: text,
        sharePositionOrigin: origin,
      ));
      return true;
    } catch (e) {
      VoidLogger.error('Failed to share image', e);
      return false;
    }
  }

  /// Opens this app's review page in the store for the current platform:
  /// the App Store's "Write a Review" sheet on iOS, the Play Store app on
  /// Android - each falling back to the web listing if the store app can't
  /// be opened (e.g. the iOS simulator has no App Store).
  static Future<void> rateApp(BuildContext context) async {
    final candidates = Platform.isIOS
        ? [
            'itms-apps://apps.apple.com/app/id${AppLinks.appStoreId}?action=write-review',
            '${AppLinks.appStoreUrl}?action=write-review',
          ]
        : [
            'market://details?id=${AppLinks.androidPackage}',
            AppLinks.playStoreUrl,
          ];
    for (final url in candidates) {
      try {
        if (await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) return;
      } catch (_) {
        // No handler for this scheme - try the next candidate.
      }
    }
    if (context.mounted) {
      _snack(context, Platform.isIOS ? 'Could not open the App Store.' : 'Could not open the Play Store.');
    }
  }

  static void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
