# 📁 File Organizer

A **high-speed file organizer** for Android that eliminates the back-and-forth navigation pain of traditional file managers. Built with Flutter and designed for rapid file organization.

![Organizer Mode](screenshots/organizer_mode.png)

## ✨ Features

### 🎯 Organizer Mode
- **Single-tap to select** files (does NOT open them)
- **Tap destination folder** to move selected files instantly
- **Stay in source folder** after move — no auto-navigation
- **Auto multi-select** — tap multiple files without mode switches
- **Long-press for preview** — view files without selecting

### 📱 Split Screen Interface
- **Persistent dual-pane** layout
- **Left pane**: Source folder files (with thumbnails)
- **Right pane**: Destination folders list
- **Independent scrolling** for both panes

### 🚀 Lightning Fast Workflow
- **Zero confirmation dialogs** — moves happen instantly
- **No animations or popups** blocking your flow
- **Batch operations** — move hundreds of files in one tap
- **Preserves scroll position** and UI state after every operation

## 📸 Screenshots

| Organizer Mode | Multi-Select | Drag & Drop |
|---|---|---|
| ![Mode](screenshots/mode.png) | ![Select](screenshots/select.png) | ![Drag](screenshots/drag.png) |

## 🛠️ Tech Stack

- **Flutter 3.x** — Cross-platform UI framework
- **Dart** — Programming language
- **permission_handler** — Storage permissions
- **path_provider** — File system access
- **shared_preferences** — Settings persistence

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (>=3.0.0)
- Android Studio / VS Code
- Android SDK (API 21+)

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/file_organizer.git
cd file_organizer

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Build Release APK/AAB

```bash
# Build APK
flutter build apk --release

# Build AAB (for Play Store)
flutter build appbundle --release
```

## 📋 Google Play Store Publishing Guide

### 1. Developer Account Setup
- Go to [Google Play Console](https://play.google.com/console)
- Pay one-time **$25** registration fee
- Verify identity with government ID
- Enable two-step verification

### 2. App Signing
```bash
# Generate keystore
keytool -genkey -v -keystore upload-keystore.jks -storetype JKS   -keyalg RSA -keysize 2048 -validity 10000   -alias upload

# Configure in android/key.properties
```

### 3. Store Listing Requirements
| Asset | Specification |
|-------|--------------|
| App Icon | 512x512 PNG |
| Feature Graphic | 1024x500 JPG/PNG |
| Screenshots | 2-8 per device type (1080x1920) |
| Title | Max 30 characters |
| Short Description | Max 80 characters |
| Full Description | Max 4000 characters |

### 4. Testing Requirements (New Accounts)
- **12 testers** minimum for closed testing
- **14 consecutive days** of testing
- Testers must opt-in via Google account

### 5. Required Permissions
```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE"/>
```

### 6. Privacy Policy
- Required if app collects any user data
- Host on public URL (GitHub Pages, website, etc.)
- Must match Data Safety form declarations

### 7. Data Safety Form
Declare in Play Console:
- What data is collected (none for this app)
- How data is used
- Whether shared with third parties
- Encryption status

## 🤝 Contributing

We welcome contributions! Please read our [Contributing Guide](CONTRIBUTING.md) first.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Original concept by the community
- Built with ❤️ using Flutter
- Icons by Material Design

## 📞 Support

- GitHub Issues: [Report a bug](https://github.com/yourusername/file_organizer/issues)
- Email: support@fileorganizer.app

---

**Made with Flutter 💙 | Open Source | Free Forever**
