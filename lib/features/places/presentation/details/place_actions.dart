import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/place.dart';

/// Hand-offs to other apps: maps, the dialler and the share sheet.
abstract final class PlaceActions {
  static Uri directionsUri(Place place, {TargetPlatform? platform}) {
    final lat = place.location.latitude;
    final lng = place.location.longitude;
    return (platform ?? defaultTargetPlatform) == TargetPlatform.iOS
        ? Uri.parse('https://maps.apple.com/?daddr=$lat,$lng&dirflg=d')
        : Uri.parse(
            'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
          );
  }

  static Uri mapLink(Place place) => Uri.parse(
    'https://www.google.com/maps/search/?api=1&query='
    '${place.location.latitude},${place.location.longitude}',
  );

  static Future<void> openDirections(BuildContext context, Place place) =>
      _launch(context, directionsUri(place), 'Couldn’t open maps');

  static Future<void> call(BuildContext context, Place place) {
    final phone = place.phone;
    if (phone == null) return Future.value();
    return _launch(
      context,
      Uri(scheme: 'tel', path: phone.replaceAll(' ', '')),
      'Calling isn’t available on this device',
    );
  }

  static Future<void> share(BuildContext context, Place place) async {
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        subject: place.name,
        text:
            '${place.name} · ${place.category.label}\n'
            '${place.fullAddress}\n${mapLink(place)}',
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  static Future<void> copyAddress(BuildContext context, Place place) async {
    await Clipboard.setData(ClipboardData(text: place.fullAddress));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Address copied')));
  }

  static Future<void> _launch(
    BuildContext context,
    Uri uri,
    String failure,
  ) async {
    var launched = false;
    try {
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on PlatformException {
      launched = false;
    }
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(failure)));
    }
  }
}
