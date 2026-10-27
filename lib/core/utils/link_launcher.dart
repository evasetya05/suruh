import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_colors.dart';

/// Opens external links, with a visible fallback when the platform refuses.
///
/// A dead link is worse than no link, so a failed launch tells the user rather
/// than silently doing nothing.
abstract final class LinkLauncher {
  static Future<void> open(
    BuildContext context,
    String url, {
    String? failureMessage,
  }) async {
    final Uri? uri = Uri.tryParse(url);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    if (uri == null) {
      _report(messenger, failureMessage ?? 'That link is not valid.');
      return;
    }

    try {
      final bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        _report(messenger, failureMessage ?? 'Could not open $url');
      }
    } on Object catch (error, stackTrace) {
      developer.log(
        'Failed to open $url',
        name: 'LinkLauncher',
        error: error,
        stackTrace: stackTrace,
      );
      _report(messenger, failureMessage ?? 'Could not open $url');
    }
  }

  static void _report(ScaffoldMessengerState messenger, String message) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.danger),
      );
  }
}
