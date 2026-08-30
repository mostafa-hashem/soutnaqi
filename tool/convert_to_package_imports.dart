import 'dart:io';

import 'package:path/path.dart' as p;

void main() {
  final libDir = p.normalize(p.join(Directory.current.path, 'lib'));
  if (!Directory(libDir).existsSync()) {
    stderr.writeln('lib/ directory not found');
    exit(1);
  }

  var updatedFiles = 0;

  for (final entity in Directory(libDir).listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;

    final original = entity.readAsStringSync();
    final converted = _convertContent(entity.path, libDir, original);
    if (converted != original) {
      entity.writeAsStringSync(converted);
      updatedFiles++;
      stdout.writeln('Updated ${entity.path}');
    }
  }

  stdout.writeln('Done. Updated $updatedFiles files.');
}

String _convertContent(String filePath, String libDir, String content) {
  final lines = content.split('\n');
  final buffer = StringBuffer();

  for (var index = 0; index < lines.length; index++) {
    var line = lines[index];
    final trimmed = line.trimLeft();

    if (trimmed.startsWith('import ') || trimmed.startsWith('export ')) {
      line = _convertImportLine(filePath, libDir, line);

      if (index + 1 < lines.length) {
        final nextTrimmed = lines[index + 1].trimLeft();
        if (nextTrimmed.startsWith('if (dart.library.')) {
          index++;
          line = '$line\n${_convertConditionalLine(filePath, libDir, lines[index])}';
        }
      }
    }

    buffer.writeln(line);
  }

  return buffer.toString().replaceFirst(RegExp(r'\n$'), '');
}

String _convertImportLine(String filePath, String libDir, String line) {
  final match = RegExp(r"^(import|export)\s+'([^']+)'(.+)?;").firstMatch(line.trim());
  if (match == null) return line;

  final kind = match.group(1)!;
  final uri = match.group(2)!;
  final suffix = match.group(3) ?? '';

  if (uri.startsWith('package:') || uri.startsWith('dart:')) return line;

  final packageUri = _toPackageUri(filePath, libDir, uri);
  final indent = line.substring(0, line.indexOf(kind));
  return "$indent$kind '$packageUri'$suffix;";
}

String _convertConditionalLine(String filePath, String libDir, String line) {
  final match = RegExp(r"^(if \(dart\.library\.[^)]+\))\s+'([^']+)';").firstMatch(line.trim());
  if (match == null) return line;

  final condition = match.group(1)!;
  final uri = match.group(2)!;
  if (uri.startsWith('package:') || uri.startsWith('dart:')) return line;

  final packageUri = _toPackageUri(filePath, libDir, uri);
  final indent = line.substring(0, line.indexOf('if'));
  return "$indent$condition '$packageUri';";
}

String _toPackageUri(String filePath, String libDir, String importPath) {
  String resolvedPath;

  if (importPath.startsWith('.')) {
    resolvedPath = p.normalize(p.join(p.dirname(filePath), importPath));
  } else {
    final fromFileDir = p.normalize(p.join(p.dirname(filePath), importPath));
    resolvedPath = File(fromFileDir).existsSync()
        ? fromFileDir
        : p.normalize(p.join(libDir, importPath));
  }

  final relativeToLib = p.relative(resolvedPath, from: libDir);
  if (relativeToLib.startsWith('..')) {
    throw StateError('Path outside lib: $importPath from $filePath');
  }

  return 'package:soutnaqi/${relativeToLib.replaceAll(r'\', '/')}';
}
