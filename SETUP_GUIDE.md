# GiphyMe - Face Swap App Setup Guide

Complete step-by-step guide to set up and run the GiphyMe face swapping application.

## Architecture Overview

```
┌─────────────────────────────────────────────┐
│          Flutter Frontend (Mobile)          │
│  - GIF Search (Giphy API)                   │
│  - Image Picker                             │
│  - Result Display                           │
└────────────────┬────────────────────────────┘
                 │ (HTTP/Multipart)
                 ▼
┌─────────────────────────────────────────────┐
│        Python FastAPI Backend                │
│  - Face Detection (MediaPipe)               │
│  - Face Swapping (InsightFace)             │
│  - GIF Frame Processing (imageio)           │
│  - Model serving (buffalo_l, inswapper)     │
└─────────────────────────────────────────────┘
```

## Prerequisites

### System Requirements
- **macOS**: Python 3.10+, Flutter 3.13+
- **RAM**: Minimum 4GB (8GB+ recommended)
- **Disk**: 2GB free space (for AI models)

### API Keys
1. **Giphy API Key** (Free)
   - Sign up at: https://developers.giphy.com/dashboard
   - Create an app and get your API key

## Setup Instructions

### Part 1: Backend Setup (Python)

#### Step 1.1: Create Virtual Environment
```bash
cd /Users/ava/development/my_projects/giphyme
cd backend

# Create virtual environment
python3 -m venv venv

# Activate it
source venv/bin/activate
```

#### Step 1.2: Install Dependencies
```bash
# Upgrade pip
pip install --upgrade pip

# Install requirements
pip install -r requirements.txt
```

This will download and install:
- FastAPI & Uvicorn (web server)
- OpenCV (image processing)
- MediaPipe (face detection)
- InsightFace (face swapping AI)
- imageio & ffmpeg (GIF handling)

**Note**: First run will download AI models (~500MB). This is a one-time download.

#### Step 1.3: Verify Installation
```bash
# Test FastAPI import
python3 -c "import fastapi; print('FastAPI OK')"

# Test InsightFace import
python3 -c "import insightface; print('InsightFace OK')"
```

#### Step 1.4: Run Backend Server
```bash
python3 main.py
```

Expected output:
```
INFO:     Uvicorn running on http://0.0.0.0:8000
INFO:     Application startup complete
```

Visit http://localhost:8000/health to verify:
```json
{"status": "healthy", "models_loaded": true}
```

**Keep this terminal open!**

---

### Part 2: Frontend Setup (Flutter)

#### Step 2.1: Configure API Keys
Edit `lib/config/constants.dart`:

```dart
const String GIPHY_API_KEY = 'YOUR_GIPHY_API_KEY_HERE';
const String BACKEND_URL = 'http://localhost:8000';
```

Replace `YOUR_GIPHY_API_KEY_HERE` with your actual Giphy API key.

#### Step 2.2: Get Flutter Dependencies
```bash
# Open new terminal in project root
cd /Users/ava/development/my_projects/giphyme

# Get dependencies
flutter pub get
```

#### Step 2.3: Run the App
```bash
# Start in debug mode
flutter run

# For iOS emulator/device:
flutter run -d <device-id>

# For Web:
flutter run -d chrome
```

---

## Using the App

### Workflow

#### 1. Search for GIFs
- **Screen**: "Search GIFs" tab
- **Action**: Type a search query (e.g., "dancing", "celebration")
- **Result**: Browse trending or search results
- **Note**: Select a GIF file directly from your device instead

#### 2. Select Face Image
- **Screen**: "Face Swap" tab  
- **Action**: Tap "Step 2: Select Face Image"
- **Select**: A clear photo with a visible face
- **Tips**:
  - Front-facing photo works best
  - Good lighting helps
  - One person in frame is ideal

#### 3. Select GIF
- **Screen**: "Face Swap" tab
- **Action**: Tap "Step 1: Select GIF"
- **Select**: A GIF file from your device
- **Tips**:
  - Smaller files process faster (~100-300KB)
  - Ensure faces are visible in the GIF

#### 4. Start Face Swap
- **Action**: Tap "Swap Face" button
- **Backend Status**: Verify green checkmark (Backend connected)
- **Processing**: Wait for completion (typically 30-120 seconds)
- **Result**: View swapped GIF when complete

#### 5. Save or Share
- **After Success**: GIF is saved to your device
- **Location**: Printed in the success message
- **Share**: Use your device's share functionality

---

## Troubleshooting

### Backend Issues

**Backend not connecting**
```
Error: Backend not available
Solution: 
1. Verify backend is running: python3 main.py
2. Check localhost:8000/health returns 200
3. Firewall: Allow localhost:8000
```

**Models failed to download**
```
Error: Failed to load InsightFace models
Solution:
1. Check internet connection
2. First run takes time (~5-10 min for downloads)
3. Models saved to ~/.insightface/models/
4. Try running again
```

**Memory/Performance Issues**
```
Error: Out of memory / Very slow
Solution:
1. Use smaller GIFs (< 1MB)
2. Reduce GIF dimensions
3. Close other apps
4. Increase system swap space
```

### Frontend Issues

**API Key not working**
```
Error: No GIFs found / network errors
Solution:
1. Verify GIPHY_API_KEY in lib/config/constants.dart
2. Check key at: https://developers.giphy.com/dashboard
3. Ensure key is active (not rate limited)
```

**Image picker not working**
```
Error: Can't select images
Solution (macOS):
1. Grant permissions in System Preferences
2. Security & Privacy > Camera/Photos access
3. Restart app: Stop and run flutter run again
```

**Hot reload not showing changes**
```
Solution:
1. Use hot restart (R key)
2. Or stop and rerun: flutter run
3. Clear build: flutter clean && flutter pub get
```

### Face Detection Issues

**"No face detected in image"**
```
Solutions:
- Use a clearer, well-lit photo
- Ensure face fills a reasonable portion of image
- Try a different angle (front-facing works best)
- Ensure good contrast
```

**Face swap looks wrong**
```
Possible causes:
- Face angle very different in GIF vs image
- GIF faces are very small or low resolution
- Try a different source image
- Multiple faces in GIF (swaps all)
```

---

## API Endpoints (Backend)

### Health Check
```
GET /health
Response: {"status": "healthy", "models_loaded": true}
```

### Face Swap
```
POST /swap-face
Content-Type: multipart/form-data
Parameters:
  - gif_file: GIF file (binary)
  - face_image: PNG/JPG with face (binary)
Response: Processed GIF (binary)
```

**Example (cURL)**:
```bash
curl -X POST http://localhost:8000/swap-face \
  -F "gif_file=@input.gif" \
  -F "face_image=@myface.jpg" \
  -o output.gif
```

---

## Performance Tips

| Task | Time | Notes |
|------|------|-------|
| First model load | 2-5 min | One-time only |
| Small GIF (100 frames) | 30-60 sec | 300x300px |
| Medium GIF (200 frames) | 1-2 min | 400x400px |
| Large GIF (500+ frames) | 5+ min | 600x600px |

**Optimization**:
- Smaller GIFs = faster processing
- Face detection is the bottleneck
- Backend runs on CPU (GPU optional)

---

## Project Structure

```
giphyme/
├── lib/                          # Flutter code
│   ├── main.dart                # App entry point
│   ├── config/
│   │   └── constants.dart        # API keys config
│   ├── models/
│   │   └── gif_data.dart         # GIF data model
│   ├── providers/
│   │   ├── giphy_provider.dart   # Giphy API state
│   │   └── face_swap_provider.dart # Face swap state
│   ├── screens/
│   │   ├── home_screen.dart
│   │   ├── gif_search_screen.dart
│   │   └── face_swap_screen.dart
│   ├── services/
│   │   ├── giphy_service.dart    # Giphy API calls
│   │   └── face_swap_service.dart # Backend API calls
│   └── widgets/
│       └── gif_grid_item.dart
├── backend/                      # Python FastAPI
│   ├── main.py                   # FastAPI app
│   ├── requirements.txt           # Python dependencies
│   └── README.md
├── pubspec.yaml                  # Flutter dependencies
└── README.md
```

---

## Next Steps

1. **Start Backend**: `cd backend && source venv/bin/activate && python3 main.py`
2. **Configure API Key**: Add Giphy API key to `lib/config/constants.dart`
3. **Start Frontend**: `flutter run`
4. **Test**: Upload a GIF and face image to test

---

## Development Tips

### Debug Backend
```bash
# Check logs with more detail
python3 -u main.py  # Unbuffered output
```

### Debug Frontend
```bash
# Verbose logging
flutter run -v

# Check errors
flutter doctor -v
```

### Hot Reload During Development
- Press `r` in terminal for hot reload
- Press `R` for hot restart
- Changes reflect in app immediately

---

## Cleanup

### Stop Services
```bash
# Stop backend (Ctrl+C in terminal)
# Stop app (q in Flutter terminal)
```

### Deactivate Backend Environment
```bash
deactivate  # In backend folder terminal
```

### Clear Build Artifacts
```bash
flutter clean
```

---

## Support & Documentation

- **Flutter Docs**: https://flutter.dev/docs
- **Giphy API**: https://developers.giphy.com/docs/api
- **FastAPI**: https://fastapi.tiangolo.com/
- **InsightFace**: https://github.com/deepinsight/insightface

---

## Notes

- Backend serves on `localhost:8000` by default
- First run downloads ~500MB AI models (cached afterwards)
- Models are stored in `~/.insightface/models/`
- All processing is local (no data sent to external servers)
- Processing time depends on GIF size and system specs
