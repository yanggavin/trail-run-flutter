import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../../domain/models/activity.dart';
import '../../domain/errors/app_errors.dart';
import '../database/database.dart';
import 'activity_tracking_service.dart';

/// Service responsible for crash recovery and session restoration
class CrashRecoveryService {
  CrashRecoveryService({
    required this.database,
    required this.activityTrackingService,
  });

  final TrailRunDatabase database;
  final ActivityTrackingService activityTrackingService;

  static const String _recoveryFileName = 'crash_recovery.json';
  static const String _sessionStateFileName = 'session_state.json';

  /// Saves the current session state for crash recovery
  Future<void> saveSessionState({
    String? activeActivityId,
    bool isTracking = false,
    DateTime? trackingStartTime,
    Map<String, dynamic>? additionalState,
  }) async {
    try {
      final sessionState = {
        'timestamp': DateTime.now().toIso8601String(),
        'activeActivityId': activeActivityId,
        'isTracking': isTracking,
        'trackingStartTime': trackingStartTime?.toIso8601String(),
        'additionalState': additionalState ?? {},
        'version': '1.0',
      };

      final file = await _getSessionStateFile();
      await file.writeAsString(jsonEncode(sessionState));
      
      debugPrint('Session state saved: $sessionState');
    } catch (error, stackTrace) {
      debugPrint('Failed to save session state: $error\n$stackTrace');
      // Don't throw - this is a background operation
    }
  }

  /// Loads and processes any crash recovery data
  Future<CrashRecoveryResult> checkForCrashRecovery() async {
    try {
      final sessionFile = await _getSessionStateFile();
      final recoveryFile = await _getRecoveryFile();

      if (!await sessionFile.exists()) {
        return CrashRecoveryResult.noCrash();
      }

      final sessionData = jsonDecode(await sessionFile.readAsString());
      final sessionTimestamp = DateTime.parse(sessionData['timestamp'] as String);
      
      // Check if the session is recent enough to be considered a crash
      final timeSinceLastSession = DateTime.now().difference(sessionTimestamp);
      if (timeSinceLastSession.inMinutes > 30) {
        // Too old, probably not a crash
        await _cleanupRecoveryFiles();
        return CrashRecoveryResult.noCrash();
      }

      final activeActivityId = sessionData['activeActivityId'] as String?;
      final wasTracking = sessionData['isTracking'] as bool? ?? false;
      
      if (activeActivityId != null && wasTracking) {
        // We have an active tracking session that may need recovery
        final activity = await _getActivityForRecovery(activeActivityId);
        
        if (activity != null) {
          // Save recovery information
          await _saveRecoveryInfo(activity, sessionData);
          
          return CrashRecoveryResult.recoveryNeeded(
            activity: activity,
            sessionData: sessionData,
          );
        }
      }

      await _cleanupRecoveryFiles();
      return CrashRecoveryResult.noCrash();
      
    } catch (error, stackTrace) {
      debugPrint('Error checking for crash recovery: $error\n$stackTrace');
      return CrashRecoveryResult.error(
        SessionError(
          type: SessionErrorType.crashRecovery,
          message: 'Failed to check crash recovery: $error',
          userMessage: 'There was a problem checking for previous session data.',
          recoveryActions: [
            RecoveryAction(
              title: 'Continue',
              description: 'Start fresh without recovery',
              action: () async => await _cleanupRecoveryFiles(),
            ),
          ],
          diagnosticInfo: {
            'timestamp': DateTime.now().toIso8601String(),
            'error_type': error.runtimeType.toString(),
          },
        ),
      );
    }
  }

  /// Recovers a crashed tracking session
  Future<void> recoverTrackingSession(Activity activity, Map<String, dynamic> sessionData) async {
    try {
      debugPrint('Recovering tracking session for activity: ${activity.id}');
      
      // Restore the tracking state
      final recovered = await activityTrackingService.recoverInProgressActivity();
      if (recovered == null) {
        throw SessionError(
          type: SessionErrorType.crashRecovery,
          message: 'No active activity found for recovery',
          userMessage: 'We couldn\'t find an active session to recover.',
          recoveryActions: [
            RecoveryAction(
              title: 'Start New Session',
              description: 'Begin a new tracking session',
              action: () async => await _cleanupRecoveryFiles(),
            ),
          ],
          diagnosticInfo: {
            'timestamp': DateTime.now().toIso8601String(),
            'activity_id': activity.id,
          },
        );
      }

      await activityTrackingService.resumeActivity();
      
      // Clean up recovery files
      await _cleanupRecoveryFiles();
      
      debugPrint('Successfully recovered tracking session');
      
    } catch (error, stackTrace) {
      debugPrint('Failed to recover tracking session: $error\n$stackTrace');
      throw SessionError(
        type: SessionErrorType.crashRecovery,
        message: 'Failed to recover tracking session: $error',
        userMessage: 'Could not restore your previous tracking session.',
        recoveryActions: [
          RecoveryAction(
            title: 'Start New Session',
            description: 'Begin a new tracking session',
            action: () async => await _cleanupRecoveryFiles(),
          ),
          RecoveryAction(
            title: 'View Activity',
            description: 'Check the partially recorded activity',
            action: () async {
              // Navigate to activity details
            },
          ),
        ],
        diagnosticInfo: {
          'timestamp': DateTime.now().toIso8601String(),
          'activity_id': activity.id,
          'error_type': error.runtimeType.toString(),
        },
      );
    }
  }

  /// Dismisses crash recovery (user chooses not to recover)
  Future<void> dismissRecovery() async {
    await _cleanupRecoveryFiles();
  }

  /// Clears the current session state (call when app is properly closed)
  Future<void> clearSessionState() async {
    try {
      final file = await _getSessionStateFile();
      if (await file.exists()) {
        await file.delete();
      }
    } catch (error) {
      debugPrint('Failed to clear session state: $error');
      // Don't throw - this is cleanup
    }
  }

  /// Gets diagnostic information for troubleshooting
  Future<Map<String, dynamic>> getDiagnosticInfo() async {
    try {
      final sessionFile = await _getSessionStateFile();
      final recoveryFile = await _getRecoveryFile();
      
      final diagnostics = <String, dynamic>{
        'timestamp': DateTime.now().toIso8601String(),
        'platform': Platform.operatingSystem,
        'session_file_exists': await sessionFile.exists(),
        'recovery_file_exists': await recoveryFile.exists(),
      };

      if (await sessionFile.exists()) {
        try {
          final sessionData = jsonDecode(await sessionFile.readAsString());
          diagnostics['last_session'] = sessionData;
        } catch (e) {
          diagnostics['session_file_error'] = e.toString();
        }
      }

      if (await recoveryFile.exists()) {
        try {
          final recoveryData = jsonDecode(await recoveryFile.readAsString());
          diagnostics['recovery_data'] = recoveryData;
        } catch (e) {
          diagnostics['recovery_file_error'] = e.toString();
        }
      }

      return diagnostics;
    } catch (error) {
      return {
        'error': error.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  Future<File> _getSessionStateFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_sessionStateFileName');
  }

  Future<File> _getRecoveryFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_recoveryFileName');
  }

  Future<Activity?> _getActivityForRecovery(String activityId) async {
    try {
      final activityEntity = await database.activityDao.getActivityById(activityId);
      if (activityEntity == null) {
        return null;
      }

      return database.activityDao.fromEntity(activityEntity);
    } catch (error) {
      debugPrint('Failed to get activity for recovery: $error');
      return null;
    }
  }

  Future<void> _saveRecoveryInfo(Activity activity, Map<String, dynamic> sessionData) async {
    final recoveryInfo = {
      'activity': {
        'id': activity.id,
        'title': activity.title,
        'startTime': activity.startTime.dateTime.toIso8601String(),
        'distanceMeters': activity.distance.meters,
        'duration': (activity.duration ?? Duration.zero).inSeconds,
      },
      'sessionData': sessionData,
      'recoveryTimestamp': DateTime.now().toIso8601String(),
    };

    final file = await _getRecoveryFile();
    await file.writeAsString(jsonEncode(recoveryInfo));
  }

  Future<void> _cleanupRecoveryFiles() async {
    try {
      final sessionFile = await _getSessionStateFile();
      final recoveryFile = await _getRecoveryFile();

      if (await sessionFile.exists()) {
        await sessionFile.delete();
      }
      
      if (await recoveryFile.exists()) {
        await recoveryFile.delete();
      }
    } catch (error) {
      debugPrint('Failed to cleanup recovery files: $error');
    }
  }
}

/// Result of crash recovery check
class CrashRecoveryResult {
  const CrashRecoveryResult._({
    required this.needsRecovery,
    this.activity,
    this.sessionData,
    this.error,
  });

  final bool needsRecovery;
  final Activity? activity;
  final Map<String, dynamic>? sessionData;
  final SessionError? error;

  factory CrashRecoveryResult.noCrash() => const CrashRecoveryResult._(needsRecovery: false);
  
  factory CrashRecoveryResult.recoveryNeeded({
    required Activity activity,
    required Map<String, dynamic> sessionData,
  }) => CrashRecoveryResult._(
    needsRecovery: true,
    activity: activity,
    sessionData: sessionData,
  );
  
  factory CrashRecoveryResult.error(SessionError error) => CrashRecoveryResult._(
    needsRecovery: false,
    error: error,
  );

  bool get hasError => error != null;
}
