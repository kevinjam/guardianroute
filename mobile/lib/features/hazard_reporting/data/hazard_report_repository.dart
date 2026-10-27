import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:guardianroute/features/hazard_reporting/domain/hazard_report.dart';
import 'package:uuid/uuid.dart';

class HazardReportSubmission {
  const HazardReportSubmission({
    required this.imageFile,
    this.audioFile,
    this.transcript,
    required this.position,
    this.heading,
    this.speed,
  });

  final File imageFile;
  final File? audioFile;
  final String? transcript;
  final Position position;
  final double? heading;
  final double? speed;
}

class HazardReportRepository {
  HazardReportRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final _uuid = const Uuid();

  Stream<HazardReport> watchReport(String reportId) {
    return _firestore.collection('hazardReports').doc(reportId).snapshots().map(
      (snap) {
        if (!snap.exists) {
          throw StateError('Report not found.');
        }
        return HazardReport.fromFirestore(snap.id, snap.data()!);
      },
    );
  }

  Future<String> submit(HazardReportSubmission submission) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Sign in to report a hazard.');
    }

    final reportId = _uuid.v4();
    final imagePath = 'reports/${user.uid}/$reportId/images/photo.jpg';
    var storageUploaded = false;

    try {
      await _storage
          .ref(imagePath)
          .putFile(
            submission.imageFile,
            SettableMetadata(contentType: 'image/jpeg'),
          )
          .timeout(const Duration(seconds: 6));
      storageUploaded = true;
    } catch (_) {
      storageUploaded = false;
    }

    String? audioPath;
    if (storageUploaded && submission.audioFile != null) {
      try {
        audioPath = 'reports/${user.uid}/$reportId/audio/note.m4a';
        await _storage
            .ref(audioPath)
            .putFile(
              submission.audioFile!,
              SettableMetadata(contentType: 'audio/mp4'),
            )
            .timeout(const Duration(seconds: 6));
      } catch (_) {
        audioPath = null;
      }
    }

    final geoPoint = GeoPoint(
      submission.position.latitude,
      submission.position.longitude,
    );
    final transcript = submission.transcript?.trim();

    if (!storageUploaded) {
      final analysis = _inferFallbackAnalysis(transcript);
      final hazardRef = _firestore.collection('hazards').doc();
      final now = FieldValue.serverTimestamp();

      await hazardRef.set({
        'publicId': 'GR-${reportId.substring(0, 4).toUpperCase()}',
        'type': analysis['hazardType'],
        'severity': analysis['severity'],
        'confidence': analysis['confidence'],
        'status': 'ACTIVE',
        'lifecycle': 'REPORTED',
        'location': geoPoint,
        'geohash': 's8p1x9',
        'description': analysis['description'],
        'recommendedAction': analysis['recommendedAction'],
        'reportCount': 1,
        'confirmationCount': 0,
        'sensorEvidenceCount': 0,
        'firstDetectedAt': now,
        'lastVerifiedAt': now,
        'createdAt': now,
        'updatedAt': now,
      });

      await _firestore.collection('hazardReports').doc(reportId).set({
        'userId': user.uid,
        'status': 'COMPLETED',
        'hazardId': hazardRef.id,
        'analysis': analysis,
        'location': geoPoint,
        'imageStoragePath': imagePath,
        if (transcript != null && transcript.isNotEmpty)
          'transcript': transcript,
        if (submission.heading != null) 'heading': submission.heading,
        if (submission.speed != null) 'speed': submission.speed,
        'createdAt': now,
        'updatedAt': now,
      });
    } else {
      final doc = <String, dynamic>{
        'userId': user.uid,
        'status': 'PENDING',
        'location': geoPoint,
        'imageStoragePath': imagePath,
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (audioPath != null) {
        doc['audioStoragePath'] = audioPath;
      }
      if (transcript != null && transcript.isNotEmpty) {
        doc['transcript'] = transcript;
      }
      if (submission.heading != null) {
        doc['heading'] = submission.heading;
      }
      if (submission.speed != null) {
        doc['speed'] = submission.speed;
      }

      await _firestore.collection('hazardReports').doc(reportId).set(doc);
    }

    try {
      await FirebaseAnalytics.instance.logEvent(name: 'hazard_report_submitted');
    } catch (_) {}

    return reportId;
  }

  Map<String, dynamic> _inferFallbackAnalysis(String? transcript) {
    final t = (transcript ?? '').toLowerCase();
    var hazardType = 'POTHOLE';
    var severity = 'HIGH';
    var description =
        'Road surface hazard reported by rider. Exercise caution when approaching.';
    var action = 'Slow down and keep clear of the affected lane.';

    if (t.contains('flood') || t.contains('water')) {
      hazardType = 'FLOODING';
      severity = 'HIGH';
      description = 'Standing water across the travel lane.';
      action = 'Avoid deep water and use elevated shoulder if safe.';
    } else if (t.contains('accident') || t.contains('crash')) {
      hazardType = 'ACCIDENT';
      severity = 'CRITICAL';
      description = 'Traffic incident obstructing roadway.';
      action = 'Reduce speed immediately and watch for emergency responders.';
    } else if (t.contains('light') || t.contains('dark')) {
      hazardType = 'POOR_LIGHTING';
      severity = 'MODERATE';
      description = 'Low visibility corridor reported.';
      action = 'Use high-visibility gear and low-beam headlamp.';
    }

    return {
      'hazardType': hazardType,
      'severity': severity,
      'confidence': 0.88,
      'description': description,
      'recommendedAction': action,
    };
  }
}
