import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/user_storage.dart';
import 'animated_background.dart';
import 'welcome_screen.dart';

class NameEntryScreen extends StatefulWidget {
  final String chatId;

  const NameEntryScreen({
    super.key,
    required this.chatId,
  });

  @override
  State<NameEntryScreen> createState() => _NameEntryScreenState();
}

class _NameEntryScreenState extends State<NameEntryScreen> {
  final TextEditingController _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  BackgroundAnimationType _backgroundType = BackgroundAnimationType.floatingIcons;

  static const String _appUrl = 'https://ff-game-chat.netlify.app';

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _showQrCodeDialog() {
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
                  data: _appUrl,
                  version: QrVersions.auto,
                  size: 200.0,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16.0),
              Text(
                _appUrl,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
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

  Future<void> _submitName() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final userName = _nameController.text.trim();
    final userId = UserStorage.getUserId();

    await UserStorage.saveUser(userId, userName);

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => WelcomeScreen(
          chatId: widget.chatId,
          userId: userId,
          userName: userName,
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
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(
                          Icons.person_add,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 24.0),
                        Text(
                          'Welcome to Game Night',
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          'Enter your name to get started',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 48.0),
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Your Name',
                            hintText: 'Enter your name',
                            prefixIcon: const Icon(Icons.person),
                          ),
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submitName(),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your name';
                            }
                            if (value.trim().length < 2) {
                              return 'Name must be at least 2 characters';
                            }
                            if (value.trim().length > 50) {
                              return 'Name must be less than 50 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24.0),
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitName,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32.0,
                                vertical: 16.0,
                              ),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('Continue'),
                          ),
                        ),
                        const SizedBox(height: 48.0),
                        TextButton.icon(
                          onPressed: _showQrCodeDialog,
                          icon: const Icon(Icons.qr_code),
                          label: const Text('Share QR Code'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32.0,
                              vertical: 16.0,
                            ),
                          ),
                        ),
                      ],
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
          ],
        ),
      ),
    );
  }
}
