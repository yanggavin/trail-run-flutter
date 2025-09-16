import 'package:flutter/material.dart';
import '../../domain/errors/app_errors.dart';

/// Dialog for displaying structured app errors with recovery actions
class ErrorDialog extends StatelessWidget {
  const ErrorDialog({
    super.key,
    required this.error,
    this.onDismiss,
  });

  final AppError error;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: _getErrorIcon(),
      title: Text(_getErrorTitle()),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(error.userMessage),
          if (error.recoveryActions.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'What you can do:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ...error.recoveryActions.map((action) => _buildRecoveryAction(context, action)),
          ],
        ],
      ),
      actions: [
        if (error.recoveryActions.isEmpty)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDismiss?.call();
            },
            child: const Text('OK'),
          ),
        if (error.recoveryActions.isNotEmpty)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDismiss?.call();
            },
            child: const Text('Cancel'),
          ),
      ],
    );
  }

  Widget _getErrorIcon() {
    IconData iconData;
    Color color;

    switch (error.runtimeType) {
      case LocationError:
        iconData = Icons.location_off;
        color = Colors.orange;
        break;
      case CameraError:
        iconData = Icons.camera_alt_outlined;
        color = Colors.blue;
        break;
      case StorageError:
        iconData = Icons.storage;
        color = Colors.red;
        break;
      case SyncError:
        iconData = Icons.sync_problem;
        color = Colors.amber;
        break;
      case SessionError:
        iconData = Icons.error_outline;
        color = Colors.red;
        break;
      default:
        iconData = Icons.error_outline;
        color = Colors.red;
    }

    return Icon(iconData, color: color, size: 32);
  }

  String _getErrorTitle() {
    switch (error.runtimeType) {
      case LocationError:
        return 'Location Issue';
      case CameraError:
        return 'Camera Issue';
      case StorageError:
        return 'Storage Issue';
      case SyncError:
        return 'Sync Issue';
      case SessionError:
        return 'Session Issue';
      default:
        return 'Error';
    }
  }

  Widget _buildRecoveryAction(BuildContext context, RecoveryAction action) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () async {
          Navigator.of(context).pop();
          try {
            await action.action();
          } catch (e) {
            // Handle action failure
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Action failed: ${e.toString()}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
            color: action.isDestructive ? Colors.red.shade50 : Colors.blue.shade50,
          ),
          child: Row(
            children: [
              Icon(
                action.isDestructive ? Icons.warning : Icons.arrow_forward,
                size: 20,
                color: action.isDestructive ? Colors.red : Colors.blue,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: action.isDestructive ? Colors.red.shade700 : Colors.blue.shade700,
                      ),
                    ),
                    Text(
                      action.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Shows an error dialog for the given error
  static Future<void> show(BuildContext context, AppError error, {VoidCallback? onDismiss}) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ErrorDialog(
        error: error,
        onDismiss: onDismiss,
      ),
    );
  }
}