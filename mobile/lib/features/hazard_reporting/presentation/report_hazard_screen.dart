import 'dart:io';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:guardianroute/features/hazard_reporting/data/hazard_report_repository.dart';
import 'package:guardianroute/features/hazard_reporting/presentation/hazard_report_providers.dart';
import 'package:guardianroute/features/map/presentation/map_providers.dart';

class ReportHazardScreen extends ConsumerStatefulWidget {
  const ReportHazardScreen({super.key});

  @override
  ConsumerState<ReportHazardScreen> createState() => _ReportHazardScreenState();
}

class _ReportHazardScreenState extends ConsumerState<ReportHazardScreen> {
  final _picker = ImagePicker();
  final _recorder = AudioRecorder();
  final _transcriptController = TextEditingController();

  File? _imageFile;
  File? _audioFile;
  bool _recording = false;
  bool _submitting = false;
  bool _pickingImage = false;
  Future<PermissionStatus>? _permissionRequestInFlight;
  String? _error;
  String? _locationLabel;

  @override
  void initState() {
    super.initState();
    FirebaseAnalytics.instance.logEvent(name: 'hazard_report_started');
    _captureLocationLabel();
  }

  @override
  void dispose() {
    _transcriptController.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _captureLocationLabel() async {
    try {
      final position = await ref.read(locationServiceProvider).getCurrentPosition();
      setState(() {
        _locationLabel =
            '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
      });
    } catch (e) {
      setState(() => _locationLabel = 'Location unavailable');
    }
  }

  Future<bool> _requestPermission(Permission permission) async {
    var status = await permission.status;
    if (status.isGranted || status.isLimited) {
      return true;
    }
    if (status.isPermanentlyDenied || status.isRestricted) {
      return false;
    }

    if (_permissionRequestInFlight != null) {
      await _permissionRequestInFlight;
      status = await permission.status;
      return status.isGranted || status.isLimited;
    }

    try {
      _permissionRequestInFlight = permission.request();
      status = await _permissionRequestInFlight!;
      return status.isGranted || status.isLimited;
    } on PlatformException catch (e) {
      if (e.code == 'ERROR_ALREADY_REQUESTING_PERMISSIONS') {
        status = await permission.status;
        return status.isGranted || status.isLimited;
      }
      rethrow;
    } finally {
      _permissionRequestInFlight = null;
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_pickingImage || _submitting) return;

    setState(() {
      _pickingImage = true;
      _error = null;
    });

    try {
      // image_picker requests camera/photos on iOS & Android — avoid permission_handler first.
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        imageQuality: 85,
      );
      if (!mounted) return;
      if (file != null) {
        setState(() {
          _imageFile = File(file.path);
          _error = null;
        });
      }
    } on PlatformException catch (e) {
      if (!mounted) return;
      if (e.code == 'multiple_request') {
        return;
      }
      setState(() {
        _error = switch (e.code) {
          'camera_access_denied' => 'Camera permission is required.',
          'photo_access_denied' => 'Photo library permission is required.',
          _ => 'Could not open ${source == ImageSource.camera ? 'camera' : 'photo library'}.',
        };
      });
    } finally {
      if (mounted) {
        setState(() => _pickingImage = false);
      }
    }
  }

  Future<void> _takePhoto() => _pickImage(ImageSource.camera);

  Future<void> _chooseFromLibrary() => _pickImage(ImageSource.gallery);

  Future<void> _toggleRecording() async {
    if (_recording) {
      final path = await _recorder.stop();
      setState(() {
        _recording = false;
        if (path != null) _audioFile = File(path);
      });
      return;
    }

    final micGranted = await _requestPermission(Permission.microphone);
    if (!micGranted) {
      final status = await Permission.microphone.status;
      setState(() {
        _error = status.isPermanentlyDenied || status.isRestricted
            ? 'Allow microphone access in Settings to record a voice note.'
            : 'Microphone permission is required for voice notes.';
      });
      return;
    }

    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/hazard_note.m4a';
    await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
    setState(() {
      _recording = true;
      _audioFile = null;
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (_imageFile == null) {
      setState(() => _error = 'Take a photo before submitting.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final position = await ref.read(locationServiceProvider).getCurrentPosition();
      final repo = ref.read(hazardReportRepositoryProvider);
      final reportId = await repo.submit(
        HazardReportSubmission(
          imageFile: _imageFile!,
          audioFile: _audioFile,
          transcript: _transcriptController.text,
          position: position,
          heading: position.heading,
          speed: position.speed,
        ),
      );

      if (mounted) {
        context.go('/map/report/$reportId');
      }
    } catch (e) {
      setState(() {
        _submitting = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report hazard'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Report Hazard',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Photo + optional voice or text. Location is captured automatically.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          AspectRatio(
            aspectRatio: 4 / 3,
            child: InkWell(
              onTap: (_submitting || _pickingImage) ? null : _takePhoto,
              borderRadius: BorderRadius.circular(16),
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: theme.colorScheme.surfaceContainerHighest,
                ),
                child: _imageFile == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.photo_camera_outlined, size: 48, color: theme.colorScheme.primary),
                          const SizedBox(height: 8),
                          const Text('Take a photo'),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(_imageFile!, fit: BoxFit.cover, width: double.infinity),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _transcriptController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Describe the problem (optional)',
              hintText: 'e.g. Deep pothole; riders swerving left',
              prefixIcon: Icon(Icons.mic_none),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _submitting ? null : _toggleRecording,
            icon: Icon(_recording ? Icons.stop : Icons.mic),
            label: Text(_recording ? 'Stop recording' : 'Record voice note'),
          ),
          if (_audioFile != null && !_recording)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Voice note attached', style: theme.textTheme.bodySmall),
            ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: const Text('Location'),
            subtitle: Text(_locationLabel ?? 'Detecting…'),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: (_submitting || _pickingImage) ? null : _chooseFromLibrary,
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Choose photo from library'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            if (_error!.contains('Settings'))
              TextButton(
                onPressed: openAppSettings,
                child: const Text('Open Settings'),
              ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
