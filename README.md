# GiphyMe - Face Swap Application

Transform GIF faces with your own face using AI-powered face swapping technology.

## Features

✨ **AI-Powered Face Swapping**
- State-of-the-art InsightFace technology
- Accurate face detection with MediaPipe
- Frame-by-frame processing for smooth results

🎬 **Giphy Integration**
- Search millions of GIFs from Giphy API
- Browse trending GIFs
- Support for any local GIF file

📱 **Cross-Platform**
- Flutter-based mobile app
- Works on iOS, Android, Web
- Simple, intuitive interface

⚡ **Fast & Efficient**
- Local processing (no cloud dependency)
- Optimized for consumer hardware
- Typical processing: 30-120 seconds

## Quick Start

### Prerequisites
- Python 3.10+
- Flutter 3.13+
- Giphy API Key (free from https://developers.giphy.com)

### One-Command Setup
```bash
chmod +x quick_start.sh
./quick_start.sh
```

### Manual Setup

**1. Backend**
```bash
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python3 main.py
```

**2. Frontend Configuration**
- Edit `lib/config/constants.dart`
- Add your Giphy API key

**3. Start App**
```bash
flutter pub get
flutter run
```

## Getting Started

This project uses Python backend and Flutter frontend.

Detailed documentation

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
