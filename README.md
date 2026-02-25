# digitize.art 🎨

> Professional artwork digitization in your pocket

Transform your physical artworks into high-quality digital files using just your smartphone. Powered by AI and computer vision.

[![Flutter](https://img.shields.io/badge/Flutter-3.16+-02569B?logo=flutter)](https://flutter.dev)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

---

## 📱 Overview

**digitize.art** enables artists to:
- Scan paintings, drawings, sculptures using smartphone camera
- Auto-detect artwork edges with perspective correction
- Enhance quality using AI-powered post-processing
- Export in professional formats (JPEG, PNG, TIFF)
- Sync to cloud storage (Firebase, Google Drive, iCloud)

### Key Features

✨ **Smart Capture**
- Real-time edge detection
- AR guidance overlays (ARKit/ARCore)
- Automatic perspective correction
- Quality checks (blur, lighting)

🎨 **Professional Editing**
- Brightness, contrast, saturation adjustments
- White balance correction
- Noise reduction & sharpening
- AI-powered enhancement (Premium)

☁️ **Cloud Integration**
- Auto-sync to Firebase Storage
- Google Drive export
- iCloud integration (iOS)
- Metadata tagging (title, artist, date)

📚 **Learning Tools**
- Interactive setup tutorials
- Voice guidance (multilingual)
- Best practices tips
- Example workflows

---

## 🏗️ Project Structure

```
digitize-art/
├── PROJECT_OVERVIEW.md          # Vision & tech stack
├── ARCHITECTURE.md              # Technical architecture
├── WIREFRAMES.md                # UI/UX design specs
├── CHALLENGES_AND_SOLUTIONS.md  # Problem-solving guide
├── DEPLOYMENT.md                # CI/CD & release guide
├── ROADMAP.md                   # Feature timeline
│
├── setup.sh                     # Automated setup script
│
├── code-examples/
│   ├── camera_service.dart      # Camera handling
│   ├── image_processing_service.dart  # OpenCV processing
│   └── camera_screen.dart       # Main UI screen
│
└── digitize_art/                # Flutter app (generated)
    ├── lib/
    ├── android/
    ├── ios/
    └── test/
```

---

## 🚀 Quick Start

### Prerequisites

- Flutter SDK 3.16+ ([Install](https://docs.flutter.dev/get-started/install))
- Xcode 15+ (iOS development)
- Android Studio (Android development)
- Firebase account

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/digitize-art.git
   cd digitize-art
   ```

2. **Run setup script**
   ```bash
   chmod +x setup.sh
   ./setup.sh
   ```

3. **Configure Firebase**
   ```bash
   # Create Firebase project at console.firebase.google.com
   # Download google-services.json (Android)
   # Download GoogleService-Info.plist (iOS)
   
   cd digitize_art
   flutterfire configure
   ```

4. **Run the app**
   ```bash
   cd digitize_art
   flutter pub get
   flutter run
   ```

---

## 📖 Documentation

- **[Project Overview](PROJECT_OVERVIEW.md)**: Vision, tech stack, monetization
- **[Architecture](ARCHITECTURE.md)**: System design, data flow, services
- **[Wireframes](WIREFRAMES.md)**: Screen-by-screen UI mockups
- **[Challenges & Solutions](CHALLENGES_AND_SOLUTIONS.md)**: Problem-solving strategies
- **[Deployment](DEPLOYMENT.md)**: Build, test, deploy to stores
- **[Roadmap](ROADMAP.md)**: Feature timeline & milestones

---

## 🛠️ Tech Stack

### Frontend
- **Flutter** (Dart): Cross-platform UI framework
- **Riverpod**: State management
- **Camera plugin**: Native camera access

### Image Processing
- **OpenCV**: Edge detection, perspective correction
- **TensorFlow Lite**: ML-based enhancement
- **ML Kit**: On-device computer vision

### Backend & Cloud
- **Firebase**: Auth, Firestore, Storage, Analytics
- **Cloud Functions**: Serverless processing

### AR
- **ARKit** (iOS): 3D guidance overlays
- **ARCore** (Android): AR positioning

---

## 📸 Screenshots

> *Coming soon - add screenshots once app is built*

| Camera Screen | AR Guidance | Editor | Gallery |
|---------------|-------------|--------|---------|
| ![](assets/screenshots/camera.png) | ![](assets/screenshots/ar.png) | ![](assets/screenshots/editor.png) | ![](assets/screenshots/gallery.png) |

---

## 🎯 Roadmap

### Phase 1: MVP (Weeks 1-4)
- ✅ Camera capture with auto-focus
- ✅ Basic edge detection
- ✅ Perspective correction
- ✅ Simple adjustments (brightness, contrast)
- ✅ Local storage

### Phase 2: Enhanced UX (Weeks 5-8)
- 🔄 Interactive tutorial system
- 🔄 AR guidance overlays
- 🔄 Multi-language support (FR, EN)
- 🔄 Batch processing

### Phase 3: Cloud & Premium (Weeks 9-12)
- 🔜 Firebase integration
- 🔜 Cloud sync
- 🔜 AI enhancement (Premium)
- 🔜 Subscription model (RevenueCat)

### Phase 4: Polish & Launch (Weeks 13-16)
- 🔜 Performance optimization
- 🔜 Beta testing (TestFlight/Internal Track)
- 🔜 App Store submission
- 🔜 Marketing website

**See [ROADMAP.md](ROADMAP.md) for detailed timeline**

---

## 🤝 Contributing

Contributions welcome! Please read our [Contributing Guidelines](CONTRIBUTING.md) first.

1. Fork the repo
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

---

## 📄 License

This project is licensed under the MIT License - see [LICENSE](LICENSE) file.

---

## 🙏 Acknowledgments

- OpenCV community for computer vision tools
- Flutter team for amazing framework
- Artists who inspired this project

---

## 📞 Contact

- **Website**: [digitize.art](https://digitize.art)
- **Email**: contact@digitize.art
- **Twitter**: [@digitizeart](https://twitter.com/digitizeart)
- **Discord**: [Join our community](https://discord.gg/digitizeart)

---

**Built with ❤️ for artists, by artists**
