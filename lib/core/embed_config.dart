import 'dart:math';
import 'package:firebase_core/firebase_core.dart';

class EmbedConfig {
  final String chatId;
  final String userId;
  final String userName;
  final FirebaseOptions? firebaseOptions;
  final String? widgetUrl;
  final double? width;
  final double? height;

  EmbedConfig({
    required this.chatId,
    required this.userId,
    required this.userName,
    this.firebaseOptions,
    this.widgetUrl,
    this.width,
    this.height,
  });

  static final List<String> _randomUserNames = [
    'Squirrel Lord',
    'Dancing Pickle',
    'Lord Snuggles',
    'Wizard of Oz',
    'Cornhole Champion',
    'Pickle Rick',
    'Captain Obvious',
    'Sir Lancelot',
    'The Mighty Duck',
    'Flying Penguin',
    'Banana Split',
    'Cream Puff',
    'Bread',
    'El Más Grande',
    'Hungry Hippo',
    'Pippi Longstocking',
    'Joker',
    'Bamse',
    'Laban',
    'Finn the Human',
    'Spongebob',
    'Pikachu',
    'Mario',
    'Link',
    'Kirby',
  ];

  static String _generateRandomUserId() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomNum = random.nextInt(10000);
    return 'user-$timestamp-$randomNum';
  }

  static String _getRandomUserName() {
    final random = Random();
    return _randomUserNames[random.nextInt(_randomUserNames.length)];
  }

  static EmbedConfig fromUrlParams() {
    // Get URL parameters
    final uri = Uri.base;
    final params = uri.queryParameters;

    return EmbedConfig(
      chatId: params['chatId'] ?? 'main-chat',
      userId: params['userId'] ?? _generateRandomUserId(),
      userName: params['userName'] ?? _getRandomUserName(),
      width: params['width'] != null ? double.tryParse(params['width']!) : null,
      height: params['height'] != null
          ? double.tryParse(params['height']!)
          : null,
    );
  }

  static EmbedConfig fromJson(Map<String, dynamic> json) {
    FirebaseOptions? firebaseOptions;

    if (json['firebase'] != null) {
      final firebaseJson = json['firebase'] as Map<String, dynamic>;
      firebaseOptions = FirebaseOptions(
        apiKey: firebaseJson['apiKey'] as String? ?? '',
        appId: firebaseJson['appId'] as String? ?? '',
        messagingSenderId: firebaseJson['messagingSenderId'] as String? ?? '',
        projectId: firebaseJson['projectId'] as String? ?? '',
        authDomain: firebaseJson['authDomain'] as String?,
        storageBucket: firebaseJson['storageBucket'] as String?,
        measurementId: firebaseJson['measurementId'] as String?,
      );
    }

    return EmbedConfig(
      chatId: json['chatId'] as String? ?? 'main-chat',
      userId: json['userId'] as String? ?? _generateRandomUserId(),
      userName: json['userName'] as String? ?? _getRandomUserName(),
      firebaseOptions: firebaseOptions,
      widgetUrl: json['widgetUrl'] as String?,
      width: json['width'] != null ? (json['width'] as num).toDouble() : null,
      height: json['height'] != null
          ? (json['height'] as num).toDouble()
          : null,
    );
  }
}
