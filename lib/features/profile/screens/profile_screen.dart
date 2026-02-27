import 'dart:io';

import 'package:bible_decision_simulator/core/di.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  static const _namePrefsKey = 'bds.profile.name';
  static const _emailPrefsKey = 'bds.profile.email';
  static const _phonePrefsKey = 'bds.profile.phone';
  static const _avatarPathPrefsKey = 'bds.profile.avatar_path';

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _picker = ImagePicker();

  XFile? _avatarFile;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final savedName = prefs.getString(_namePrefsKey) ?? '';
    final savedEmail = prefs.getString(_emailPrefsKey) ?? '';
    final savedPhone = prefs.getString(_phonePrefsKey) ?? '';
    final savedAvatarPath = prefs.getString(_avatarPathPrefsKey);

    XFile? savedAvatarFile;
    if (savedAvatarPath != null && savedAvatarPath.isNotEmpty) {
      final file = File(savedAvatarPath);
      if (file.existsSync()) {
        savedAvatarFile = XFile(savedAvatarPath);
      }
    }

    if (!mounted) return;
    setState(() {
      _nameController.text = savedName;
      _emailController.text = savedEmail;
      _phoneController.text = savedPhone;
      _avatarFile = savedAvatarFile;
    });
  }

  Future<void> _saveProfileData() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_namePrefsKey, _nameController.text.trim());
    await prefs.setString(_emailPrefsKey, _emailController.text.trim());
    await prefs.setString(_phonePrefsKey, _phoneController.text.trim());
    if (_avatarFile == null) {
      await prefs.remove(_avatarPathPrefsKey);
    } else {
      await prefs.setString(_avatarPathPrefsKey, _avatarFile!.path);
    }
  }

  Future<void> _openAvatarSourceSheet() async {
    final text = ref.read(uiTextProvider);
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(title: Text(text.chooseAvatarSourceTitle)),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(text.galleryOption),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: Text(text.cancel),
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || source == null) return;
    final granted = await _requestGalleryPermission();
    if (!mounted || !granted) return;
    try {
      final picked = await _picker.pickImage(source: source);
      if (!mounted || picked == null) return;
      setState(() {
        _avatarFile = picked;
      });
    } on PlatformException catch (error, stackTrace) {
      debugPrint(
          'ImagePicker PlatformException: ${error.code} ${error.message}');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      final message = error.code == 'photo_access_denied'
          ? 'Photo permission denied. Please allow Photos access in Settings.'
          : 'Cannot open photo library (${error.code}).';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (error, stackTrace) {
      debugPrint('ImagePicker unexpected error: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot open photo library.')),
      );
    }
  }

  Future<bool> _requestGalleryPermission() async {
    if (Platform.isIOS) {
      var status = await Permission.photos.status;
      if (status.isGranted || status.isLimited) return true;
      status = await Permission.photos.request();
      if (status.isGranted || status.isLimited) return true;
      _showPermissionDeniedMessage();
      return false;
    }

    if (Platform.isAndroid) {
      var status = await Permission.photos.status;
      if (status.isGranted) return true;
      status = await Permission.photos.request();
      if (status.isGranted) return true;

      status = await Permission.storage.status;
      if (status.isGranted) return true;
      status = await Permission.storage.request();
      if (status.isGranted) return true;

      _showPermissionDeniedMessage();
      return false;
    }

    return true;
  }

  void _showPermissionDeniedMessage() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Photo permission is required. Please allow access in Settings.',
        ),
        action: SnackBarAction(
          label: 'Settings',
          onPressed: openAppSettings,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = ref.watch(uiTextProvider);
    const avatarSize = 160.0;
    final avatarProvider =
        _avatarFile == null ? null : FileImage(File(_avatarFile!.path));

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      text.generateProfileTitle,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 20),
                    // Name
                    TextField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: text.yourNameLabel,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Email
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: text.yourEmailOptionalLabel,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Phone
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: text.yourPhoneOptionalLabel,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Avatar
                    Text(
                      text.yourAvatarLabel,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        width: avatarSize,
                        height: avatarSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline,
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: avatarProvider == null
                              ? Center(
                                  child: Icon(
                                    Icons.person,
                                    size: 72,
                                    color:
                                        Theme.of(context).colorScheme.outline,
                                  ),
                                )
                              : FittedBox(
                                  fit: BoxFit.cover,
                                  child: SizedBox(
                                    width: avatarSize,
                                    height: avatarSize,
                                    child: Image(
                                      image: avatarProvider,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _openAvatarSourceSheet,
                      icon: const Icon(Icons.upload_file),
                      label: Text(text.uploadAvatarButton),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () async {
                FocusScope.of(context).unfocus();
                await _saveProfileData();
                if (!context.mounted) return;
                final latestText = ref.read(uiTextProvider);
                await showDialog<void>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    content: Text(latestText.profileSavedSuccess),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: Text(latestText.ok),
                      ),
                    ],
                  ),
                );
              },
              child: Text(text.submit),
            ),
          ],
        ),
      ),
    );
  }
}
