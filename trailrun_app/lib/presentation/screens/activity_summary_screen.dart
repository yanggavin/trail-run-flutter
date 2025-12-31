import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/activity.dart';
import '../../domain/models/photo.dart';
import '../../domain/enums/privacy_level.dart';
import '../../data/services/share_export_provider.dart';
import '../widgets/activity_map_widget.dart';
import '../widgets/activity_stats_widget.dart';
import '../widgets/elevation_chart_widget.dart';
import '../widgets/photo_gallery_widget.dart';
import 'activity_map_screen.dart';


/// Screen displaying comprehensive activity summary with stats, map, and photos
class ActivitySummaryScreen extends ConsumerStatefulWidget {
  const ActivitySummaryScreen({
    super.key,
    required this.activity,
  });

  final Activity activity;

  @override
  ConsumerState<ActivitySummaryScreen> createState() => _ActivitySummaryScreenState();
}

class _ActivitySummaryScreenState extends ConsumerState<ActivitySummaryScreen> {
  late Activity _activity;

  @override
  void initState() {
    super.initState();
    _activity = widget.activity;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_activity.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _showEditDialog,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareActivity,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Activity Stats
            ActivityStatsWidget(activity: _activity),
            
            const SizedBox(height: 24),
            
            // Map Section
            _buildMapSection(),
            
            const SizedBox(height: 24),
            
            // Elevation Chart Section
            if (_activity.trackPoints.isNotEmpty) ...[
              _buildElevationSection(),
              const SizedBox(height: 24),
            ],
            
            // Splits Section
            if (_activity.splits.isNotEmpty) ...[
              _buildSplitsSection(),
              const SizedBox(height: 24),
            ],
            
            // Photos Section
            if (_activity.photos.isNotEmpty) ...[
              _buildPhotosSection(),
              const SizedBox(height: 24),
            ],
            
            // Notes Section
            if (_activity.notes?.isNotEmpty == true) ...[
              _buildNotesSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMapSection() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Route',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: _openFullScreenMap,
                  child: const Text('View Full Map'),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 200,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              child: _activity.trackPoints.isNotEmpty
                  ? ActivityMapWidget(
                      activity: _activity,
                      enableInteraction: false,
                      onPhotoTap: _onPhotoTap,
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.map_outlined,
                              size: 48,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'No GPS data available',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildElevationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Elevation Profile',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: ElevationChartWidget(
                trackPoints: _activity.trackPointsSortedBySequence,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSplitsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Splits',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...(_activity.splitsSortedByNumber.map((split) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Text(
                      'Km ${split.splitNumber}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(split.pace.formatMinutesSeconds()),
                  ),
                  Text(
                    '${split.distance.kilometers.toStringAsFixed(2)} km',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ))),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotosSection() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Photos (${_activity.photos.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: _openPhotoGallery,
                  child: const Text('View All'),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 120,
            child: PhotoGalleryWidget(
              photos: _activity.photos,
              onPhotoTap: _onPhotoTap,
              scrollDirection: Axis.horizontal,
              maxPhotos: 10,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _activity.notes!,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  void _openFullScreenMap() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ActivityMapScreen(
          activity: _activity,
          title: _activity.title,
        ),
      ),
    );
  }

  void _openPhotoGallery() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PhotoGalleryScreen(
          photos: _activity.photos,
          activityTitle: _activity.title,
        ),
      ),
    );
  }

  void _onPhotoTap(Photo photo) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PhotoGalleryScreen(
          photos: _activity.photos,
          activityTitle: _activity.title,
          initialPhotoIndex: _activity.photos.indexOf(photo),
        ),
      ),
    );
  }

  void _showEditDialog() {
    showDialog(
      context: context,
      builder: (context) => ActivityEditDialog(
        activity: _activity,
        onSave: (updatedActivity) {
          setState(() {
            _activity = updatedActivity;
          });
        },
      ),
    );
  }

  Future<void> _shareActivity() async {
    final shareService = ref.read(shareExportServiceProvider);
    
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // In a real app we would capture map snapshot here
      // Uint8List? mapSnapshot = await _captureMapSnapshot();
      
      await shareService.shareActivity(
        _activity,
        mapSnapshot: null, // Placeholder
      );
      
      if (mounted) {
        Navigator.of(context).pop(); // Dismiss loading
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Dismiss loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share activity: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Dialog for editing activity details
class ActivityEditDialog extends StatefulWidget {
  const ActivityEditDialog({
    super.key,
    required this.activity,
    required this.onSave,
  });

  final Activity activity;
  final Function(Activity) onSave;

  @override
  State<ActivityEditDialog> createState() => _ActivityEditDialogState();
}

class _ActivityEditDialogState extends State<ActivityEditDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  late PrivacyLevel _selectedPrivacy;
  String? _selectedCoverPhotoId;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.activity.title);
    _notesController = TextEditingController(text: widget.activity.notes ?? '');
    _selectedPrivacy = widget.activity.privacy;
    _selectedCoverPhotoId = widget.activity.coverPhotoId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Activity'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title field
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Notes field
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            
            const SizedBox(height: 16),
            
            // Privacy level
            const Text('Privacy Level', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            DropdownButtonFormField<PrivacyLevel>(
              value: _selectedPrivacy,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: PrivacyLevel.values.map((privacy) {
                return DropdownMenuItem(
                  value: privacy,
                  child: Row(
                    children: [
                      Text(privacy.icon),
                      const SizedBox(width: 8),
                      Text(privacy.displayName),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedPrivacy = value;
                  });
                }
              },
            ),
            
            const SizedBox(height: 16),
            
            // Cover photo selection
            if (widget.activity.photos.isNotEmpty) ...[
              const Text('Cover Photo', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.activity.photos.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      // No cover photo option
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCoverPhotoId = null;
                          });
                        },
                        child: Container(
                          width: 80,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _selectedCoverPhotoId == null 
                                  ? Theme.of(context).primaryColor 
                                  : Colors.grey,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.no_photography, color: Colors.grey),
                              Text('None', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                      );
                    }
                    
                    final photo = widget.activity.photos[index - 1];
                    final isSelected = _selectedCoverPhotoId == photo.id;
                    
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCoverPhotoId = photo.id;
                        });
                      },
                      child: Container(
                        width: 80,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected 
                                ? Theme.of(context).primaryColor 
                                : Colors.grey,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.asset(
                            'assets/images/.gitkeep', // Placeholder
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.image, color: Colors.grey),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveChanges,
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _saveChanges() {
    final updatedActivity = widget.activity.copyWith(
      title: _titleController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      privacy: _selectedPrivacy,
      coverPhotoId: _selectedCoverPhotoId,
    );
    
    widget.onSave(updatedActivity);
    Navigator.of(context).pop();
  }
}