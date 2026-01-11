# GiphyMe Testing Guide

Complete step-by-step instructions to test the entire GiphyMe face swap application.

## Pre-Testing Checklist

- [ ] Python 3.10+ installed (`python3 --version`)
- [ ] Flutter installed (`flutter --version`)
- [ ] Giphy API key obtained (https://developers.giphy.com)
- [ ] Project cloned to `/Users/ava/development/my_projects/giphyme`
- [ ] No other services using port 8000

---

## Phase 1: Backend Testing

### Test 1.1: Python Environment Setup

**Expected Duration**: 5 minutes

**Steps**:
```bash
# Navigate to backend
cd /Users/ava/development/my_projects/giphyme/backend

# Create virtual environment
python3 -m venv venv

# Activate it
source venv/bin/activate

# Verify activation (should show (venv) prefix)
which python
```

**Expected Output**:
```
/Users/ava/development/my_projects/giphyme/backend/venv/bin/python
```

**Pass**: ✅ Shows venv python path

### Test 1.2: Install Dependencies

**Expected Duration**: 10-20 minutes (first time is slower)

**Steps**:
```bash
# Already in backend/ with venv activated
pip install --upgrade pip
pip install -r requirements.txt
```

**Expected Output**:
```
Successfully installed fastapi-... opencv-python-... insightface-...
```

**Pass**: ✅ All packages installed without errors

### Test 1.3: Model Download & Verification

**Expected Duration**: 5-10 minutes

**Steps**:
```bash
# Start backend (will download models on first run)
python3 main.py
```

**Expected Output**:
```
INFO:     Application startup complete
INFO:     Uvicorn running on http://0.0.0.0:8000 (Press CTRL+C to quit)
```

**Verify**: Open new terminal and test health endpoint:
```bash
curl http://localhost:8000/health
```

**Expected Response**:
```json
{"status": "healthy", "models_loaded": true}
```

**Pass**: ✅ Server running and models loaded

**Important**: Keep terminal open for next tests

### Test 1.4: Models Downloaded

**Expected Duration**: 1 minute

**Steps**:
```bash
# In new terminal (not the one running the server)
ls -lah ~/.insightface/models/
```

**Expected Output** (should have 2 directories):
```
buffalo_l/          # Face detection model
inswapper_128.onnx  # Face swap model
```

**Pass**: ✅ Both models present

### Test 1.5: API Error Handling

**Expected Duration**: 2 minutes

**Steps**:
```bash
# Test with invalid file (should fail gracefully)
curl -X POST http://localhost:8000/swap-face \
  -F "gif_file=@nonexistent.gif" \
  -F "face_image=@nonexistent.jpg"
```

**Expected Output**: Error response (not server crash)
```
{"detail": "No face detected..."}
```

**Pass**: ✅ API returns proper error, doesn't crash

---

## Phase 2: Frontend Testing

### Test 2.1: Flutter Dependencies

**Expected Duration**: 5-10 minutes

**Steps**:
```bash
# New terminal (NOT backend terminal)
cd /Users/ava/development/my_projects/giphyme

# Get dependencies
flutter pub get
```

**Expected Output**:
```
Running "flutter pub get" in giphyme...
... 
Got dependencies!
```

**Pass**: ✅ No version conflicts, all packages installed

### Test 2.2: Configure Giphy API Key

**Expected Duration**: 2 minutes

**Steps**:
1. Go to https://developers.giphy.com/dashboard
2. Create app if needed, get API key
3. Edit `lib/config/constants.dart`:

```dart
const String GIPHY_API_KEY = 'YOUR_ACTUAL_KEY_HERE';  // Replace!
const String BACKEND_URL = 'http://localhost:8000';   // Verify correct
```

**Pass**: ✅ Key is non-empty and real

### Test 2.3: App Launch

**Expected Duration**: 3-5 minutes

**Steps**:
```bash
# Still in /Users/ava/development/my_projects/giphyme
# Ensure backend is still running in other terminal
flutter run
```

**Expected Output**:
```
Building flutter app...
...
Launching lib/main.dart on iPhone 15 Pro in debug mode...
```

**Pass**: ✅ App opens, no build errors

### Test 2.4: Verify Home Screen

**Expected Duration**: 1 minute

**Expected**:
- App shows "GiphyMe - Face Swap" title
- Two navigation tabs: "Search GIFs" and "Face Swap"
- Bottom navigation bar shows both tabs
- No error messages

**Pass**: ✅ UI renders correctly

### Test 2.5: Test GIF Search

**Expected Duration**: 2 minutes

**Steps**:
1. Ensure "Search GIFs" tab is active
2. Type "dancing" in search box
3. Press Enter or wait for auto-search

**Expected**:
- Grid of GIFs appears
- Each GIF shows thumbnail and title
- No loading spinner (search complete)

**Pass**: ✅ Giphy API working, GIFs display

**Troubleshoot if fails**:
- Check Giphy API key in constants.dart
- Verify internet connection
- Check backend health: `curl http://localhost:8000/health`

### Test 2.6: Test Backend Connection

**Expected Duration**: 1 minute

**Steps**:
1. Switch to "Face Swap" tab
2. Look at top status bar

**Expected**:
- Green checkmark with "Backend connected"

**Troubleshoot if shows red/error**:
- Verify backend is running: `python3 main.py` in other terminal
- Check backend URL in `lib/config/constants.dart`
- Ensure localhost:8000 is accessible

**Pass**: ✅ Status shows connected

---

## Phase 3: End-to-End Face Swap Testing

### Test 3.1: Prepare Test Files

**Expected Duration**: 5 minutes

**Steps**:
1. Find a test GIF (small, with faces)
   - Download from web or use existing
   - Size: < 1MB recommended
   - Example search: "celebration.gif"

2. Take a face photo
   - Clear front-facing photo
   - Good lighting
   - Save as JPG/PNG
   - Just your face in frame

**Files needed**:
- `test_input.gif` - Small animated GIF with faces
- `test_face.jpg` - Clear photo of a face

**Pass**: ✅ Both files ready

### Test 3.2: Select GIF

**Expected Duration**: 2 minutes

**Steps**:
1. In "Face Swap" tab
2. Tap "Step 1: Select GIF"
3. Select your test GIF file
4. Verify filename appears

**Expected**:
- Container shows checkmark icon
- Filename displayed
- "GIF Selected" text visible

**Pass**: ✅ GIF selected and displayed

### Test 3.3: Select Face Image

**Expected Duration**: 2 minutes

**Steps**:
1. Still in "Face Swap" tab
2. Tap "Step 2: Select Face Image"
3. Select your test face image
4. Verify thumbnail appears

**Expected**:
- Face image thumbnail displayed
- Clear preview of selected photo
- Close button (X) to deselect

**Pass**: ✅ Face image selected and previewed

### Test 3.4: Check Ready State

**Expected Duration**: 1 minute

**Expected**:
- "Swap Face" button is enabled (blue, clickable)
- Backend status still shows connected
- No error messages

**Pass**: ✅ App ready to process

### Test 3.5: Execute Face Swap

**Expected Duration**: 1-2 minutes (plus processing time)

**Steps**:
1. Tap "Swap Face" button
2. Observe loading spinner
3. Wait for completion message

**Expected during processing**:
- Spinner animation in button
- Progress message
- Backend terminal shows logs:
  ```
  Detecting faces...
  Processing frame 1/N...
  ...
  GIF saved successfully
  ```

**Processing time**:
- Small GIF (100 frames): 30-60 seconds
- Medium GIF (200 frames): 1-2 minutes
- **Don't interrupt, let it complete**

**Pass**: ✅ Completes without crashing

### Test 3.6: Verify Result

**Expected Duration**: 2 minutes

**Expected after completion**:
- Green success box with checkmark
- Message: "Success!"
- File path displayed (e.g., `/Users/ava/.../swapped_1234567890.gif`)
- "Start Over" button available

**Pass**: ✅ Face swap completed successfully

### Test 3.7: Verify Output File

**Expected Duration**: 2 minutes

**Steps**:
```bash
# In new terminal
open ~/Documents/giphyme/

# Or check file exists
ls -lh ~/Documents/giphyme/swapped_*.gif
```

**Expected**:
- GIF file exists
- File size reasonable (similar to input)
- File is readable

**Pass**: ✅ Output file created and accessible

---

## Phase 4: Advanced Testing

### Test 4.1: Multiple Faces in GIF

**Expected Duration**: 5 minutes

**Steps**:
1. Get a GIF with 2+ visible faces
2. Select face image
3. Run swap

**Expected**:
- All faces swapped (not just first)
- Processing takes longer
- Final GIF shows multiple swaps

**Pass**: ✅ All faces swapped correctly

### Test 4.2: No Faces in GIF

**Expected Duration**: 3 minutes

**Steps**:
1. Use a GIF without faces (landscape, object, etc.)
2. Try to swap

**Expected**:
- Processing completes
- Output GIF unchanged (no faces to swap)
- No error shown

**Pass**: ✅ Handles gracefully

### Test 4.3: Poor Quality Face Image

**Expected Duration**: 3 minutes

**Steps**:
1. Use blurry or low-light face photo
2. Try to swap

**Expected**:
- Error: "No face detected in image"
- Or: Poor quality swap result

**Pass**: ✅ Proper error handling or degraded result

### Test 4.4: Large GIF

**Expected Duration**: 10+ minutes

**Steps**:
1. Get GIF with 500+ frames (> 5MB)
2. Try to swap

**Expected**:
- Processing takes significant time (5-10 min)
- Progress updates visible
- Completes without out-of-memory crash

**Pass**: ✅ Handles large files

### Test 4.5: Network Interruption

**Expected Duration**: 5 minutes

**Steps**:
1. Stop backend: Ctrl+C in backend terminal
2. Try to run face swap
3. Observe error

**Expected**:
- Red error box appears
- Error message: "Backend not available" or network error
- App doesn't crash

**Pass**: ✅ Graceful error handling

### Test 4.6: Concurrent Requests

**Expected Duration**: 5 minutes

**Steps**:
1. Start first swap
2. Quickly click "Swap Face" again before first completes
3. Observe behavior

**Expected**:
- Second request queued (or prevented)
- Button disabled during processing
- No duplicate processing

**Pass**: ✅ Prevents race conditions

---

## Phase 5: Performance Testing

### Test 5.1: Startup Time

**Expected Duration**: 2 minutes

**Steps**:
1. `flutter run` time from command to app visible

**Expected**: < 10 seconds

**Pass**: ✅ If < 10 seconds

### Test 5.2: Search Response Time

**Expected Duration**: 2 minutes

**Steps**:
1. Type search query
2. Time until GIFs appear

**Expected**: < 5 seconds

**Pass**: ✅ If < 5 seconds

### Test 5.3: Memory Usage

**Expected Duration**: 3 minutes

**Steps** (on macOS):
```bash
# During face swap processing
top -l 1 | grep "python\|flutter"
```

**Expected**: Memory usage stays reasonable
- Python: < 2GB
- Flutter: < 500MB

**Pass**: ✅ No memory leaks

### Test 5.4: Backend Response Time

**Expected Duration**: 3 minutes

**Steps**:
```bash
# Time a health check
time curl http://localhost:8000/health
```

**Expected**: < 0.5 seconds

**Pass**: ✅ If < 0.5 seconds

---

## Phase 6: Cleanup & Report

### Test 6.1: Clean Up Test Files

**Steps**:
```bash
# Remove test output GIFs
rm ~/Documents/giphyme/swapped_*.gif
```

### Test 6.2: Stop Services

**Steps**:
```bash
# Stop backend (in backend terminal): Ctrl+C
# Stop app (in flutter terminal): q
```

### Test 6.3: Generate Test Report

**Create a summary**:

```markdown
## GiphyMe Test Report - [DATE]

### Environment
- Python: [version]
- Flutter: [version]
- macOS: [version]

### Test Results Summary
- Phase 1 (Backend): ✅ PASSED / ❌ FAILED
- Phase 2 (Frontend): ✅ PASSED / ❌ FAILED
- Phase 3 (E2E): ✅ PASSED / ❌ FAILED
- Phase 4 (Advanced): ✅ PASSED / ❌ FAILED
- Phase 5 (Performance): ✅ PASSED / ❌ FAILED

### Issues Found
[List any issues]

### Recommendations
[Any improvements needed]
```

---

## Quick Test Checklist

For quick testing (< 10 minutes):

- [ ] Backend starts: `python3 main.py` shows "Uvicorn running"
- [ ] Health check passes: `curl http://localhost:8000/health` returns 200
- [ ] App launches: `flutter run` shows app without errors
- [ ] GIF search works: Type query, GIFs appear
- [ ] Face swap works: Select GIF + face, tap swap, get result
- [ ] Output saved: File exists in ~/Documents/giphyme/

---

## Troubleshooting During Testing

| Problem | Diagnosis | Solution |
|---------|-----------|----------|
| App won't launch | Flutter error | `flutter clean && flutter pub get` |
| Backend won't start | Python error | Check Python version, reinstall requirements |
| No GIFs show | API error | Verify Giphy key, check internet |
| Backend unavailable | Server down | Restart `python3 main.py` |
| Face swap hangs | Processing stuck | Check memory, try smaller GIF |
| Poor quality result | Input quality | Use better face photo |

---

## Success Criteria

All tests should pass with:
- ✅ No crashes
- ✅ Expected output/behavior
- ✅ Proper error handling
- ✅ Reasonable performance

If all phases pass, the app is ready for use!
