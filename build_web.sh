#!/bin/bash

# Build Flutter web app
flutter build web --release

# Copy embed files to build directory
cp web/embed.js build/web/
cp web/example.html build/web/

echo "Build complete! Embed files copied to build/web/"
