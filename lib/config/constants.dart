// API Configuration
// Get your Giphy API key at: https://developers.giphy.com/

const String GIPHY_API_KEY = 'W6o9fJJuJzsH3dmknjTTbhVRjANCajK9';

// Backend URL - Change this to your backend server URL
// For local development: http://localhost:8000
// For testing on iPhone: Use your Mac's IP address
// For production: https://your-backend-server.com
// You can override at build time:
// flutter run --dart-define=BACKEND_URL=https://api.yourdomain.com
const String BACKEND_URL = String.fromEnvironment(
  'BACKEND_URL',
  defaultValue: 'http://192.168.68.69:8000',
);

// App Configuration
const String APP_NAME = 'GiphyMe';
const String APP_VERSION = '1.0.0';
