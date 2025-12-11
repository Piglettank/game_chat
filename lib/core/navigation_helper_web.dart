import 'package:web/web.dart' as web;

/// Force update the browser URL using History API
void updateUrlWeb(String path) {
  // Use browser History API to update URL immediately
  // pushState updates the URL in the address bar without reloading the page
  
  // Ensure path starts with / for proper URL handling
  final url = path.startsWith('/') ? path : '/$path';
  
  // Push the new state to update the URL
  // state can be null, title can be empty string, url is the path
  // This immediately updates the browser's address bar
  web.window.history.pushState(null, '', url);
}
