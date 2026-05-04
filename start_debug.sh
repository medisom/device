#!/bin/bash
flutter clean
flutter pub get
dart run flutter_launcher_icons
flutter build apk --release
adb install -r build/app/outputs/flutter-apk/app-release.apk
flutter logs
