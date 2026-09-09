import 'dart:io';
import 'dart:math';

/// The result of making sure a project has an id.
class ProjectId {
  /// Creates a result reporting [id], and whether this call just generated it.
  ProjectId(this.id, this.created);

  /// The uuid identifying this project.
  final String id;

  /// Whether this call generated [id], as opposed to reading it back.
  final bool created;
}

/// Reads the project id from [idFile], generating and writing one if absent.
///
/// The id never changes once written: a project keeps the same identity
/// across every later sync.
ProjectId ensureProjectId(File idFile) {
  if (idFile.existsSync()) {
    return ProjectId(idFile.readAsStringSync().trim(), false);
  }
  idFile.parent.createSync(recursive: true);
  final id = generateUuidV4();
  idFile.writeAsStringSync('$id\n');
  return ProjectId(id, true);
}

/// A random version 4 uuid, generated with a cryptographically secure source.
String generateUuidV4() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
      '${hex.substring(20, 32)}';
}
