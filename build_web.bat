@echo off
REM Build Flutter web app
flutter build web --release

REM Copy embed files to build directory
copy web\embed.js build\web\
copy web\example.html build\web\

echo Build complete! Embed files copied to build\web\
