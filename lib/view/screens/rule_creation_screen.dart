import 'package:flutter/material.dart';
import '../../data/services/app_blocking_service.dart';
import '../../data/model/blocking_rule.dart';

class RuleCreationScreen extends StatefulWidget {
  final BlockingRule? existingRule;

  const RuleCreationScreen({super.key, this.existingRule});

  @override
  State<RuleCreationScreen> createState() => _RuleCreationScreenState();
}

class _RuleCreationScreenState extends State<RuleCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _customMessageController = TextEditingController();

  BlockingType _selectedType = BlockingType.timeLimit;
  List<String> _selectedPackages = [];
  Duration _dailyLimit = const Duration(hours: 2);
  Duration _sessionLimit = const Duration(minutes: 30);
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);
  List<int> _selectedDays = [1, 2, 3, 4, 5]; // Monday to Friday
  bool _allowEmergencyBypass = false;
  bool _showUsageWarning = true;
  Duration _warningThreshold = const Duration(minutes: 90);

  final AppBlockingService _blockingService = AppBlockingService();

  @override
  void initState() {
    super.initState();
    if (widget.existingRule != null) {
      _loadExistingRule();
    }
  }

  void _loadExistingRule() {
    final rule = widget.existingRule!;
    _nameController.text = rule.name;
    _descriptionController.text = rule.description;
    _customMessageController.text = rule.customBlockMessage ?? '';
    _selectedType = rule.type;
    _selectedPackages = List.from(rule.targetPackages);
    _dailyLimit = rule.dailyLimit ?? const Duration(hours: 2);
    _sessionLimit = rule.sessionLimit ?? const Duration(minutes: 30);
    _startTime = rule.startTime ?? const TimeOfDay(hour: 9, minute: 0);
    _endTime = rule.endTime ?? const TimeOfDay(hour: 17, minute: 0);
    _selectedDays = rule.daysOfWeek ?? [1, 2, 3, 4, 5];
    _allowEmergencyBypass = rule.allowEmergencyBypass;
    _showUsageWarning = rule.showUsageWarning;
    _warningThreshold = rule.warningThreshold ?? const Duration(minutes: 90);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFE4B5),
      appBar: AppBar(
        title: Text(widget.existingRule != null ? 'Edit Rule' : 'Create Rule'),
        backgroundColor: const Color(0xFFFFE4B5),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _saveRule,
            child: const Text('Save', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Info
              _buildSection('Basic Information', [
                _buildTextField(
                  controller: _nameController,
                  label: 'Rule Name',
                  hint: 'e.g., Social Media Limit',
                  validator: (value) => value?.isEmpty == true ? 'Name is required' : null,
                ),
                const SizedBox(height: 15),
                _buildTextField(
                  controller: _descriptionController,
                  label: 'Description',
                  hint: 'e.g., Limit social media to 2 hours daily',
                  maxLines: 2,
                ),
              ]),

              const SizedBox(height: 25),

              // Rule Type
              _buildSection('Rule Type', [
                _buildRuleTypeSelector(),
              ]),

              const SizedBox(height: 25),

              // App Selection
              _buildSection('Target Apps', [
                _buildAppSelector(),
              ]),

              const SizedBox(height: 25),

              // Type-specific settings
              if (_selectedType == BlockingType.timeLimit) ...[
                _buildSection('Time Limits', [
                  _buildTimeLimitSettings(),
                ]),
                const SizedBox(height: 25),
              ],

              if (_selectedType == BlockingType.schedule) ...[
                _buildSection('Schedule Settings', [
                  _buildScheduleSettings(),
                ]),
                const SizedBox(height: 25),
              ],

              // Advanced Settings
              _buildSection('Advanced Settings', [
                _buildAdvancedSettings(),
              ]),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.white,
      ),
      maxLines: maxLines,
      validator: validator,
    );
  }

  Widget _buildRuleTypeSelector() {
    return Column(
      children: BlockingType.values.map((type) {
        return RadioListTile<BlockingType>(
          title: Text(_getRuleTypeDisplayName(type)),
          subtitle: Text(_getRuleTypeDescription(type)),
          value: type,
          groupValue: _selectedType,
          onChanged: (value) => setState(() => _selectedType = value!),
          activeColor: Colors.orange,
        );
      }).toList(),
    );
  }

  Widget _buildAppSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Selected Apps: ${_selectedPackages.length}'),
            const Spacer(),
            ElevatedButton(
              onPressed: _showAppSelectionDialog,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Select Apps', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
        if (_selectedPackages.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedPackages.map((packageName) {
              return Chip(
                label: Text(_getAppDisplayName(packageName)),
                onDeleted: () {
                  setState(() => _selectedPackages.remove(packageName));
                },
                backgroundColor: Colors.orange.withOpacity(0.2),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildTimeLimitSettings() {
    return Column(
      children: [
        // Daily Limit
        Row(
          children: [
            const Expanded(child: Text('Daily Limit:')),
            DropdownButton<Duration>(
              value: _dailyLimit,
              items: [
                const Duration(minutes: 30),
                const Duration(hours: 1),
                const Duration(hours: 2),
                const Duration(hours: 3),
                const Duration(hours: 4),
                const Duration(hours: 6),
                const Duration(hours: 8),
              ].map((duration) {
                return DropdownMenuItem(
                  value: duration,
                  child: Text(_formatDuration(duration)),
                );
              }).toList(),
              onChanged: (value) => setState(() => _dailyLimit = value!),
            ),
          ],
        ),
        const SizedBox(height: 15),
        
        // Session Limit
        Row(
          children: [
            const Expanded(child: Text('Session Limit:')),
            DropdownButton<Duration>(
              value: _sessionLimit,
              items: [
                const Duration(minutes: 15),
                const Duration(minutes: 30),
                const Duration(hours: 1),
                const Duration(hours: 2),
              ].map((duration) {
                return DropdownMenuItem(
                  value: duration,
                  child: Text(_formatDuration(duration)),
                );
              }).toList(),
              onChanged: (value) => setState(() => _sessionLimit = value!),
            ),
          ],
        ),
        const SizedBox(height: 15),
        
        // Warning Settings
        SwitchListTile(
          title: const Text('Show Usage Warning'),
          subtitle: const Text('Warn when approaching limit'),
          value: _showUsageWarning,
          onChanged: (value) => setState(() => _showUsageWarning = value),
          activeColor: Colors.orange,
        ),
        
        if (_showUsageWarning) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              const Expanded(child: Text('Warning Threshold:')),
              DropdownButton<Duration>(
                value: _warningThreshold,
                items: [
                  Duration(milliseconds: (_dailyLimit.inMilliseconds * 0.7).round()),
                  Duration(milliseconds: (_dailyLimit.inMilliseconds * 0.8).round()),
                  Duration(milliseconds: (_dailyLimit.inMilliseconds * 0.9).round()),
                ].map((duration) {
                  return DropdownMenuItem(
                    value: duration,
                    child: Text(_formatDuration(duration)),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _warningThreshold = value!),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildScheduleSettings() {
    return Column(
      children: [
        // Time Range
        Row(
          children: [
            Expanded(
              child: ListTile(
                title: const Text('Start Time'),
                subtitle: Text(_startTime.format(context)),
                onTap: () => _selectTime(true),
              ),
            ),
            Expanded(
              child: ListTile(
                title: const Text('End Time'),
                subtitle: Text(_endTime.format(context)),
                onTap: () => _selectTime(false),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 15),
        
        // Days of Week
        const Text('Days of Week:', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: List.generate(7, (index) {
            final day = index + 1;
            final dayName = _getDayName(day);
            final isSelected = _selectedDays.contains(day);
            
            return FilterChip(
              label: Text(dayName),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedDays.add(day);
                  } else {
                    _selectedDays.remove(day);
                  }
                });
              },
              selectedColor: Colors.orange.withOpacity(0.3),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildAdvancedSettings() {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('Allow Emergency Bypass'),
          subtitle: const Text('Allow temporary override in emergencies'),
          value: _allowEmergencyBypass,
          onChanged: (value) => setState(() => _allowEmergencyBypass = value),
          activeColor: Colors.orange,
        ),
        
        const SizedBox(height: 15),
        
        _buildTextField(
          controller: _customMessageController,
          label: 'Custom Block Message (Optional)',
          hint: 'Message shown when app is blocked',
          maxLines: 2,
        ),
      ],
    );
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  String _getRuleTypeDisplayName(BlockingType type) {
    switch (type) {
      case BlockingType.timeLimit:
        return 'Time Limit';
      case BlockingType.schedule:
        return 'Schedule';
      case BlockingType.allDayBlock:
        return 'All Day Block';
      case BlockingType.focusMode:
        return 'Focus Mode';
    }
  }

  String _getRuleTypeDescription(BlockingType type) {
    switch (type) {
      case BlockingType.timeLimit:
        return 'Limit daily or session usage time';
      case BlockingType.schedule:
        return 'Block during specific time periods';
      case BlockingType.allDayBlock:
        return 'Block completely for the entire day';
      case BlockingType.focusMode:
        return 'Block as part of a focus mode';
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${minutes}m';
    }
  }

  String _getDayName(int day) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[day - 1];
  }

  String _getAppDisplayName(String packageName) {
    // In a real implementation, you'd look up the actual app name
    final parts = packageName.split('.');
    return parts.last.replaceAll('_', ' ').toUpperCase();
  }

  Future<void> _selectTime(bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
    );
    
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _showAppSelectionDialog() {
    // Mock app list - in real implementation, get from AppUsageService
    final availableApps = [
      'com.instagram.android',
      'com.facebook.katana',
      'com.twitter.android',
      'com.tiktok',
      'com.snapchat.android',
      'com.youtube.android',
      'com.whatsapp',
      'com.telegram.messenger',
      'com.spotify.music',
      'com.netflix.mediaclient',
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Apps to Block'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: availableApps.length,
            itemBuilder: (context, index) {
              final packageName = availableApps[index];
              final isSelected = _selectedPackages.contains(packageName);
              
              return CheckboxListTile(
                title: Text(_getAppDisplayName(packageName)),
                subtitle: Text(packageName),
                value: isSelected,
                onChanged: (selected) {
                  setState(() {
                    if (selected == true) {
                      _selectedPackages.add(packageName);
                    } else {
                      _selectedPackages.remove(packageName);
                    }
                  });
                  Navigator.pop(context);
                  _showAppSelectionDialog(); // Refresh dialog
                },
                activeColor: Colors.orange,
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _saveRule() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPackages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one app')),
      );
      return;
    }

    final rule = BlockingRule(
      id: widget.existingRule?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      description: _descriptionController.text,
      type: _selectedType,
      targetPackages: _selectedPackages,
      createdAt: widget.existingRule?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      dailyLimit: _selectedType == BlockingType.timeLimit ? _dailyLimit : null,
      sessionLimit: _selectedType == BlockingType.timeLimit ? _sessionLimit : null,
      startTime: _selectedType == BlockingType.schedule ? _startTime : null,
      endTime: _selectedType == BlockingType.schedule ? _endTime : null,
      daysOfWeek: _selectedType == BlockingType.schedule ? _selectedDays : null,
      allowEmergencyBypass: _allowEmergencyBypass,
      customBlockMessage: _customMessageController.text.isNotEmpty ? _customMessageController.text : null,
      showUsageWarning: _showUsageWarning,
      warningThreshold: _showUsageWarning ? _warningThreshold : null,
    );

    if (widget.existingRule != null) {
      _blockingService.updateRule(rule);
    } else {
      _blockingService.addRule(rule);
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Rule ${widget.existingRule != null ? 'updated' : 'created'} successfully')),
    );
  }
}

