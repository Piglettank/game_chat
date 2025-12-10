# Game Night

An embeddable Flutter chat widget that can be integrated into any website.

## Building for Web

To build the web app and automatically copy embed files:

**macOS/Linux:**
```bash
./build_web.sh
```

**Windows:**
```bash
build_web.bat
```

This will:
1. Build the Flutter web app (`flutter build web --release`)
2. Automatically copy `embed.js` and `example.html` to `build/web/`

Alternatively, you can build manually:
```bash
flutter build web --release
cp web/embed.js build/web/
cp web/example.html build/web/
```

## Embedding

See [EMBEDDING.md](EMBEDDING.md) for detailed instructions on how to embed the widget into other websites.
