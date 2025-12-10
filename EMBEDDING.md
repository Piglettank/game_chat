# Embedding Game Chat Widget

This document explains how to embed the Game Chat widget into your website.

## Quick Start

### Method 1: Using the Embed Script (Recommended)

1. Add the embed script to your HTML:

```html
<script src="https://your-domain.com/embed.js"></script>
```

2. Add a container element where you want the chat to appear:

```html
<div id="game-chat-widget"></div>
```

3. Initialize the widget:

```html
<script>
  GameChat.init({
    containerId: 'game-chat-widget',
    widgetUrl: 'https://your-domain.com',
    chatId: 'my-chat-room',
    userId: 'user-123',
    userName: 'Player Name',
    width: '100%',
    height: '600px'
  });
</script>
```

### Method 2: Direct iframe Embed

```html
<iframe 
  src="https://your-domain.com?chatId=my-chat-room&userId=user-123&userName=Player%20Name"
  width="100%"
  height="600px"
  frameborder="0"
  style="border: none;">
</iframe>
```

## Configuration Options

### Required Parameters

- `chatId` (string): Unique identifier for the chat room
- `userId` (string): Unique identifier for the current user
- `userName` (string): Display name for the current user

### Optional Parameters

- `width` (string): Widget width (default: '100%')
- `height` (string): Widget height (default: '600px')
- `firebase` (object): Custom Firebase configuration (see below)

### Custom Firebase Configuration

If you want to use your own Firebase project instead of the default:

```javascript
GameChat.init({
  containerId: 'game-chat-widget',
  widgetUrl: 'https://your-domain.com',
  chatId: 'my-chat-room',
  userId: 'user-123',
  userName: 'Player Name',
  firebase: {
    apiKey: 'your-api-key',
    authDomain: 'your-project.firebaseapp.com',
    projectId: 'your-project-id',
    storageBucket: 'your-project.appspot.com',
    messagingSenderId: '123456789',
    appId: '1:123456789:web:abc123',
    measurementId: 'G-XXXXXXXXXX'
  }
});
```

## API Reference

### `GameChat.init(config)`

Initializes a new chat widget instance.

**Parameters:**
- `config` (object): Configuration object (see above)

**Returns:** Instance ID (string)

**Example:**
```javascript
var instanceId = GameChat.init({
  containerId: 'game-chat-widget',
  widgetUrl: 'https://your-domain.com',
  chatId: 'my-chat-room',
  userId: 'user-123',
  userName: 'Player Name'
});
```

### `GameChat.destroy(instanceId)`

Removes a widget instance from the page.

**Parameters:**
- `instanceId` (string): Instance ID returned from `init()`

**Example:**
```javascript
GameChat.destroy(instanceId);
```

### `GameChat.update(instanceId, updates)`

Updates configuration for an existing instance.

**Parameters:**
- `instanceId` (string): Instance ID
- `updates` (object): Partial configuration updates

**Returns:** New instance ID (string)

**Example:**
```javascript
GameChat.update(instanceId, {
  userName: 'New Player Name',
  height: '800px'
});
```

## Building for Production

1. Build the Flutter web app:
```bash
flutter build web --release
```

2. Deploy the contents of `build/web/` to your hosting service

3. Make sure `embed.js` is accessible at the root of your deployment

## Security Considerations

- The widget uses iframe sandboxing for security
- Make sure your Firebase security rules are properly configured
- Consider implementing authentication if needed
- Use HTTPS for production deployments

## Browser Support

- Chrome/Edge (latest)
- Firefox (latest)
- Safari (latest)
- Mobile browsers (iOS Safari, Chrome Mobile)
