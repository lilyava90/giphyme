# GiphyMe Face Swap Backend

Face swapping backend service for GiphyMe using InsightFace and MediaPipe.

## Setup

1. **Install Python 3.10+**
```bash
python --version  # Should be 3.10 or higher
```

2. **Create virtual environment**
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

3. **Install dependencies**
```bash
pip install -r requirements.txt
```

Note: First run will download required models (~500MB):
- `buffalo_l`: Face detection and embedding model
- `inswapper_128.onnx`: Face swapping model

4. **Run the server**
```bash
python main.py
```

Server will start at `http://localhost:8000`

## API Endpoints

### Health Check
```
GET /health
```

### Face Swap
```
POST /swap-face
Content-Type: multipart/form-data

Parameters:
- gif_file: GIF file (binary)
- face_image: Face image to swap (PNG/JPG)

Returns: Processed GIF with swapped faces
```

## API Usage Example (cURL)
```bash
curl -X POST http://localhost:8000/swap-face \
  -F "gif_file=@input.gif" \
  -F "face_image=@face.jpg" \
  -o output.gif
```

## Troubleshooting

**Memory Issues:** If you run out of memory, process smaller GIFs first or reduce resolution.

**Model Download Issues:** Models are auto-downloaded on first run. Ensure internet connection.

**Face Detection Failed:** The image must have a clear, visible face. Try different angles.

## Notes

- Processing time depends on GIF size and number of frames
- Typical small GIF (~200 frames, 300x300): 30-60 seconds
- Requires CPU only (GPU optional, not necessary)
