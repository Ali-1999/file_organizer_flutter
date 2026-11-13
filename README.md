# File Organizer

File Organizer is a Flutter app for Android. Browse files in the left pane and tap a folder in the right pane to move the selected files. The source pane stays in the same folder after the move.

- Tap files to select one or more, or drag a file by its handle to a destination. Dragging a selected file moves the selection.
- Search the current folder and filter the destination list independently.
- Long-press a file to preview images or view file details.
- Add destination folders through the folder picker. Added destinations and the chosen source folder are remembered.
- Use Undo and Redo for moves during the current app session. Duplicate names get a numbered suffix. Existing files are protected during undo and redo.

## Run and build

Install Flutter 3.50 and the Android SDK, then run:

```sh
git clone https://github.com/Ali-1999/file_organizer_flutter.git
cd file_organizer_flutter
flutter pub get
flutter analyze
flutter test
flutter run
flutter build apk --debug
```

On Android 11 and later, enable **Allow access to manage all files** when prompted. Older Android versions use the standard storage permission. Android limits access to protected folders, including other apps' private directories.

See [CONTRIBUTING.md](CONTRIBUTING.md) and [LICENSE](LICENSE).
