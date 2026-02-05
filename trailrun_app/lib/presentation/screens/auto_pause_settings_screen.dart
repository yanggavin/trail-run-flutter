import 'package:flutter/material.dart';

import '../../data/services/activity_tracking_provider.dart' as tracking_provider;
import '../../data/services/auto_pause_settings_service.dart';

class AutoPauseSettingsScreen extends StatefulWidget {
  const AutoPauseSettingsScreen({super.key});

  @override
  State<AutoPauseSettingsScreen> createState() => _AutoPauseSettingsScreenState();
}

class _AutoPauseSettingsScreenState extends State<AutoPauseSettingsScreen> {
  AutoPauseSettings _settings = AutoPauseSettings.defaults;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await AutoPauseSettingsService.load();
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _loading = false;
    });
  }

  Future<void> _saveSettings() async {
    await AutoPauseSettingsService.save(_settings);
    tracking_provider.ActivityTrackingProvider.configureAutoPause(
      enabled: _settings.enabled,
      speedThreshold: _settings.speedThreshold,
      timeThreshold: _settings.timeThreshold,
      resumeSpeedThreshold: _settings.resumeSpeedThreshold,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Auto-pause settings saved')),
    );
    Navigator.of(context).pop();
  }

  double _mpsToKmh(double mps) => mps * 3.6;
  double _kmhToMps(double kmh) => kmh / 3.6;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auto-Pause Settings'),
        actions: [
          TextButton(
            onPressed: _loading ? null : _saveSettings,
            child: const Text('Save'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SwitchListTile(
                  title: const Text('Enable Auto-Pause'),
                  subtitle: const Text('Automatically pause when you stop moving'),
                  value: _settings.enabled,
                  onChanged: (value) {
                    setState(() {
                      _settings = _settings.copyWith(enabled: value);
                    });
                  },
                ),
                const SizedBox(height: 16),
                _buildSliderSection(
                  title: 'Pause Speed Threshold',
                  subtitle: 'Pause when speed is below this value',
                  value: _mpsToKmh(_settings.speedThreshold),
                  min: 0.5,
                  max: 6.0,
                  divisions: 11,
                  unit: 'km/h',
                  onChanged: (value) {
                    setState(() {
                      _settings = _settings.copyWith(speedThreshold: _kmhToMps(value));
                    });
                  },
                ),
                const SizedBox(height: 16),
                _buildSliderSection(
                  title: 'Auto-Pause Delay',
                  subtitle: 'Time to wait before pausing',
                  value: _settings.timeThreshold.inSeconds.toDouble(),
                  min: 5,
                  max: 30,
                  divisions: 25,
                  unit: 'sec',
                  onChanged: (value) {
                    setState(() {
                      _settings = _settings.copyWith(timeThreshold: Duration(seconds: value.round()));
                    });
                  },
                ),
                const SizedBox(height: 16),
                _buildSliderSection(
                  title: 'Resume Speed Threshold',
                  subtitle: 'Resume when speed exceeds this value',
                  value: _mpsToKmh(_settings.resumeSpeedThreshold),
                  min: 1.0,
                  max: 8.0,
                  divisions: 14,
                  unit: 'km/h',
                  onChanged: (value) {
                    setState(() {
                      _settings = _settings.copyWith(resumeSpeedThreshold: _kmhToMps(value));
                    });
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  'Tips',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  '• Use a higher pause threshold for technical trails\n'
                  '• Increase delay if your GPS signal is noisy\n'
                  '• Resume threshold should be higher than pause threshold',
                ),
              ],
            ),
    );
  }

  Widget _buildSliderSection({
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String unit,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${value.toStringAsFixed(1)} $unit'),
          ],
        ),
        Slider(
          value: value.clamp(min, max) as double,
          min: min,
          max: max,
          divisions: divisions,
          label: '${value.toStringAsFixed(1)} $unit',
          onChanged: onChanged,
        ),
      ],
    );
  }
}
