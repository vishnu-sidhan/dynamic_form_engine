import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dynamic_form_engine/dynamic_form_engine.dart';

/// Platform handlers integrating real device GPS and file/image pickers into the example showcase.
class ExamplePlatformHandlers {
  const ExamplePlatformHandlers._();

  /// Whether the current runtime platform is Android or iOS mobile.
  static bool get isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Captures current GPS coordinates using the [geolocator] package.
  static Future<String?> captureGpsPosition(
    BuildContext context,
    FormFieldDefinition field,
  ) async {
    try {
      final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isServiceEnabled) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Location services are disabled on this device.'),
              backgroundColor: Colors.orange,
              action: SnackBarAction(
                label: 'Settings',
                textColor: Colors.white,
                onPressed: () => Geolocator.openLocationSettings(),
              ),
            ),
          );
        }
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location permission denied.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Location permissions are permanently denied. Please enable them in app settings.',
              ),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'Settings',
                textColor: Colors.white,
                onPressed: () => Geolocator.openAppSettings(),
              ),
            ),
          );
        }
        return null;
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Acquiring GPS coordinates...'),
            duration: Duration(seconds: 1),
          ),
        );
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 8),
          ),
        );
      } catch (_) {
        // Fallback to last known position if real-time satellite fix times out (e.g. emulators)
        position = await Geolocator.getLastKnownPosition();
      }

      if (position == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Unable to acquire GPS fix. Please verify location settings or emulator GPS coordinates.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return null;
      }

      final lat = position.latitude.toStringAsFixed(6);
      final lng = position.longitude.toStringAsFixed(6);
      final acc = position.accuracy.toStringAsFixed(1);
      final result = '$lat, $lng (±${acc}m)';

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('GPS captured: $result'),
            backgroundColor: Colors.green,
          ),
        );
      }

      return result;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('GPS capture error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  /// Picks media files (images, videos, documents) using [image_picker] and [file_picker].
  static Future<String?> pickMedia(
    BuildContext context,
    FormFieldDefinition field,
  ) async {
    try {
      if (field.fieldType == FormFieldType.image ||
          field.fieldType == FormFieldType.media) {
        return await _pickImage(context);
      } else if (field.fieldType == FormFieldType.video) {
        return await _pickVideo(context);
      } else {
        return await _pickDocument(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Media picker error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  static Future<String?> _pickImage(BuildContext context) async {
    if (isMobile) {
      final ImageSource? source = await showModalBottomSheet<ImageSource>(
        context: context,
        showDragHandle: true,
        builder: (ctx) {
          final theme = Theme.of(ctx);
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Select Image Source',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.photo_camera_rounded),
                    ),
                    title: const Text('Take Photo with Camera'),
                    subtitle: const Text('Capture using device camera'),
                    onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
                  ),
                  ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.photo_library_rounded),
                    ),
                    title: const Text('Photo Gallery'),
                    subtitle: const Text('Select an existing photo'),
                    onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
                  ),
                ],
              ),
            ),
          );
        },
      );

      // User dismissed sheet
      if (source == null) return null;

      final picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (photo != null) {
        final length = await photo.length();
        final sizeKb = (length / 1024).toStringAsFixed(1);
        return '${photo.name} ($sizeKb KB)';
      }
      return null;
    } else {
      // Desktop and Web platforms use native file chooser
      final files = await FilePickerPlatform.instance.pickFiles(
        type: FileType.image,
      );
      if (files.isNotEmpty) {
        final file = files.first;
        final length = await file.xFile.length();
        final sizeKb = (length / 1024).toStringAsFixed(1);
        return '${file.name} ($sizeKb KB)';
      }
      return null;
    }
  }

  static Future<String?> _pickVideo(BuildContext context) async {
    if (isMobile) {
      final ImageSource? source = await showModalBottomSheet<ImageSource>(
        context: context,
        showDragHandle: true,
        builder: (ctx) {
          final theme = Theme.of(ctx);
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Select Video Source',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.videocam_rounded),
                    ),
                    title: const Text('Record Video with Camera'),
                    subtitle: const Text('Capture using device camera'),
                    onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
                  ),
                  ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.video_library_rounded),
                    ),
                    title: const Text('Video Library'),
                    subtitle: const Text('Select an existing video'),
                    onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
                  ),
                ],
              ),
            ),
          );
        },
      );

      if (source == null) return null;

      final picker = ImagePicker();
      final XFile? video = await picker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 5),
      );

      if (video != null) {
        final length = await video.length();
        final sizeMb = (length / (1024 * 1024)).toStringAsFixed(2);
        return '${video.name} ($sizeMb MB)';
      }
      return null;
    } else {
      // Desktop and Web platforms
      final files = await FilePickerPlatform.instance.pickFiles(
        type: FileType.video,
      );
      if (files.isNotEmpty) {
        final file = files.first;
        final length = await file.xFile.length();
        final sizeMb = (length / (1024 * 1024)).toStringAsFixed(2);
        return '${file.name} ($sizeMb MB)';
      }
      return null;
    }
  }

  static Future<String?> _pickDocument(BuildContext context) async {
    final files = await FilePickerPlatform.instance.pickFiles(
      type: FileType.any,
    );

    if (files.isNotEmpty) {
      final file = files.first;
      final length = await file.xFile.length();
      final sizeKb = (length / 1024).toStringAsFixed(1);
      return '${file.name} ($sizeKb KB)';
    }
    return null;
  }
}

/// Registers device GPS, camera, and file pickers onto a [FieldRendererRegistry] (or global if omitted).
void registerExamplePlatformHandlers([FieldRendererRegistry? targetRegistry]) {
  final registry = targetRegistry ?? FieldRendererRegistry.global;

  Widget locationBuilder(
    BuildContext ctx,
    FormFieldDefinition f,
    FormFlowController c,
  ) {
    return LocationFieldRenderer(
      field: f,
      controller: c,
      onCaptureLocation: ExamplePlatformHandlers.captureGpsPosition,
    );
  }

  registry.register(FormFieldType.gps, locationBuilder);
  registry.register(FormFieldType.gpsLocation, locationBuilder);
  registry.register(FormFieldType.location, locationBuilder);

  Widget mediaBuilder(
    BuildContext ctx,
    FormFieldDefinition f,
    FormFlowController c,
  ) {
    return MediaFieldRenderer(
      field: f,
      controller: c,
      onPickMedia: ExamplePlatformHandlers.pickMedia,
    );
  }

  registry.register(FormFieldType.image, mediaBuilder);
  registry.register(FormFieldType.video, mediaBuilder);
  registry.register(FormFieldType.document, mediaBuilder);
  registry.register(FormFieldType.media, mediaBuilder);
}

/// Factory function to create a fully functional [FieldRendererRegistry]
/// wired with real GPS and file/image picker handlers for the showcase app.
FieldRendererRegistry createFunctionalExampleRegistry() {
  final registry = FieldRendererRegistry();
  registerExamplePlatformHandlers(registry);
  return registry;
}
