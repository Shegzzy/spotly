// Seeds Cloud Firestore with the sample places in assets/data/places.json.
//
//   dart run tool/seed_firestore.dart [--project <id>] [--account <email>]
//
// Clients can never write to Firestore (see firestore.rules), so this script
// briefly deploys rules that allow writes to `places` only, for ten minutes,
// uploads the data over the REST API, removes documents that are no longer
// in the JSON, and then always redeploys the locked-down rules. It needs the
// Firebase CLI, signed in to an account that can deploy to the project; pass
// --account if that isn't the CLI's default account.
import 'dart:convert';
import 'dart:io';

const _collection = 'places';

Future<void> main(List<String> args) async {
  final project = _argument(args, '--project') ?? _defaultProject();
  final account = _argument(args, '--account');
  Future<void> firebase(List<String> command) => _firebase([
    ...command,
    '--project',
    project,
    if (account != null) ...['--account', account],
  ]);
  final places =
      (jsonDecode(File('assets/data/places.json').readAsStringSync())
              as Map<String, Object?>)['places']!
          as List<Object?>;
  stdout.writeln('Seeding ${places.length} places into $project…');

  final seedDir = Directory('build/seed')..createSync(recursive: true);
  final expiry = DateTime.now().add(const Duration(minutes: 10));
  File('${seedDir.path}/seed.rules').writeAsStringSync(_seedRules(expiry));
  File('${seedDir.path}/firebase.json').writeAsStringSync(
    jsonEncode({
      'firestore': {'rules': 'seed.rules'},
    }),
  );

  final client = HttpClient();
  try {
    await firebase([
      'deploy',
      '--only',
      'firestore:rules',
      '--config',
      '${seedDir.path}/firebase.json',
    ]);

    final base =
        'https://firestore.googleapis.com/v1/projects/$project/databases/(default)/documents';
    final ids = {for (final p in places) (p! as Map<String, Object?>)['id']};
    final stale = (await _existingIds(client, base)).difference(ids);

    final writes = [
      for (final place in places.cast<Map<String, Object?>>())
        {
          'update': {
            'name':
                'projects/$project/databases/(default)/documents/$_collection/${place['id']}',
            'fields': _fields({...place}..remove('id')),
          },
        },
      for (final id in stale)
        {
          'delete':
              'projects/$project/databases/(default)/documents/$_collection/$id',
        },
    ];

    // New rules can take a little while to apply, so retry permission errors.
    for (var attempt = 1; ; attempt++) {
      final (status, body) = await _request(client, 'POST', '$base:commit', {
        'writes': writes,
      });
      if (status == 200) break;
      if (status == 403 && attempt < 12) {
        stdout.writeln('Waiting for seed rules to take effect…');
        await Future<void>.delayed(const Duration(seconds: 10));
        continue;
      }
      throw HttpException('Commit failed ($status): $body');
    }
    stdout.writeln(
      'Wrote ${places.length} places'
      '${stale.isEmpty ? '' : ', removed ${stale.length} stale'}.',
    );
  } finally {
    client.close();
    stdout.writeln('Restoring read-only rules…');
    await firebase(['deploy', '--only', 'firestore:rules']);
  }
}

String _seedRules(DateTime expiry) =>
    '''
rules_version = '2';
// Temporary rules written by tool/seed_firestore.dart. Writes to places are
// allowed until ${expiry.toUtc().toIso8601String()} only.
service cloud.firestore {
  match /databases/{database}/documents {
    match /$_collection/{placeId} {
      allow read: if true;
      allow write: if request.time < timestamp.value(${expiry.millisecondsSinceEpoch});
    }
  }
}
''';

Future<Set<String>> _existingIds(HttpClient client, String base) async {
  final ids = <String>{};
  String? pageToken;
  do {
    final (status, body) = await _request(
      client,
      'GET',
      '$base/$_collection?pageSize=300&mask.fieldPaths=name'
          '${pageToken == null ? '' : '&pageToken=$pageToken'}',
    );
    if (status != 200) throw HttpException('List failed ($status): $body');
    final json = jsonDecode(body) as Map<String, Object?>;
    for (final doc in (json['documents'] as List<Object?>? ?? const [])) {
      ids.add(
        ((doc! as Map<String, Object?>)['name']! as String).split('/').last,
      );
    }
    pageToken = json['nextPageToken'] as String?;
  } while (pageToken != null);
  return ids;
}

/// Converts JSON into Firestore's typed REST representation. `location`
/// becomes a GeoPoint.
Map<String, Object?> _fields(Map<String, Object?> json) => {
  for (final MapEntry(:key, :value) in json.entries)
    key: key == 'location' && value is Map
        ? {
            'geoPointValue': {
              'latitude': value['lat'],
              'longitude': value['lng'],
            },
          }
        : _value(value),
};

Map<String, Object?> _value(Object? value) => switch (value) {
  null => {'nullValue': null},
  bool() => {'booleanValue': value},
  int() => {'integerValue': '$value'},
  double() => {'doubleValue': value},
  String() => {'stringValue': value},
  List() => {
    'arrayValue': {'values': value.map(_value).toList()},
  },
  Map() => {
    'mapValue': {'fields': _fields(value.cast<String, Object?>())},
  },
  _ => throw ArgumentError('Unsupported value: $value'),
};

Future<(int, String)> _request(
  HttpClient client,
  String method,
  String url, [
  Object? body,
]) async {
  final request = await client.openUrl(method, Uri.parse(url));
  if (body != null) {
    request.headers.contentType = ContentType.json;
    request.write(jsonEncode(body));
  }
  final response = await request.close();
  return (response.statusCode, await response.transform(utf8.decoder).join());
}

Future<void> _firebase(List<String> args) async {
  final result = await Process.run('firebase', args, runInShell: true);
  if (result.exitCode != 0) {
    throw ProcessException(
      'firebase',
      args,
      '${result.stdout}${result.stderr}',
    );
  }
}

String? _argument(List<String> args, String name) {
  final index = args.indexOf(name);
  return index >= 0 && index + 1 < args.length ? args[index + 1] : null;
}

String _defaultProject() {
  final rc = File('.firebaserc');
  if (!rc.existsSync()) {
    throw StateError('No .firebaserc found; pass --project <id>.');
  }
  final json = jsonDecode(rc.readAsStringSync()) as Map<String, Object?>;
  return (json['projects']! as Map<String, Object?>)['default']! as String;
}
