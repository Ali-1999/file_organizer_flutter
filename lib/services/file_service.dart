import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/file_item.dart';

typedef FileMove = ({String from, String to});

class FileService {
  static const _storage = MethodChannel('file_organizer/storage');

  static Future<bool> requestStoragePermission() async {
    if (!Platform.isAndroid) return true;
    final sdk = (await DeviceInfoPlugin().androidInfo).version.sdkInt;
    final permission = sdk >= 30
        ? Permission.manageExternalStorage
        : Permission.storage;
    return (await permission.request()).isGranted;
  }

  static Future<String> getInitialDirectory() async {
    if (Platform.isAndroid) {
      return (await _storage.invokeMethod<String>('root'))!;
    }
    return (await getApplicationDocumentsDirectory()).path;
  }

  static Future<List<FileItem>> getFilesInDirectory(String path) async {
    final items = <FileItem>[];
    await for (final entity in Directory(path).list(followLinks: false)) {
      if (entity is! File && entity is! Directory) continue;
      final stat = await entity.stat();
      if (stat.type == FileSystemEntityType.notFound) continue;
      final isFolder = entity is Directory;
      items.add(
        FileItem(
          path: entity.path,
          name: p.basename(entity.path),
          type: isFolder ? FileType.folder : FileItem.getFileType(entity.path),
          size: isFolder ? null : stat.size,
          modifiedDate: stat.modified,
        ),
      );
    }
    items.sort((a, b) {
      if (a.type == FileType.folder && b.type != FileType.folder) return -1;
      if (a.type != FileType.folder && b.type == FileType.folder) return 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return items;
  }

  static Future<List<DestinationFolder>> getCommonDestinations(
    String root,
  ) async {
    final folders = await getFilesInDirectory(root);
    final camera = p.join(root, 'DCIM', 'Camera');
    return [
      if (await Directory(camera).exists())
        DestinationFolder(path: camera, name: 'Camera'),
      for (final folder in folders.where(
        (item) => item.type == FileType.folder,
      ))
        DestinationFolder(path: folder.path, name: folder.name),
    ];
  }

  static Future<FileMove> move(String from, String folder) async {
    if (p.equals(
      await Directory(p.dirname(from)).resolveSymbolicLinks(),
      await Directory(folder).resolveSymbolicLinks(),
    )) {
      throw FileSystemException('File is already in this folder', from);
    }
    final name = p.basename(from);
    final extension = p.extension(name);
    final stem = p.basenameWithoutExtension(name);
    var to = p.join(folder, name);
    var counter = 1;
    while (await FileSystemEntity.type(to, followLinks: false) !=
        FileSystemEntityType.notFound) {
      to = p.join(folder, '${stem}_${counter++}$extension');
    }
    await moveToExactPath(from, to);
    return (from: from, to: to);
  }

  static Future<void> moveToExactPath(String from, String to) async {
    if (await FileSystemEntity.type(from, followLinks: false) !=
        FileSystemEntityType.file) {
      throw FileSystemException('Source is not a regular file', from);
    }
    // Exclusive creation reserves the name without overwriting existing data.
    final destination = await File(to).create(exclusive: true);
    final source = File(from);
    try {
      try {
        await source.rename(to);
        return;
      } on FileSystemException {
        // A rename can fail when the folders are on different volumes.
        await source.copy(to);
      }
      await source.delete();
    } catch (_) {
      await destination.delete();
      rethrow;
    }
  }
}
