import 'package:flutter/material.dart';
import '../../data/services/app_blocking_service.dart';
import '../../data/model/focus_mode.dart';

class FocusModeScreen extends StatefulWidget {
  const FocusModeScreen({super.key});

  @override
  State<FocusModeScreen> createState() => _FocusModeScreenState();
}

class _FocusModeScreenState extends State<FocusModeScreen> {
  final AppBlockingService _blockingService = AppBlockingService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFE4B5),
      appBar: AppBar(
        title: const Text('Focus Modes'),
        backgroundColor: const Color(0xFFFFE4B5),
        elevation: 0,
      ),
      body: StreamBuilder<List<FocusMode>>(
        stream: _blockingService.focusModesStream,
        initialData: _blockingService.focusModes,
        builder: (context, snapshot) {
          final focusModes = snapshot.data ?? [];
          final activeFocus = _blockingService.activeFocusMode;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Active focus mode section
                if (activeFocus != null) ...[
                  _buildActiveFocusSection(activeFocus),
                  const SizedBox(height: 30),
                ],
                
                // Available focus modes
                const Text(
                  'Available Focus Modes',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                
                ...focusModes.map((mode) => _buildFocusModeCard(mode)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActiveFocusSection(FocusMode focusMode) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [focusMode.color.withOpacity(0.2), focusMode.color.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: focusMode.color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: focusMode.color,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Icon(focusMode.icon, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      focusMode.name,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Currently Active',
                      style: TextStyle(fontSize: 14, color: focusMode.color, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => _stopFocusMode(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('Stop'),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Status info
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.grey, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      focusMode.statusText,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                
                if (focusMode.remainingTime != null) ...[
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: _calculateProgress(focusMode),
                    backgroundColor: Colors.grey.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(focusMode.color),
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 15),
          
          // Blocked/Allowed apps info
          Row(
            children: [
              Expanded(
                child: _buildAppCountCard(
                  'Blocked Apps',
                  focusMode.blockedPackages.length.toString(),
                  Colors.red,
                  Icons.block,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildAppCountCard(
                  'Allowed Apps',
                  focusMode.allowedPackages.length.toString(),
                  Colors.green,
                  Icons.check_circle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFocusModeCard(FocusMode focusMode) {
    final isActive = focusMode.isActive;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: Card(
        elevation: isActive ? 4 : 1,
        color: Colors.white.withOpacity(0.9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: InkWell(
          onTap: isActive ? null : () => _showStartFocusModeDialog(focusMode),
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: focusMode.color.withOpacity(isActive ? 1.0 : 0.2),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Icon(
                        focusMode.icon,
                        color: isActive ? Colors.white : focusMode.color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            focusMode.name,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            focusMode.description,
                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    if (isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Text(
                          'ACTIVE',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      )
                    else
                      const Icon(Icons.play_arrow, color: Colors.grey, size: 30),
                  ],
                ),
                
                const SizedBox(height: 15),
                
                // Focus mode details
                Row(
                  children: [
                    _buildDetailChip(
                      '${focusMode.blockedPackages.length} blocked',
                      Colors.red,
                      Icons.block,
                    ),
                    const SizedBox(width: 10),
                    _buildDetailChip(
                      '${focusMode.allowedPackages.length} allowed',
                      Colors.green,
                      Icons.check_circle,
                    ),
                  ],
                ),
                
                const SizedBox(height: 10),
                
                // Settings info
                Row(
                  children: [
                    if (!focusMode.allowNotifications)
                      _buildDetailChip('No notifications', Colors.orange, Icons.notifications_off),
                    const SizedBox(width: 10),
                    if (focusMode.allowCalls)
                      _buildDetailChip('Calls allowed', Colors.blue, Icons.phone),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppCountCard(String title, String count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 5),
          Text(
            count,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailChip(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  double _calculateProgress(FocusMode focusMode) {
    if (focusMode.duration == null || focusMode.startTime == null) return 0.0;
    
    final elapsed = DateTime.now().difference(focusMode.startTime!);
    return (elapsed.inMilliseconds / focusMode.duration!.inMilliseconds).clamp(0.0, 1.0);
  }

  void _showStartFocusModeDialog(FocusMode focusMode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: focusMode.color,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(focusMode.icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 15),
            Expanded(child: Text('Start ${focusMode.name}?')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(focusMode.description),
            const SizedBox(height: 15),
            
            // Focus mode details
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (focusMode.blockedPackages.isNotEmpty) ...[
                    Text('Will block ${focusMode.blockedPackages.length} apps', 
                         style: const TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 5),
                  ],
                  if (focusMode.allowedPackages.isNotEmpty) ...[
                    Text('Will allow ${focusMode.allowedPackages.length} apps', 
                         style: const TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 5),
                  ],
                  if (!focusMode.allowNotifications)
                    const Text('• Notifications will be blocked', 
                         style: TextStyle(color: Colors.orange)),
                  if (focusMode.allowCalls)
                    const Text('• Phone calls will be allowed', 
                         style: TextStyle(color: Colors.green)),
                ],
              ),
            ),
            
            const SizedBox(height: 15),
            const Text('Choose duration:', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 10),
            
            // Duration buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildDurationButton('15 min', const Duration(minutes: 15), focusMode),
                _buildDurationButton('30 min', const Duration(minutes: 30), focusMode),
                _buildDurationButton('1 hour', const Duration(hours: 1), focusMode),
                _buildDurationButton('2 hours', const Duration(hours: 2), focusMode),
                _buildDurationButton('4 hours', const Duration(hours: 4), focusMode),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startFocusMode(focusMode, null);
            },
            style: ElevatedButton.styleFrom(backgroundColor: focusMode.color),
            child: const Text('Start Indefinitely', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationButton(String text, Duration duration, FocusMode focusMode) {
    return ElevatedButton(
      onPressed: () {
        Navigator.pop(context);
        _startFocusMode(focusMode, duration);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: focusMode.color.withOpacity(0.2),
        foregroundColor: focusMode.color,
        elevation: 0,
      ),
      child: Text(text),
    );
  }

  void _startFocusMode(FocusMode focusMode, Duration? duration) {
    _blockingService.startFocusMode(focusMode.id, duration: duration);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${focusMode.name} started${duration != null ? ' for ${_formatDuration(duration)}' : ''}'),
        backgroundColor: focusMode.color,
      ),
    );
  }

  void _stopFocusMode() {
    _blockingService.stopFocusMode();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Focus mode stopped'),
        backgroundColor: Colors.grey,
      ),
    );
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
}
