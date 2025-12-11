.PHONY: build help

# Default target
help:
	@echo "Available targets:"
	@echo "  make build            - Build Flutter web app and copy embed files"
	@echo "  make clean            - Clean Flutter build artifacts"
	@echo "  make serve            - Build and serve the web app locally on port 8080"
	@echo "  make lan_server_start - Start Flutter web server on local network (0.0.0.0:8080)"
	@echo "  make lan_server_stop   - Stop the Flutter web server"

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

# Start Flutter web server on local network
lan_server_start:
	@echo "Checking if port 8080 is available..."
	@if lsof -Pi :8080 -sTCP:LISTEN -t >/dev/null 2>&1 ; then \
		echo "Port 8080 is already in use. Use 'make lan_server_stop' first."; \
		exit 1; \
	fi
	@echo "Starting Flutter web server on local network..."
	@echo "Server will be accessible at http://0.0.0.0:8080"
	@echo "Access from your phone: http://$$(ifconfig | grep 'inet ' | grep -v 127.0.0.1 | head -1 | awk '{print $$2}' | cut -d: -f2):8080"
	@echo "Press Ctrl+C to stop the server"
	@flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080

# Stop the Flutter web server
lan_server_stop:
	@echo "Stopping Flutter web server..."
	@if lsof -Pi :8080 -sTCP:LISTEN -t >/dev/null 2>&1 ; then \
		echo "Found process on port 8080, killing it..."; \
		lsof -ti:8080 | xargs kill -9 2>/dev/null || true; \
		sleep 1; \
		echo "Server stopped."; \
	else \
		echo "No server found running on port 8080."; \
	fi
	@echo "Killing any remaining Flutter processes..."
	@pkill -f "flutter run.*web-server" 2>/dev/null || true
