/// Requests an appropriately sized image from CDNs that support it, so a
/// 96px thumbnail doesn't download a 5MB original.
String sizedPhotoUrl(String url, {required double width}) {
  final uri = Uri.tryParse(url);
  if (uri == null || uri.host != 'images.unsplash.com') return url;
  return uri
      .replace(
        queryParameters: {
          ...uri.queryParameters,
          'w': '${width.round()}',
          'q': '75',
          'auto': 'format',
          'fit': 'crop',
        },
      )
      .toString();
}
