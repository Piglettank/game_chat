import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'animated_background.dart';
import 'navigation_helper.dart';

class WelcomeScreen extends StatefulWidget {
  final String chatId;
  final String userId;
  final String userName;

  static const String _appUrl = 'https://ff-game-chat.netlify.app';

  const WelcomeScreen({
    super.key,
    required this.chatId,
    required this.userId,
    required this.userName,
  });

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  BackgroundAnimationType _backgroundType = BackgroundAnimationType.floatingIcons;

  void _showQrCodeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Scan to Join',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16.0),
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: QrImageView(
                  data: WelcomeScreen._appUrl,
                  version: QrVersions.auto,
                  size: 200.0,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16.0),
              Text(
                WelcomeScreen._appUrl,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16.0),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        type: _backgroundType,
        child: Stack(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      const Spacer(),
                      Text(
                        'Welcome to Game Night',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.displayMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: MediaQuery.of(context).size.width < 600 ? 32 : null,
                            ),
                      ),
                      const SizedBox(height: 48.0),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            navigateWithUrlUpdate(context, '/tournament');
                          },
                          icon: const Icon(Icons.emoji_events),
                          label: const Text('Go to Leaderboard'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32.0,
                              vertical: 16.0,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            navigateWithUrlUpdate(context, '/brackets');
                          },
                          icon: const Icon(Icons.account_tree_outlined),
                          label: const Text('Go to Tournament'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32.0,
                              vertical: 16.0,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            navigateWithUrlUpdate(context, '/chat');
                          },
                          icon: const Icon(Icons.chat),
                          label: const Text('Go to Chat'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32.0,
                              vertical: 16.0,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    navigateWithUrlUpdate(context, '/edit-name');
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: const Color(0xFF00bcd4).withValues(alpha: 0.2),
                      border: Border.all(
                        color: const Color(0xFF00bcd4),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 20,
                      color: Color(0xFF00bcd4),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: BackgroundAnimationSelector(
                currentType: _backgroundType,
                onChanged: (type) {
                  setState(() {
                    _backgroundType = type;
                  });
                },
              ),
            ),
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: () => _showQrCodeDialog(context),
                        icon: const Icon(Icons.qr_code),
                        label: const Text('Share QR Code'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32.0,
                            vertical: 16.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
