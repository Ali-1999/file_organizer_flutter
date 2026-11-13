import 'dart:io';
import 'package:flutter/material.dart';
import '../models/file_item.dart';
import '../services/file_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String currentPath = '';
  List<FileItem> files = [];
  List<DestinationFolder> destinations = [];
  Set<int> selectedIndices = {};
  bool isLoading = true;
  bool organizerMode = true;
  String? toastMessage;
  bool showToast = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final path = await FileService.getInitialDirectory();
    if (path != null) {
      await _loadDirectory(path);
      await _loadDestinations();
    }
  }

  Future<void> _loadDirectory(String path) async {
    setState(() => isLoading = true);
    final items = await FileService.getFilesInDirectory(path);
    setState(() {
      currentPath = path;
      files = items;
      selectedIndices.clear();
      isLoading = false;
    });
  }

  Future<void> _loadDestinations() async {
    final dests = await FileService.getCommonDestinations();
    setState(() {
      destinations = dests;
    });
  }

  void _toggleSelection(int index) {
    setState(() {
      if (selectedIndices.contains(index)) {
        selectedIndices.remove(index);
      } else {
        selectedIndices.add(index);
      }
    });
  }

  void _clearSelection() {
    setState(() => selectedIndices.clear());
  }

  Future<void> _moveToDestination(String destPath, String destName) async {
    if (selectedIndices.isEmpty) {
      _showToast('Select files first!');
      return;
    }

    final pathsToMove = selectedIndices.map((i) => files[i].path).toList();
    final success = await FileService.moveFiles(pathsToMove, destPath);

    if (success) {
      _showToast('Moved ${selectedIndices.length} file(s) to $destName');
      // Reload current directory but keep position
      await _loadDirectory(currentPath);
    } else {
      _showToast('Failed to move files');
    }
  }

  void _showToast(String message) {
    setState(() {
      toastMessage = message;
      showToast = true;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => showToast = false);
      }
    });
  }

  void _navigateToFolder(String path) {
    _loadDirectory(path);
  }

  void _goBack() {
    final parent = Directory(currentPath).parent.path;
    if (parent != currentPath) {
      _loadDirectory(parent);
    }
  }

  String _getBreadcrumb() {
    final parts = currentPath.split('/');
    if (parts.length <= 3) return currentPath;
    return '.../${parts.sublist(parts.length - 3).join(' > ')}';
  }

  IconData _getFileIcon(FileType type) {
    switch (type) {
      case FileType.folder:
        return Icons.folder;
      case FileType.image:
        return Icons.image;
      case FileType.video:
        return Icons.videocam;
      case FileType.audio:
        return Icons.music_note;
      case FileType.pdf:
        return Icons.picture_as_pdf;
      case FileType.document:
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileColor(FileType type) {
    switch (type) {
      case FileType.folder:
        return const Color(0xFFFFA726);
      case FileType.image:
        return const Color(0xFF66BB6A);
      case FileType.video:
        return const Color(0xFFEF5350);
      case FileType.audio:
        return const Color(0xFFAB47BC);
      case FileType.pdf:
        return const Color(0xFFEF5350);
      case FileType.document:
        return const Color(0xFF42A5F5);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              // App Bar
              _buildAppBar(),
              // Selection Bar
              if (selectedIndices.isNotEmpty) _buildSelectionBar(),
              // Main Content
              Expanded(
                child: Row(
                  children: [
                    // Source Pane
                    Expanded(
                      flex: 13,
                      child: _buildSourcePane(),
                    ),
                    // Divider
                    Container(
                      width: 2,
                      color: Colors.grey.shade300,
                    ),
                    // Destination Pane
                    Expanded(
                      flex: 7,
                      child: _buildDestinationPane(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Toast
          if (showToast) _buildToast(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _goBack,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _getBreadcrumb(),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {},
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            IconButton(
              icon: const Icon(Icons.undo),
              onPressed: () {},
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            IconButton(
              icon: const Icon(Icons.redo),
              onPressed: () {},
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {},
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {},
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: const Color(0xFF1976D2),
      child: Row(
        children: [
          Text(
            '${selectedIndices.length} item${selectedIndices.length > 1 ? 's' : ''} selected',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _clearSelection,
            child: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildSourcePane() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Folder Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentPath.split('/').last,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${files.length} items',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFC8E6C9)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF4CAF50),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Organizer Mode',
                        style: TextStyle(
                          color: Color(0xFF2E7D32),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // File Grid
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : files.isEmpty
                    ? const Center(child: Text('No files'))
                    : GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: files.length,
                        itemBuilder: (context, index) {
                          final file = files[index];
                          final isSelected = selectedIndices.contains(index);

                          return GestureDetector(
                            onTap: () {
                              if (file.type == FileType.folder) {
                                _navigateToFolder(file.path);
                              } else {
                                _toggleSelection(index);
                              }
                            },
                            onLongPress: () {
                              // Preview mode
                              _showToast('Preview: ${file.name}');
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFE3F2FD)
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF1976D2)
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  Column(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Container(
                                          margin: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: _getFileColor(file.type).withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Center(
                                            child: Icon(
                                              _getFileIcon(file.type),
                                              size: 36,
                                              color: _getFileColor(file.type),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 4),
                                          child: Text(
                                            file.name,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Colors.black87,
                                            ),
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (isSelected)
                                    Positioned(
                                      top: 6,
                                      left: 6,
                                      child: Container(
                                        width: 22,
                                        height: 22,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF1976D2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                      ),
                                    ),
                                  if (file.type == FileType.video && file.duration != null)
                                    Positioned(
                                      bottom: 28,
                                      right: 4,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius: BorderRadius.circular(3),
                                        ),
                                        child: Text(
                                          file.duration!,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildDestinationPane() {
    return Container(
      color: const Color(0xFFFAFAFA),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Destination',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Search Box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, size: 18, color: Colors.grey.shade500),
                  const SizedBox(width: 8),
                  Text(
                    'Search folders...',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Destination List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: destinations.length,
              itemBuilder: (context, index) {
                final dest = destinations[index];
                final isHighlighted = dest.name.toLowerCase() == 'images';

                return GestureDetector(
                  onTap: () => _moveToDestination(dest.path, dest.name),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isHighlighted
                          ? const Color(0xFFE3F2FD)
                          : Colors.white,
                      border: Border.all(
                        color: isHighlighted
                            ? const Color(0xFF1976D2)
                            : Colors.grey.shade300,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.folder_outlined,
                          size: 22,
                          color: isHighlighted
                              ? const Color(0xFF1976D2)
                              : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            dest.name,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                        Icon(
                          dest.name == 'More' ? Icons.keyboard_arrow_down : Icons.arrow_outward,
                          size: 16,
                          color: Colors.grey.shade400,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToast() {
    return Positioned(
      bottom: 24,
      left: 0,
      right: 0,
      child: Center(
        child: AnimatedOpacity(
          opacity: showToast ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(
              toastMessage ?? '',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
