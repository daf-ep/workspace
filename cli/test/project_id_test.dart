import 'dart:io';

import 'package:cli/src/project_id.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory dir;
  late File idFile;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('dafep_id_');
    idFile = File(p.join(dir.path, '.claude', 'ID'));
  });

  tearDown(() {
    dir.deleteSync(recursive: true);
  });

  test('generates a new id shaped like a uuid when none exists', () {
    final result = ensureProjectId(idFile);

    expect(result.created, isTrue);
    expect(
      result.id,
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
  });

  test('keeps the existing id on a second call', () {
    final first = ensureProjectId(idFile);
    final second = ensureProjectId(idFile);

    expect(second.created, isFalse);
    expect(second.id, first.id);
  });
}
