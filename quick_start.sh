#!/bin/bash

# GiphyMe Quick Start Script

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "=========================================="
echo "GiphyMe - Face Swap App Quick Start"
echo "=========================================="
echo ""

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "❌ Error: Python 3 not found"
    echo "Please install Python 3.10+ from https://www.python.org/downloads/"
    exit 1
fi

echo "✓ Python found: $(python3 --version)"

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Error: Flutter not found"
    echo "Please install Flutter from https://flutter.dev/docs/get-started/install"
    exit 1
fi

echo "✓ Flutter found: $(flutter --version | head -1)"
echo ""

# Backend Setup
echo "=========================================="
echo "Setting up Backend..."
echo "=========================================="

cd "$SCRIPT_DIR/backend"

if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
fi

echo "Activating virtual environment..."
source venv/bin/activate

echo "Installing Python dependencies..."
pip install -q --upgrade pip
pip install -q -r requirements.txt

echo "✓ Backend ready!"
echo ""
echo "Starting FastAPI server..."
echo "Visit http://localhost:8000/health to check status"
echo ""

# Start backend in background
python3 main.py &
BACKEND_PID=$!

# Give backend time to start
sleep 3

# Check if backend is running
if ! kill -0 $BACKEND_PID 2>/dev/null; then
    echo "❌ Error: Backend failed to start"
    exit 1
fi

echo "✓ Backend running (PID: $BACKEND_PID)"
echo ""

# Frontend Setup
echo "=========================================="
echo "Setting up Frontend..."
echo "=========================================="

cd "$SCRIPT_DIR"

echo "Getting Flutter dependencies..."
flutter pub get -q

echo "✓ Frontend ready!"
echo ""

# Configuration Check
echo "=========================================="
echo "Configuration Check"
echo "=========================================="

if grep -q "YOUR_GIPHY_API_KEY_HERE" lib/config/constants.dart; then
    echo "⚠️  IMPORTANT: Giphy API key not configured!"
    echo "   Edit: lib/config/constants.dart"
    echo "   Get key from: https://developers.giphy.com/dashboard"
    echo ""
fi

echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "Backend is running on: http://localhost:8000"
echo ""
echo "To start the app, run:"
echo "  flutter run"
echo ""
echo "Press Ctrl+C to stop backend"
echo ""

# Wait for interrupt
wait $BACKEND_PID
