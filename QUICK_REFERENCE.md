# GiphyMe Quick Reference

Fast answers to common questions while developing or using GiphyMe.

## 🚀 Starting the App

### Quick Start (Automated)
```bash
cd /Users/ava/development/my_projects/giphyme
chmod +x quick_start.sh
./quick_start.sh
```

### Manual Start

**Terminal 1 - Backend:**
```bash
cd /Users/ava/development/my_projects/giphyme/backend
source venv/bin/activate
python3 main.py
```

**Terminal 2 - Frontend:**
```bash
cd /Users/ava/development/my_projects/giphyme
flutter run
```

## 🔧 Configuration

### Add Giphy API Key
**File**: `lib/config/constants.dart`

```dart
const String GIPHY_API_KEY = 'YOUR_API_KEY_HERE';
```

Get key from: https://developers.giphy.com/dashboard

### Change Backend URL
**File**: `lib/config/constants.dart`

```dart
// Local development
const String BACKEND_URL = 'http://localhost:8000';

// Remote server
const String BACKEND_URL = 'https://your-server.com';
```

## 📱 Using the App

### Step 1: Search for GIFs
- Tap "Search GIFs" tab
- Type query (optional, shows trending by default)
- Requires Giphy API key configured

### Step 2: Prepare Files
- **GIF**: Download from Giphy or select local file
- **Face Image**: Clear photo of your face
- File format: GIF (for input), JPG/PNG (for face)

### Step 3: Swap Face
- Go to "Face Swap" tab
- Select GIF file (Step 1)
- Select face image (Step 2)
- Verify backend connected (green checkmark)
- Tap "Swap Face"
- Wait for processing

### Step 4: Save Result
- Success message shows file location
- GIF saved to: `~/Documents/giphyme/swapped_*.gif`
- Tap "Start Over" to process another GIF

## ⚙️ Development

### Hot Reload
During `flutter run`:
- Press `r` - Hot reload (code changes)
- Press `R` - Hot restart (state reset)
- Press `q` - Quit

### View Backend Logs
Terminal with backend running shows logs:
```
INFO:     Request received
INFO:     Detecting faces...
INFO:     Processing frame 1/100
...
INFO:     GIF saved successfully
```

### View Flutter Logs
```bash
flutter run -v  # Verbose output
```

### Check API Health
```bash
curl http://localhost:8000/health
```

Expected response:
```json
{"status": "healthy", "models_loaded": true}
```

## 📦 Project Files

| File | Purpose |
|------|---------|
| `lib/main.dart` | App entry point |
| `lib/config/constants.dart` | API keys & URLs |
| `lib/screens/*` | UI screens |
| `lib/providers/*` | State management |
| `lib/services/*` | API calls |
| `backend/main.py` | Face swap API server |
| `backend/requirements.txt` | Python dependencies |
| `pubspec.yaml` | Flutter dependencies |

## 🐛 Troubleshooting

### Backend Won't Start
```bash
# Check Python version
python3 --version  # Need 3.10+

# Reinstall dependencies
pip install --upgrade pip
pip install -r requirements.txt

# Check port availability
lsof -i :8000  # Port in use?

# Try different port (edit main.py)
```

### No Giphy Results
- Check API key is valid
- Verify internet connection
- Check rate limiting (free tier: 43 requests/hour)

### Face Not Detected
- Use clearer image
- Better lighting helps
- Try front-facing photo
- Ensure face fills reasonable portion

### Very Slow Processing
- Use smaller GIF (< 1MB)
- Reduce GIF dimensions
- Close other apps
- Check system RAM available

### Flutter Won't Run
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run

# Check environment
flutter doctor
```

## 📊 Performance Tips

| Action | Expected Time |
|--------|---------------|
| App launch | 2-3s |
| Load GIF search | 1-2s |
| Download models (first run) | 5-10 min |
| Process small GIF (100 frames) | 30-60s |
| Process medium GIF (200 frames) | 1-2 min |
| Process large GIF (500+ frames) | 5+ min |

**Optimization**:
- Smaller files = faster processing
- M1/M2 Macs faster than Intel
- Close unnecessary apps
- Ensure good internet for API calls

## 🔌 API Endpoints

### Health Check
```
GET http://localhost:8000/health

Response:
{
  "status": "healthy",
  "models_loaded": true
}
```

### Face Swap
```
POST http://localhost:8000/swap-face

Body (multipart/form-data):
- gif_file: <binary GIF>
- face_image: <binary JPG/PNG>

Response: <binary GIF>
```

**Example cURL**:
```bash
curl -X POST http://localhost:8000/swap-face \
  -F "gif_file=@input.gif" \
  -F "face_image=@myface.jpg" \
  -o output.gif
```

## 💾 File Locations

### App Files
- Source code: `/Users/ava/development/my_projects/giphyme/lib/`
- Backend: `/Users/ava/development/my_projects/giphyme/backend/`

### Generated/Temporary Files
- AI Models: `~/.insightface/models/` (auto-downloaded)
- GIF Cache: `~/Library/Caches/` (auto-managed)
- Output GIFs: `~/Documents/giphyme/` (user accessible)

### Configuration Files
- Constants: `lib/config/constants.dart`
- Pubspec: `pubspec.yaml`
- Requirements: `backend/requirements.txt`

## 📚 Documentation

- **Full Setup**: Read [SETUP_GUIDE.md](SETUP_GUIDE.md)
- **Architecture**: Read [ARCHITECTURE.md](ARCHITECTURE.md)
- **Backend README**: [backend/README.md](backend/README.md)

## 🎯 Common Tasks

### Add New Screen
```dart
// 1. Create file: lib/screens/new_screen.dart
// 2. Add route to HomeScreen navigation
// 3. Add provider if needed
// 4. Import and use
```

### Add New API Endpoint
```dart
// 1. Add method to service (lib/services/)
// 2. Call from provider (lib/providers/)
// 3. Update UI to use provider
```

### Test with Different GIF
1. Get GIF URL from Giphy search
2. Download manually or program it
3. Select in app Face Swap tab
4. Test swap with various face images

### Change UI Colors
**File**: `lib/main.dart`

```dart
colorScheme: ColorScheme.fromSeed(
  seedColor: Colors.purple,  // Change this
),
```

## 🚨 Error Messages

| Error | Cause | Solution |
|-------|-------|----------|
| "Backend not available" | Server not running | Start backend: `python3 main.py` |
| "No face detected" | No visible face | Use clearer image |
| "Network error" | No internet / wrong URL | Check connection & URL |
| "Face swap failed" | Processing error | Try smaller GIF |
| "No GIFs found" | Invalid API key | Update Giphy key |

## 🔐 Security Notes

- All processing is local (no cloud upload)
- Images not stored permanently
- Temp files auto-cleaned
- No external data transmission
- API keys only in local config

## 📞 Getting Help

1. Check [SETUP_GUIDE.md](SETUP_GUIDE.md) for detailed help
2. Review error message section above
3. Check backend logs: `python3 -u main.py`
4. Check Flutter logs: `flutter run -v`
5. Verify system requirements are met

## ✅ Before Reporting Issues

- [ ] Backend is running
- [ ] Flask shows "running on http://0.0.0.0:8000"
- [ ] API key is configured (not placeholder)
- [ ] GIF has visible faces
- [ ] Face image is clear
- [ ] Internet connection is working
- [ ] Using Python 3.10+
- [ ] Using Flutter 3.13+
