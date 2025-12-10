.PHONY: build help

# Default target
help:
	@echo "Available targets:"
	@echo "  make build    - Build Flutter web app and copy embed files"
	@echo "  make clean    - Clean Flutter build artifacts"
	@echo "  make serve    - Build and serve the web app locally on port 8080"

# Build Flutter web app and copy embed files
build:
	@echo "Building Flutter web app..."
	@./build_web.sh

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	@flutter clean

# Build and serve locally
serve: build
	@echo "Checking if port 8080 is available..."
	@if lsof -Pi :8080 -sTCP:LISTEN -t >/dev/null 2>&1 ; then \
		echo "Port 8080 is already in use. Killing existing process..."; \
		lsof -ti:8080 | xargs kill -9 2>/dev/null || true; \
		sleep 1; \
	fi
	@echo "Starting local server on http://localhost:8080..."
	@echo "Main app: http://localhost:8080/"
	@echo "Example page: http://localhost:8080/example.html"
	@cd build/web && python3 -m http.server 8080
