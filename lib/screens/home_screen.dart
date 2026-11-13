import 'dart:io';

import 'package:file_picker/file_picker.dart' show FilePicker;
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/file_item.dart';
import '../services/file_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _selected = <String>{};
  final _undo = <List<FileMove>>[];
  final _redo = <List<FileMove>>[];
  final _sourceScroll = ScrollController();
  List<FileItem> _files = [];
  List<DestinationFolder> _destinations = [];
  String _root = '';
  String _path = '';
  String _sourceQuery = '';
  String _destinationQuery = '';
  String? _error;
  bool _busy = true;

  @override
  void initState() {
    super.initState();
    _initialise();
  }

  @override
  void dispose() {
    _sourceScroll.dispose();
    super.dispose();
  }

  Future<void> _initialise() async {
    try {
      final root = await FileService.getInitialDirectory();
      final preferences = await SharedPreferences.getInstance();
      final defaults = await FileService.getCommonDestinations(root);
      final destinations = {for (final folder in defaults) folder.path: folder};
      for (final path
          in preferences.getStringList('destinations') ?? <String>[]) {
        if (await Directory(path).exists()) {
          destinations[path] = DestinationFolder(
            path: path,
            name: p.basename(path),
          );
        }
      }
      if (!mounted) return;
      setState(() {
        _root = root;
        _destinations = destinations.values.toList();
      });
      final saved = preferences.getString('source');
      await _load(
        saved != null && await Directory(saved).exists() ? saved : root,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not access storage. Check the app storage permission.';
        _busy = false;
      });
    }
  }

  Future<void> _load(String path, {bool refresh = false}) async {
    if (!mounted) return;
    setState(() => _busy = true);
    try {
      final files = await FileService.getFilesInDirectory(path);
      if (!mounted) return;
      setState(() {
        _path = path;
        _files = files;
        _error = null;
        if (!refresh) _selected.clear();
        final existing = files.map((file) => file.path).toSet();
        _selected.retainAll(existing);
      });
      if (!refresh && _sourceScroll.hasClients) _sourceScroll.jumpTo(0);
    } on FileSystemException {
      if (mounted) setState(() => _error = 'Could not read $path');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _chooseFolder({required bool destination}) async {
    setState(() => _busy = true);
    try {
      final path = await FilePicker.platform.getDirectoryPath();
      if (path == null || !mounted) return;
      final preferences = await SharedPreferences.getInstance();
      if (!mounted) return;
      if (destination) {
        if (_destinations.any((folder) => folder.path == path)) return;
        final saved = preferences.getStringList('destinations') ?? <String>[];
        await preferences.setStringList('destinations', [...saved, path]);
        if (!mounted) return;
        setState(
          () => _destinations.add(
            DestinationFolder(path: path, name: p.basename(path)),
          ),
        );
      } else {
        await _load(path);
        if (_path == path) await preferences.setString('source', path);
      }
    } catch (_) {
      _notice('Could not use that folder.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _move(DestinationFolder folder, [String? dragged]) async {
    if (_busy) return;
    final paths = dragged != null && !_selected.contains(dragged)
        ? [dragged]
        : _selected.toList();
    if (paths.isEmpty) {
      _notice('Select files first.');
      return;
    }
    setState(() => _busy = true);
    final moved = <FileMove>[];
    for (final path in paths) {
      try {
        moved.add(await FileService.move(path, folder.path));
      } on FileSystemException {
        // Continue with the rest of the batch and report the failure count.
      }
    }
    if (!mounted) return;
    if (moved.isNotEmpty) {
      _undo.add(moved);
      _redo.clear();
      _selected.removeAll(moved.map((move) => move.from));
    }
    final failed = paths.length - moved.length;
    _notice(
      'Moved ${moved.length} to ${folder.name}'
      '${failed == 0 ? '.' : ' · $failed failed.'}',
    );
    await _load(_path, refresh: true);
  }

  Future<void> _replay({required bool undo}) async {
    final pending = undo ? _undo : _redo;
    final completed = undo ? _redo : _undo;
    if (_busy || pending.isEmpty) return;
    setState(() => _busy = true);
    final batch = pending.removeLast();
    final succeeded = <FileMove>[];
    final failed = <FileMove>[];
    for (final move in batch) {
      try {
        await FileService.moveToExactPath(
          undo ? move.to : move.from,
          undo ? move.from : move.to,
        );
        succeeded.add(move);
      } on FileSystemException {
        failed.add(move);
      }
    }
    if (failed.isNotEmpty) pending.add(failed);
    if (succeeded.isNotEmpty) completed.add(succeeded);
    if (!mounted) return;
    _notice(
      '${undo ? 'Undid' : 'Redid'} ${succeeded.length} move(s)'
      '${failed.isEmpty ? '.' : ' · ${failed.length} failed.'}',
    );
    await _load(_path, refresh: true);
  }

  void _notice(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
  }

  void _preview(FileItem file) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(file.name),
        content: file.type == FileType.image
            ? Image.file(
                File(file.path),
                errorBuilder: (_, _, _) => const Text('Preview unavailable'),
              )
            : Text(
                '${file.path}\n\n${file.size ?? 0} bytes\n${file.modifiedDate ?? ''}',
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  IconData _icon(FileType type) => switch (type) {
    FileType.folder => Icons.folder,
    FileType.image => Icons.image,
    FileType.video => Icons.videocam,
    FileType.audio => Icons.music_note,
    FileType.pdf => Icons.picture_as_pdf,
    _ => Icons.insert_drive_file,
  };

  @override
  Widget build(BuildContext context) {
    final source = _files
        .where((file) => file.name.toLowerCase().contains(_sourceQuery))
        .toList();
    final destinations = _destinations.where(
      (folder) => folder.name.toLowerCase().contains(_destinationQuery),
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(_path.isEmpty ? 'File Organizer' : p.basename(_path)),
        leading: IconButton(
          tooltip: 'Parent folder',
          icon: const Icon(Icons.arrow_upward),
          onPressed:
              _busy ||
                  _path.isEmpty ||
                  _path == _root ||
                  p.dirname(_path) == _path
              ? null
              : () => _load(p.dirname(_path)),
        ),
        actions: [
          IconButton(
            tooltip: 'Undo move',
            onPressed: _busy || _undo.isEmpty
                ? null
                : () => _replay(undo: true),
            icon: const Icon(Icons.undo),
          ),
          IconButton(
            tooltip: 'Redo move',
            onPressed: _busy || _redo.isEmpty
                ? null
                : () => _replay(undo: false),
            icon: const Icon(Icons.redo),
          ),
          PopupMenuButton<String>(
            enabled: !_busy,
            onSelected: (action) => switch (action) {
              'source' => _chooseFolder(destination: false),
              'root' => _root.isEmpty ? _initialise() : _load(_root),
              _ => _path.isEmpty ? _initialise() : _load(_path, refresh: true),
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'source',
                child: Text('Choose source folder'),
              ),
              PopupMenuItem(value: 'root', child: Text('Go to storage root')),
              PopupMenuItem(value: 'refresh', child: Text('Refresh')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_busy)
              const LinearProgressIndicator()
            else
              const SizedBox(height: 4),
            if (_error != null) Text(_error!),
            if (_selected.isNotEmpty)
              ListTile(
                title: Text('${_selected.length} selected'),
                trailing: IconButton(
                  tooltip: 'Clear selection',
                  onPressed: _busy ? null : () => setState(_selected.clear),
                  icon: const Icon(Icons.close),
                ),
              ),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        _search(
                          'Search files',
                          (value) => setState(() => _sourceQuery = value),
                        ),
                        Expanded(
                          child: source.isEmpty
                              ? const Center(child: Text('No matching files'))
                              : GridView.builder(
                                  controller: _sourceScroll,
                                  padding: const EdgeInsets.all(8),
                                  gridDelegate:
                                      const SliverGridDelegateWithMaxCrossAxisExtent(
                                        maxCrossAxisExtent: 126,
                                        mainAxisSpacing: 6,
                                        crossAxisSpacing: 6,
                                      ),
                                  itemCount: source.length,
                                  itemBuilder: (_, index) =>
                                      _fileTile(source[index]),
                                ),
                        ),
                      ],
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        TextButton.icon(
                          onPressed: _busy
                              ? null
                              : () => _chooseFolder(destination: true),
                          icon: const Icon(Icons.create_new_folder_outlined),
                          label: const Text('Add folder'),
                        ),
                        _search(
                          'Find folders',
                          (value) => setState(() => _destinationQuery = value),
                        ),
                        Expanded(
                          child: ListView(
                            children: [
                              for (final folder in destinations)
                                DragTarget<String>(
                                  onWillAcceptWithDetails: (_) => !_busy,
                                  onAcceptWithDetails: (details) =>
                                      _move(folder, details.data),
                                  builder: (context, candidates, _) => ListTile(
                                    selected: candidates.isNotEmpty,
                                    dense: true,
                                    title: Text(
                                      folder.name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    onTap: _busy ? null : () => _move(folder),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _search(String hint, ValueChanged<String> onChanged) => Padding(
    padding: const EdgeInsets.all(8),
    child: TextField(
      onChanged: onChanged,
      decoration: InputDecoration(hintText: hint, isDense: true),
    ),
  );

  Widget _fileTile(FileItem file) {
    final selected = _selected.contains(file.path);
    final isFolder = file.type == FileType.folder;
    final icon = Icon(_icon(file.type));
    final tile = Card(
      margin: EdgeInsets.zero,
      color: selected ? Theme.of(context).colorScheme.primaryContainer : null,
      child: InkWell(
        onTap: _busy
            ? null
            : () {
                if (isFolder) {
                  _load(file.path);
                } else {
                  setState(() {
                    if (selected) {
                      _selected.remove(file.path);
                    } else {
                      _selected.add(file.path);
                    }
                  });
                }
              },
        onLongPress: _busy || isFolder ? null : () => _preview(file),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: file.type == FileType.image
                    ? Image.file(
                        File(file.path),
                        cacheWidth: 192,
                        errorBuilder: (_, _, _) => icon,
                      )
                    : icon,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(4),
              child: Text(
                file.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
    if (isFolder || _busy) return tile;
    return Stack(
      fit: StackFit.expand,
      children: [
        tile,
        Positioned(
          top: 0,
          right: 0,
          child: Draggable<String>(
            data: file.path,
            feedback: Material(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(file.name),
              ),
            ),
            child: const Tooltip(
              message: 'Drag to a destination',
              child: Padding(
                padding: EdgeInsets.all(5),
                child: Icon(Icons.drag_indicator, size: 17),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
