# Habit Tracker - Cross-Platform Running Guide

## Supported Platforms
- ✅ **Web** - Chrome, Edge, Safari
- ✅ **Android** - APK and Debug builds  
- ✅ **iOS** - Xcode project ready (requires macOS for building)

## Running the App

### Web Development
```bash
# Run web development server
flutter run -d chrome

# Or run with edge
flutter run -d edge
```

### Android Development
```bash
# Check connected Android devices
flutter devices

# Run on connected Android device
flutter run -d android

# Or build APK for manual installation
flutter build apk --debug
# Install: adb install build/app/outputs/flutter-apk/app-debug.apk
```

### iOS Development (macOS only)
```bash
# Run on iOS simulator (requires macOS)
flutter run -d ios

# Or build for App Store
flutter build ios
```

### Desktop Development
```bash
# Run on Windows desktop
flutter run -d windows

# Run on macOS desktop
flutter run -d macos

# Run on Linux desktop  
flutter run -d linux
```

## Platform-Specific Features

### Mobile (Android/iOS)
- ✅ Responsive mobile UI with large touch targets
- ✅ Mobile-optimized habit cards
- ✅ Large, accessible checkboxes
- ✅ Prominent date display
- ✅ Touch-friendly navigation

### Web/Desktop
- ✅ Desktop layout with full calendar grid
- ✅ Mouse-optimized interactions
- ✅ Keyboard navigation support
- ✅ Responsive design adapts to screen size

## Responsive Design
The app automatically detects screen size and adapts:
- **Mobile (< 600px)**: Card-based layout
- **Desktop (≥ 600px)**: Table-based layout

## Testing Different Screen Sizes
Use browser dev tools to test responsive behavior:
1. Open Chrome DevTools (F12)
2. Toggle device toolbar (Ctrl+Shift+M)
3. Select different device presets
4. Test mobile and desktop layouts

## Firebase Configuration
The app uses Firebase for:
- Authentication (Google Sign-In)
- Cloud Firestore for data storage
- Cloud Functions for AI features

Make sure Firebase is configured for each platform in `firebase_options.dart`.

## Troubleshooting
- **Android**: Ensure Android SDK is installed and device has USB debugging enabled
- **Web**: Use Chrome/Edge for best compatibility
- **iOS**: Requires macOS and Xcode for building
- **Responsive Issues**: Check MediaQuery breakpoints in `habit_grid.dart`
