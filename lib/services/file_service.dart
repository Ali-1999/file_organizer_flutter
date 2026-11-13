import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/file_item.dart';

class FileService {
  static Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (status.isGranted) return true;

      final manageStatus = await Permission.manageExternalStorage.request();
      return manageStatus.isGranted;
    }
    return true;
  }

  static Future<List<FileItem>> getFilesInDirectory(String path) async {
    final dir = Directory(path);
    if (!await dir.exists()) return [];

    final entities = await dir.list().toList();
    final items = <FileItem>[];

    for (var entity in entities) {
      final stat = await entity.stat();
      final isDir = entity is Directory;

      items.add(FileItem(
        path: entity.path,
        name: entity.path.split('/').last,
        type: isDir ? FileType.folder : FileItem.getFileType(entity.path),
        size: isDir ? null : stat.size,
        modifiedDate: stat.modified,
      ));
    }

    // Sort: folders first, then by name
    items.sort((a, b) {
      if (a.type == FileType.folder && b.type != FileType.folder) return -1;
      if (a.type != FileType.folder && b.type == FileType.folder) return 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return items;
  }

  static Future<List<DestinationFolder>> getCommonDestinations() async {
    final destinations = <DestinationFolder>[];

    if (Platform.isAndroid) {
      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        final basePath = externalDir.path;
        final commonFolders = [
          'DCIM/Camera',
          'DCIM',
          'Pictures',
          'Movies',
          'Music',
          'Documents',
          'Download',
          'Screenshots',
        ];

        for (var folder in commonFolders) {
          final path = '$basePath/$folder';
          final dir = Directory(path);
          if (await dir.exists()) {
            destinations.add(DestinationFolder(
              path: path,
              name: folder.split('/').last,
            ));
          }
        }
      }
    }

    return destinations;
  }

  static Future<bool> moveFiles(List<String> filePaths, String destinationPath) async {
    try {
      final destDir = Directory(destinationPath);
      if (!await destDir.exists()) {
        await destDir.create(recursive: true);
      }

      for (var filePath in filePaths) {
        final file = File(filePath);
        if (await file.exists()) {
          final fileName = filePath.split('/').last;
          final newPath = '$destinationPath/$fileName';

          // Handle duplicate names
          String finalPath = newPath;
          int counter = 1;
          while (await File(finalPath).exists()) {
            final ext = fileName.contains('.') 
                ? '.${fileName.split('.').last}' 
                : '';
            final baseName = fileName.contains('.') 
                ? fileName.substring(0, fileName.lastIndexOf('.')) 
                : fileName;
            finalPath = '$destinationPath/${baseName}_$counter$ext';
            counter++;
          }

          await file.rename(finalPath);
        }
      }
      return true;
    } catch (e) {
      print('Error moving files: $e');
      return false;
    }
  }

  static Future<String?> getInitialDirectory() async {
    if (Platform.isAndroid) {
      final dir = await getExternalStorageDirectory();
      return dir?.path;
    }
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }
}
