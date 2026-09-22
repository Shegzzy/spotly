// Sends a "new place" push notification for one of the places in
// assets/data/places.json, to everyone following that place's city.
//
//   dart run tool/send_push.dart --place <id> [--project <id>]
//       [--access-token <token>]
//
// The app follows a city's topic (places-lagos, places-abuja) while "New
// place alerts" is on in the city picker, and tapping the notification opens
// the place. The request is authorised with `gcloud auth print-access-token`
// unless --access-token is given; the account needs permission to send
// messages in the Firebase project.
import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  final placeId = _argument(args, '--place');
  if (placeId == null) {
    stderr.writeln('Usage: dart run tool/send_push.dart --place <id>');
    exit(64);
  }
  final project = _argument(args, '--project') ?? _defaultProject();
  final token = _argument(args, '--access-token') ?? await _gcloudToken();

  final places =
      (jsonDecode(File('assets/data/places.json').readAsStringSync())
              as Map<String, Object?>)['places']!
          as List<Object?>;
  final place = places.cast<Map<String, Object?>>().firstWhere(
    (p) => p['id'] == placeId,
    orElse: () => throw ArgumentError('No place with id "$placeId"'),
  );
  final city = place['city']! as String;
  final description = place['description']! as String;
  final message = {
    'message': {
      'topic': 'places-${city.toLowerCase()}',
      'notification': {
        'title': 'New in $city: ${place['name']}',
        // The first sentence of the description.
        'body': description.split(RegExp(r'(?<=\.)\s')).first,
      },
      'data': {'placeId': placeId},
      'apns': {
        'payload': {
          'aps': {'sound': 'default'},
        },
      },
    },
  };

  final client = HttpClient();
  try {
    final request = await client.postUrl(
      Uri.parse(
        'https://fcm.googleapis.com/v1/projects/$project/messages:send',
      ),
    );
    request.headers
      ..contentType = ContentType.json
      ..set(HttpHeaders.authorizationHeader, 'Bearer $token');
    request.write(jsonEncode(message));
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    if (response.statusCode != 200) {
      throw HttpException('Send failed (${response.statusCode}): $body');
    }
    stdout.writeln('Sent to places-${city.toLowerCase()}: $body');
  } finally {
    client.close();
  }
}

Future<String> _gcloudToken() async {
  final result = await Process.run('gcloud', [
    'auth',
    'print-access-token',
  ], runInShell: true);
  if (result.exitCode != 0) {
    throw ProcessException('gcloud', [
      'auth',
      'print-access-token',
    ], '${result.stderr}');
  }
  return (result.stdout as String).trim();
}

String? _argument(List<String> args, String name) {
  final index = args.indexOf(name);
  return index >= 0 && index + 1 < args.length ? args[index + 1] : null;
}

String _defaultProject() {
  final json =
      jsonDecode(File('.firebaserc').readAsStringSync())
          as Map<String, Object?>;
  return (json['projects']! as Map<String, Object?>)['default']! as String;
}
