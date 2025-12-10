/**
 * Game Chat Widget Embed Script
 * 
 * Usage:
 * <script src="https://your-domain.com/embed.js"></script>
 * <div id="game-chat-widget"></div>
 * <script>
 *   GameChat.init({
 *     containerId: 'game-chat-widget',
 *     widgetUrl: 'https://your-domain.com',
 *     chatId: 'my-chat-room',
 *     userId: 'user-123',
 *     userName: 'Player Name',
 *     width: '100%',
 *     height: '600px',
 *     firebase: {
 *       apiKey: 'your-api-key',
 *       authDomain: 'your-project.firebaseapp.com',
 *       projectId: 'your-project-id',
 *       storageBucket: 'your-project.appspot.com',
 *       messagingSenderId: '123456789',
 *       appId: '1:123456789:web:abc123',
 *       measurementId: 'G-XXXXXXXXXX'
 *     }
 *   });
 * </script>
 */

(function() {
  'use strict';

  window.GameChat = {
    instances: {},

    /**
     * Initialize a Game Chat widget instance
     * @param {Object} config - Configuration object
     * @param {string} config.containerId - ID of the container element
     * @param {string} config.widgetUrl - URL where the widget is hosted
     * @param {string} config.chatId - Chat room ID
     * @param {string} config.userId - User ID
     * @param {string} config.userName - User display name
     * @param {string} [config.width='100%'] - Widget width
     * @param {string} [config.height='600px'] - Widget height
     * @param {Object} [config.firebase] - Firebase configuration (optional, uses default if not provided)
     * @returns {string} Instance ID
     */
    init: function(config) {
      if (!config.containerId) {
        throw new Error('containerId is required');
      }
      if (!config.widgetUrl) {
        throw new Error('widgetUrl is required');
      }
      if (!config.chatId) {
        throw new Error('chatId is required');
      }
      if (!config.userId) {
        throw new Error('userId is required');
      }
      if (!config.userName) {
        throw new Error('userName is required');
      }

      var container = document.getElementById(config.containerId);
      if (!container) {
        throw new Error('Container element with id "' + config.containerId + '" not found');
      }

      var instanceId = 'game-chat-' + Date.now() + '-' + Math.random().toString(36).substr(2, 9);
      var width = config.width || '100%';
      var height = config.height || '600px';

      // Create iframe
      var iframe = document.createElement('iframe');
      iframe.id = instanceId;
      iframe.style.width = width;
      iframe.style.height = height;
      iframe.style.border = 'none';
      iframe.style.overflow = 'hidden';
      iframe.setAttribute('allow', 'microphone; camera');
      iframe.setAttribute('sandbox', 'allow-scripts allow-same-origin allow-forms');

      // Build URL with query parameters
      var url = new URL(config.widgetUrl);
      url.searchParams.set('chatId', config.chatId);
      url.searchParams.set('userId', config.userId);
      url.searchParams.set('userName', encodeURIComponent(config.userName));
      
      if (config.width && config.width !== '100%') {
        url.searchParams.set('width', config.width);
      }
      if (config.height && config.height !== '600px') {
        url.searchParams.set('height', config.height);
      }

      iframe.src = url.toString();

      // Store instance
      this.instances[instanceId] = {
        iframe: iframe,
        config: config
      };

      // Append iframe to container
      container.appendChild(iframe);

      // Send Firebase config via postMessage after iframe loads
      if (config.firebase) {
        iframe.onload = function() {
          iframe.contentWindow.postMessage({
            type: 'game-chat-config',
            chatId: config.chatId,
            userId: config.userId,
            userName: config.userName,
            firebase: config.firebase,
            width: width,
            height: height
          }, config.widgetUrl);
        };
      }

      return instanceId;
    },

    /**
     * Destroy a widget instance
     * @param {string} instanceId - Instance ID returned from init()
     */
    destroy: function(instanceId) {
      if (this.instances[instanceId]) {
        var iframe = this.instances[instanceId].iframe;
        if (iframe && iframe.parentNode) {
          iframe.parentNode.removeChild(iframe);
        }
        delete this.instances[instanceId];
      }
    },

    /**
     * Update configuration for an existing instance
     * @param {string} instanceId - Instance ID
     * @param {Object} updates - Partial configuration updates
     */
    update: function(instanceId, updates) {
      if (!this.instances[instanceId]) {
        throw new Error('Instance not found: ' + instanceId);
      }

      var instance = this.instances[instanceId];
      var config = Object.assign({}, instance.config, updates);

      // Reinitialize with new config
      var container = instance.iframe.parentNode;
      this.destroy(instanceId);
      return this.init(config);
    }
  };
})();
