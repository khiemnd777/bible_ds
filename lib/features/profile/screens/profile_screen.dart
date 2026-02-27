import 'dart:io';

import 'package:bible_decision_simulator/core/di.dart';
import 'package:bible_decision_simulator/features/profile/providers/profile_avatar_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
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
    final savedAvatarRef = prefs.getString(profileAvatarPathPrefsKey);
    debugPrint('Profile load avatar ref=$savedAvatarRef');

    XFile? savedAvatarFile;
    if (savedAvatarRef != null && savedAvatarRef.isNotEmpty) {
      final resolvedPath = await _resolveAvatarPath(savedAvatarRef);
      if (resolvedPath != null) {
        savedAvatarFile = XFile(resolvedPath);
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
      await prefs.remove(profileAvatarPathPrefsKey);
    } else {
      final avatarName = _fileNameFromPath(_avatarFile!.path);
      await prefs.setString(profileAvatarPathPrefsKey, avatarName);
      debugPrint('Profile save avatar ref=$avatarName');
    }
    ref.invalidate(profileAvatarPathProvider);
  }

  Future<String> _persistAvatarFile(XFile sourceFile) async {
    final docsDir = await getApplicationDocumentsDirectory();
    await docsDir.create(recursive: true);
    final extensionIndex = sourceFile.path.lastIndexOf('.');
    final extension = extensionIndex > -1
        ? sourceFile.path.substring(extensionIndex)
        : '.jpg';
    final targetPath = '${docsDir.path}/profile_avatar$extension';
    if (sourceFile.path == targetPath) return sourceFile.path;
    final targetFile = File(targetPath);
    if (targetFile.existsSync()) {
      await targetFile.delete();
    }
    final copiedFile = await File(sourceFile.path).copy(targetPath);
    return copiedFile.path;
  }

  Future<String?> _resolveAvatarPath(String savedRef) async {
    final docsDir = await getApplicationDocumentsDirectory();

    // Backward compatibility: old data stored absolute paths.
    if (savedRef.contains('/')) {
      final legacyFile = File(savedRef);
      if (legacyFile.existsSync()) return savedRef;

      final migratedName = _fileNameFromPath(savedRef);
      final migratedPath = '${docsDir.path}/$migratedName';
      if (File(migratedPath).existsSync()) return migratedPath;
      return null;
    }

    final currentPath = '${docsDir.path}/$savedRef';
    if (File(currentPath).existsSync()) return currentPath;
    return null;
  }

  String _fileNameFromPath(String path) {
    final slash = path.lastIndexOf('/');
    if (slash < 0 || slash == path.length - 1) return path;
    return path.substring(slash + 1);
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
      final persistedPath = await _persistAvatarFile(picked);
      final avatarName = _fileNameFromPath(persistedPath);
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setString(profileAvatarPathPrefsKey, avatarName);
      ref.invalidate(profileAvatarPathProvider);
      debugPrint('Profile picked avatar persisted path=$persistedPath');
      if (!mounted) return;
      setState(() {
        _avatarFile = XFile(persistedPath);
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
    final avatarPath = _avatarFile?.path;
    final avatarExists = avatarPath != null && File(avatarPath).existsSync();
    assert(() {
      debugPrint(
        'ProfileScreen avatar file exists=$avatarExists path=$avatarPath',
      );
      return true;
    }());
    final avatarProvider = avatarExists ? FileImage(File(avatarPath)) : null;

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
