import 'dart:io';

import 'package:cli/src/rules_sync.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory source;
  late Directory destination;

  setUp(() {
    source = Directory.systemTemp.createTempSync('dafep_source_');
    destination = Directory.systemTemp.createTempSync('dafep_dest_');

    File(p.join(source.path, 'rules.md')).writeAsStringSync('root rule');
    final common = Directory(p.join(source.path, 'common'))..createSync();
    File(p.join(common.path, 'code.md')).writeAsStringSync('code rule');
    final customization = Directory(p.join(source.path, 'customization'))
      ..createSync();
    File(
      p.join(customization.path, 'push.md'),
    ).writeAsStringSync('default customization');
  });

  tearDown(() {
    source.deleteSync(recursive: true);
    destination.deleteSync(recursive: true);
  });

  test('copies every top-level entry except customization', () {
    syncRules(source: source, destination: destination);

    expect(
      File(p.join(destination.path, 'rules.md')).readAsStringSync(),
      'root rule',
    );
    expect(
      File(p.join(destination.path, 'common', 'code.md')).readAsStringSync(),
      'code rule',
    );
  });

  test(
    'adds a missing customization file without touching an existing one',
    () {
      final existing = Directory(p.join(destination.path, 'customization'))
        ..createSync(recursive: true);
      File(
        p.join(existing.path, 'push.md'),
      ).writeAsStringSync('a project wrote this already');

      syncRules(source: source, destination: destination);

      expect(
        File(
          p.join(destination.path, 'customization', 'push.md'),
        ).readAsStringSync(),
        'a project wrote this already',
      );
    },
  );

  test('adds a customization file the project never wrote', () {
    syncRules(source: source, destination: destination);

    expect(
      File(
        p.join(destination.path, 'customization', 'push.md'),
      ).readAsStringSync(),
      'default customization',
    );
  });

  test('replaces a stale top-level file on the second run', () {
    syncRules(source: source, destination: destination);
    File(p.join(source.path, 'rules.md')).writeAsStringSync('updated rule');

    syncRules(source: source, destination: destination);

    expect(
      File(p.join(destination.path, 'rules.md')).readAsStringSync(),
      'updated rule',
    );
  });
}
