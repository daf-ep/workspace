import 'dart:io';

import 'package:path/path.dart' as p;

/// Finds the rules directory that ships next to this tool.
///
/// Walks up from the running script to the package root, the first parent
/// carrying a `pubspec.yaml`, then looks for a sibling `rules` directory.
Directory? findRulesSource() {
  final scriptPath = File.fromUri(Platform.script).resolveSymbolicLinksSync();
  var dir = Directory(p.dirname(scriptPath));
  while (!File(p.join(dir.path, 'pubspec.yaml')).existsSync()) {
    final parent = dir.parent;
    if (parent.path == dir.path) return null;
    dir = parent;
  }
  final rules = Directory(p.join(dir.parent.path, 'rules'));
  return rules.existsSync() ? rules : null;
}

/// Syncs [source] into [destination].
///
/// Every top-level entry gets replaced, except `customization`, whose files
/// only get added when missing: a project's own customizations never get
/// overwritten by a later sync.
void syncRules({required Directory source, required Directory destination}) {
  destination.createSync(recursive: true);

  for (final entry in source.listSync()) {
    final name = p.basename(entry.path);
    if (name == 'customization') continue;
    final targetPath = p.join(destination.path, name);
    _removeIfExists(targetPath);
    _copyPath(entry, targetPath);
  }

  final customizationSource = Directory(p.join(source.path, 'customization'));
  if (!customizationSource.existsSync()) return;

  final customizationDest = Directory(p.join(destination.path, 'customization'))
    ..createSync(recursive: true);

  for (final file in customizationSource.listSync().whereType<File>()) {
    final destPath = p.join(customizationDest.path, p.basename(file.path));
    if (!File(destPath).existsSync()) {
      file.copySync(destPath);
    }
  }
}

void _removeIfExists(String path) {
  final type = FileSystemEntity.typeSync(path);
  if (type == FileSystemEntityType.notFound) return;
  if (type == FileSystemEntityType.directory) {
    Directory(path).deleteSync(recursive: true);
  } else {
    File(path).deleteSync();
  }
}

void _copyPath(FileSystemEntity entity, String destinationPath) {
  if (entity is Directory) {
    Directory(destinationPath).createSync(recursive: true);
    for (final child in entity.listSync()) {
      _copyPath(child, p.join(destinationPath, p.basename(child.path)));
    }
  } else if (entity is File) {
    entity.copySync(destinationPath);
  }
}
