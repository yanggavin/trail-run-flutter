import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/services/gps_diagnostics_service.dart';

/// Widget for displaying GPS diagnostics and troubleshooting information
class GpsDiagnosticsWidget extends StatefulWidget {
  const GpsDiagnosticsWidget({
    super.key,
    required this.diagnosticsService,
  });

  final GpsDiagnosticsService diagnosticsService;

  @override
  State<GpsDiagnosticsWidget> createState() => _GpsDiagnosticsWidgetState();
}

class _GpsDiagnosticsWidgetState extends State<GpsDiagnosticsWidget> {
  GpsDiagnostics? _diagnostics;
  GpsTestResult? _testResult;
  List<TroubleshootingStep>? _troubleshootingSteps;
  bool _isLoading = false;
  bool _isRunningTest = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDiagnostics();
  }

  Future<void> _loadDiagnostics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final diagnostics = await widget.diagnosticsService.getDiagnostics();
      final troubleshootingSteps = await widget.diagnosticsService.getTroubleshootingSteps();
      
      setState(() {
        _diagnostics = diagnostics;
        _troubleshootingSteps = troubleshootingSteps;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _runGpsTest() async {
    setState(() {
      _isRunningTest = true;
      _testResult = null;
    });

    try {
      final result = await widget.diagnosticsService.runGpsTest();
      setState(() {
        _testResult = result;
        _isRunningTest = false;
      });
    } catch (error) {
      setState(() {
        _error = error.toString();
        _isRunningTest = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GPS Diagnostics'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadDiagnostics,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorView()
              : _buildDiagnosticsView(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text('Failed to load GPS diagnostics'),
          const SizedBox(height: 8),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadDiagnostics,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosticsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusOverview(),
          const SizedBox(height: 24),
          _buildTroubleshootingSteps(),
          const SizedBox(height: 24),
          _buildGpsTest(),
          const SizedBox(height: 24),
          _buildDetailedDiagnostics(),
        ],
      ),
    );
  }

  Widget _buildStatusOverview() {
    if (_diagnostics == null) return const SizedBox.shrink();

    final isGpsWorking = _diagnostics!.isLocationServiceEnabled && 
                        _diagnostics!.locationPermission.toString().contains('granted');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isGpsWorking ? Icons.check_circle : Icons.error,
                  color: isGpsWorking ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  isGpsWorking ? 'GPS is Working' : 'GPS Issues Detected',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStatusItem(
              'Location Services',
              _diagnostics!.isLocationServiceEnabled ? 'Enabled' : 'Disabled',
              _diagnostics!.isLocationServiceEnabled,
            ),
            _buildStatusItem(
              'Location Permission',
              _diagnostics!.locationPermission.toString().split('.').last,
              _diagnostics!.locationPermission.toString().contains('granted'),
            ),
            if (_diagnostics!.lastKnownPosition != null)
              _buildStatusItem(
                'GPS Signal Quality',
                _diagnostics!.gpsSignalQuality.toString().split('.').last,
                _diagnostics!.gpsSignalQuality == GpsSignalQuality.good ||
                _diagnostics!.gpsSignalQuality == GpsSignalQuality.excellent,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String label, String value, bool isGood) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            isGood ? Icons.check : Icons.close,
            size: 16,
            color: isGood ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Text('$label: '),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isGood ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTroubleshootingSteps() {
    if (_troubleshootingSteps == null || _troubleshootingSteps!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Troubleshooting Steps',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ..._troubleshootingSteps!.map((step) => _buildTroubleshootingStep(step)),
          ],
        ),
      ),
    );
  }

  Widget _buildTroubleshootingStep(TroubleshootingStep step) {
    Color priorityColor;
    IconData priorityIcon;

    switch (step.priority) {
      case TroubleshootingPriority.critical:
        priorityColor = Colors.red;
        priorityIcon = Icons.error;
        break;
      case TroubleshootingPriority.high:
        priorityColor = Colors.orange;
        priorityIcon = Icons.warning;
        break;
      case TroubleshootingPriority.medium:
        priorityColor = Colors.amber;
        priorityIcon = Icons.info;
        break;
      case TroubleshootingPriority.low:
        priorityColor = Colors.blue;
        priorityIcon = Icons.info_outline;
        break;
      case TroubleshootingPriority.info:
        priorityColor = Colors.green;
        priorityIcon = Icons.check_circle;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: priorityColor.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
        color: priorityColor.withOpacity(0.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(priorityIcon, color: priorityColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  step.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(step.description),
          const SizedBox(height: 8),
          Text(
            step.action,
            style: const TextStyle(
              fontStyle: FontStyle.italic,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGpsTest() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'GPS Signal Test',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Run a 1-minute GPS test to check signal quality and stability.',
            ),
            const SizedBox(height: 16),
            if (_isRunningTest)
              const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 8),
                  Text('Running GPS test...'),
                ],
              )
            else if (_testResult != null)
              _buildTestResults()
            else
              ElevatedButton(
                onPressed: _runGpsTest,
                child: const Text('Run GPS Test'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestResults() {
    if (_testResult == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Test Results',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        if (_testResult!.error != null)
          Text(
            'Test failed: ${_testResult!.error}',
            style: const TextStyle(color: Colors.red),
          )
        else ...[
          Text('Total readings: ${_testResult!.totalReadings}'),
          Text('Average accuracy: ${_testResult!.averageAccuracy.toStringAsFixed(1)}m'),
          Text('Best accuracy: ${_testResult!.bestAccuracy.toStringAsFixed(1)}m'),
          Text('Signal stability: ${_testResult!.signalStability}'),
        ],
        const SizedBox(height: 12),
        const Text(
          'Recommendations:',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        ..._testResult!.recommendations.map((rec) => Text('• $rec')),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _runGpsTest,
          child: const Text('Run Test Again'),
        ),
      ],
    );
  }

  Widget _buildDetailedDiagnostics() {
    if (_diagnostics == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Detailed Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _copyDiagnosticsToClipboard,
                  child: const Text('Copy'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDetailItem('Device', _diagnostics!.deviceInfo['model'] ?? 'Unknown'),
            _buildDetailItem('Platform', _diagnostics!.deviceInfo['platform'] ?? 'Unknown'),
            _buildDetailItem('OS Version', _diagnostics!.deviceInfo['version'] ?? 'Unknown'),
            if (_diagnostics!.lastKnownPosition != null) ...[
              _buildDetailItem(
                'Last Position',
                '${_diagnostics!.lastKnownPosition!['latitude']?.toStringAsFixed(6)}, '
                '${_diagnostics!.lastKnownPosition!['longitude']?.toStringAsFixed(6)}',
              ),
              _buildDetailItem(
                'Last Accuracy',
                '${_diagnostics!.lastKnownPosition!['accuracy']?.toStringAsFixed(1)}m',
              ),
            ],
            _buildDetailItem('Network', _diagnostics!.networkConnectivity),
            if (_diagnostics!.batteryOptimizationStatus != null)
              _buildDetailItem('Battery Optimization', _diagnostics!.batteryOptimizationStatus!),
            if (_diagnostics!.backgroundAppRefreshStatus != null)
              _buildDetailItem('Background Refresh', _diagnostics!.backgroundAppRefreshStatus!),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _copyDiagnosticsToClipboard() {
    if (_diagnostics == null) return;

    final diagnosticsText = '''
GPS Diagnostics Report
Generated: ${DateTime.now()}

Location Services: ${_diagnostics!.isLocationServiceEnabled ? 'Enabled' : 'Disabled'}
Location Permission: ${_diagnostics!.locationPermission}
GPS Signal Quality: ${_diagnostics!.gpsSignalQuality}

Device Information:
${_diagnostics!.deviceInfo.entries.map((e) => '${e.key}: ${e.value}').join('\n')}

${_diagnostics!.lastKnownPosition != null ? '''
Last Known Position:
${_diagnostics!.lastKnownPosition!.entries.map((e) => '${e.key}: ${e.value}').join('\n')}
''' : 'No position data available'}

Network: ${_diagnostics!.networkConnectivity}
${_diagnostics!.batteryOptimizationStatus != null ? 'Battery Optimization: ${_diagnostics!.batteryOptimizationStatus}' : ''}
${_diagnostics!.backgroundAppRefreshStatus != null ? 'Background Refresh: ${_diagnostics!.backgroundAppRefreshStatus}' : ''}
''';

    Clipboard.setData(ClipboardData(text: diagnosticsText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Diagnostics copied to clipboard')),
    );
  }
}