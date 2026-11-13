import 'dart:io';

import 'package:file_organizer/services/file_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;
  late Directory source;
  late Directory destination;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('organizer_test_');
    source = await Directory(p.join(root.path, 'source')).create();
    destination = await Directory(p.join(root.path, 'destination')).create();
  });

  tearDown(() => root.delete(recursive: true));

  test('duplicate names are preserved and moves can be reversed', () async {
    final original = await File(p.join(source.path, 'photo.jpg'))
        .writeAsString('new');
    final existing = await File(p.join(destination.path, 'photo.jpg'))
        .writeAsString('old');
    final move = await FileService.move(original.path, destination.path);

    expect(p.basename(move.to), 'photo_1.jpg');
    expect(await existing.readAsString(), 'old');
    expect(await original.exists(), isFalse);

    await FileService.moveToExactPath(move.to, move.from);
    expect(await original.readAsString(), 'new');
    await FileService.moveToExactPath(move.from, move.to);
    expect(await File(move.to).readAsString(), 'new');
  });

  test('a conflict leaves both files untouched', () async {
    final original = await File(p.join(source.path, 'data'))
        .writeAsString('source');
    final existing = await File(p.join(destination.path, 'data'))
        .writeAsString('destination');

    await expectLater(
      FileService.moveToExactPath(original.path, existing.path),
      throwsA(isA<FileSystemException>()),
    );
    expect(await original.readAsString(), 'source');
    expect(await existing.readAsString(), 'destination');
  });

  test('a move into the source folder leaves the file in place', () async {
    final original = await File(p.join(source.path, 'data'))
        .writeAsString('source');
    await expectLater(
      FileService.move(original.path, source.path),
      throwsA(isA<FileSystemException>()),
    );
    expect(await source.list().map((entry) => entry.path).toList(), [
      original.path,
    ]);
  });
}
