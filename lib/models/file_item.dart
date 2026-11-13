import 'dart:io';

enum FileType {
  folder,
  image,
  video,
  audio,
  document,
  pdf,
  other,
}

class FileItem {
  final String path;
  final String name;
  final FileType type;
  final int? size;
  final DateTime? modifiedDate;
  final String? duration;
  bool isSelected;

  FileItem({
    required this.path,
    required this.name,
    required this.type,
    this.size,
    this.modifiedDate,
    this.duration,
    this.isSelected = false,
  });

  FileItem copyWith({bool? isSelected}) {
    return FileItem(
      path: path,
      name: name,
      type: type,
      size: size,
      modifiedDate: modifiedDate,
      duration: duration,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  static FileType getFileType(String path) {
    final ext = path.toLowerCase();
    if (FileSystemEntity.isDirectorySync(path)) return FileType.folder;
    if (ext.endsWith('.jpg') || ext.endsWith('.jpeg') || ext.endsWith('.png') || 
        ext.endsWith('.gif') || ext.endsWith('.webp') || ext.endsWith('.bmp')) {
      return FileType.image;
    }
    if (ext.endsWith('.mp4') || ext.endsWith('.avi') || ext.endsWith('.mkv') || 
        ext.endsWith('.mov') || ext.endsWith('.wmv') || ext.endsWith('.flv')) {
      return FileType.video;
    }
    if (ext.endsWith('.mp3') || ext.endsWith('.wav') || ext.endsWith('.aac') || 
        ext.endsWith('.flac') || ext.endsWith('.m4a') || ext.endsWith('.ogg')) {
      return FileType.audio;
    }
    if (ext.endsWith('.pdf')) return FileType.pdf;
    if (ext.endsWith('.doc') || ext.endsWith('.docx') || ext.endsWith('.txt') || 
        ext.endsWith('.xls') || ext.endsWith('.xlsx') || ext.endsWith('.ppt') || 
        ext.endsWith('.pptx')) {
      return FileType.document;
    }
    return FileType.other;
  }

  String get displaySize {
    if (size == null) return '';
    if (size! < 1024) return '${size}B';
    if (size! < 1024 * 1024) return '${(size! / 1024).toStringAsFixed(1)}KB';
    if (size! < 1024 * 1024 * 1024) return '${(size! / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(size! / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }
}

class DestinationFolder {
  final String path;
  final String name;
  final bool isHighlighted;

  DestinationFolder({
    required this.path,
    required this.name,
    this.isHighlighted = false,
  });
}
