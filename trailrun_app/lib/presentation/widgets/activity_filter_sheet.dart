import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/repositories/activity_repository.dart';
import '../../domain/enums/privacy_level.dart';

/// Bottom sheet for filtering activities
class ActivityFilterSheet extends StatefulWidget {
  const ActivityFilterSheet({
    super.key,
    this.initialFilter,
    required this.onApplyFilter,
  });

  final ActivityFilter? initialFilter;
  final Function(ActivityFilter?) onApplyFilter;

  @override
  State<ActivityFilterSheet> createState() => _ActivityFilterSheetState();
}

class _ActivityFilterSheetState extends State<ActivityFilterSheet> {
  late DateTime? _startDate;
  late DateTime? _endDate;
  late double? _minDistance;
  late double? _maxDistance;
  late bool? _hasPhotos;
  late Set<PrivacyLevel> _selectedPrivacyLevels;

  @override
  void initState() {
    super.initState();
    _initializeFromFilter();
  }

  void _initializeFromFilter() {
    final filter = widget.initialFilter;
    _startDate = filter?.startDate;
    _endDate = filter?.endDate;
    _minDistance = filter?.minDistance != null ? filter!.minDistance! / 1000 : null; // Convert to km
    _maxDistance = filter?.maxDistance != null ? filter!.maxDistance! / 1000 : null; // Convert to km
    _hasPhotos = filter?.hasPhotos;
    
    _selectedPrivacyLevels = {};
    if (filter?.privacyLevels != null) {
      for (final level in filter!.privacyLevels!) {
        if (level < PrivacyLevel.values.length) {
          _selectedPrivacyLevels.add(PrivacyLevel.values[level]);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(
                'Filter Activities',
                style: theme.textTheme.headlineSmall,
              ),
              const Spacer(),
              TextButton(
                onPressed: _clearAllFilters,
                child: const Text('Clear All'),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Date Range Section
          Text(
            'Date Range',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  label: 'Start Date',
                  date: _startDate,
                  onTap: () => _selectDate(context, true),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDateField(
                  label: 'End Date',
                  date: _endDate,
                  onTap: () => _selectDate(context, false),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Distance Range Section
          Text(
            'Distance Range (km)',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: _minDistance?.toString(),
                  decoration: const InputDecoration(
                    labelText: 'Min Distance',
                    suffixText: 'km',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _minDistance = double.tryParse(value);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  initialValue: _maxDistance?.toString(),
                  decoration: const InputDecoration(
                    labelText: 'Max Distance',
                    suffixText: 'km',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _maxDistance = double.tryParse(value);
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Photo Filter Section
          Text(
            'Photos',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          
          Row(
            children: [
              FilterChip(
                label: const Text('Has Photos'),
                selected: _hasPhotos == true,
                onSelected: (selected) {
                  setState(() {
                    _hasPhotos = selected ? true : null;
                  });
                },
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('No Photos'),
                selected: _hasPhotos == false,
                onSelected: (selected) {
                  setState(() {
                    _hasPhotos = selected ? false : null;
                  });
                },
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Privacy Level Section
          Text(
            'Privacy Level',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          
          Wrap(
            spacing: 8,
            children: PrivacyLevel.values.map((level) {
              return FilterChip(
                label: Text(_getPrivacyLevelName(level)),
                selected: _selectedPrivacyLevels.contains(level),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedPrivacyLevels.add(level);
                    } else {
                      _selectedPrivacyLevels.remove(level);
                    }
                  });
                },
              );
            }).toList(),
          ),
          
          const SizedBox(height: 32),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _applyFilter,
                  child: const Text('Apply Filter'),
                ),
              ),
            ],
          ),
          
          // Add bottom padding for safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          date != null ? DateFormat.yMd().format(date) : 'Select date',
          style: TextStyle(
            color: date != null ? null : Colors.grey,
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final initialDate = isStartDate ? _startDate : _endDate;
    final firstDate = DateTime(2020);
    final lastDate = DateTime.now();
    
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: firstDate,
      lastDate: lastDate,
    );
    
    if (selectedDate != null) {
      setState(() {
        if (isStartDate) {
          _startDate = selectedDate;
          // Ensure end date is not before start date
          if (_endDate != null && _endDate!.isBefore(selectedDate)) {
            _endDate = selectedDate;
          }
        } else {
          _endDate = selectedDate;
          // Ensure start date is not after end date
          if (_startDate != null && _startDate!.isAfter(selectedDate)) {
            _startDate = selectedDate;
          }
        }
      });
    }
  }

  void _clearAllFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _minDistance = null;
      _maxDistance = null;
      _hasPhotos = null;
      _selectedPrivacyLevels.clear();
    });
  }

  void _applyFilter() {
    ActivityFilter? filter;
    
    // Only create filter if at least one criterion is set
    if (_startDate != null ||
        _endDate != null ||
        _minDistance != null ||
        _maxDistance != null ||
        _hasPhotos != null ||
        _selectedPrivacyLevels.isNotEmpty) {
      
      filter = ActivityFilter(
        startDate: _startDate,
        endDate: _endDate,
        minDistance: _minDistance != null ? _minDistance! * 1000 : null, // Convert to meters
        maxDistance: _maxDistance != null ? _maxDistance! * 1000 : null, // Convert to meters
        hasPhotos: _hasPhotos,
        privacyLevels: _selectedPrivacyLevels.isNotEmpty 
            ? _selectedPrivacyLevels.map((level) => level.index).toList()
            : null,
      );
    }
    
    widget.onApplyFilter(filter);
    Navigator.of(context).pop();
  }

  String _getPrivacyLevelName(PrivacyLevel level) {
    switch (level) {
      case PrivacyLevel.private:
        return 'Private';
      case PrivacyLevel.friends:
        return 'Friends';
      case PrivacyLevel.public:
        return 'Public';
    }
  }
}