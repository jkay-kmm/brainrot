import 'package:flutter/material.dart';
import '../../data/services/permission_service.dart';

class PermissionSetupScreen extends StatefulWidget {
  const PermissionSetupScreen({super.key});

  @override
  State<PermissionSetupScreen> createState() => _PermissionSetupScreenState();
}

class _PermissionSetupScreenState extends State<PermissionSetupScreen> {
  final PermissionService _permissionService = PermissionService();
  PermissionStatus? _permissionStatus;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    setState(() => _isLoading = true);

    try {
      final status = await _permissionService.checkAllPermissions();
      setState(() {
        _permissionStatus = status;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking permissions: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFE4B5),
      appBar: AppBar(
        title: const Text('Setup App Blocking'),
        backgroundColor: const Color(0xFFFFE4B5),
        elevation: 0,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.security,
                            size: 60,
                            color: Colors.orange,
                          ),
                          const SizedBox(height: 15),
                          const Text(
                            'Enable App Blocking',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Grant the following permissions to start blocking distracting apps',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Permission items
                    _buildPermissionItem(
                      title: 'Display over other apps',
                      description:
                          'Shows block screen when you try to open blocked apps',
                      icon: Icons.phone_android,
                      isGranted:
                          _permissionStatus?.hasOverlayPermission ?? false,
                      onTap:
                          () => _permissionService.requestOverlayPermission(),
                    ),

                    const SizedBox(height: 15),

                    _buildPermissionItem(
                      title: 'Accessibility Service',
                      description:
                          'Detects when apps are opened to apply blocking rules',
                      icon: Icons.accessibility,
                      isGranted:
                          _permissionStatus?.hasAccessibilityPermission ??
                          false,
                      onTap:
                          () =>
                              _permissionService
                                  .requestAccessibilityPermission(),
                    ),

                    const SizedBox(height: 30),

                    // Setup guide
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.info, color: Colors.blue),
                              SizedBox(width: 10),
                              Text(
                                'Setup Instructions',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          Text(
                            _permissionService.getPermissionSetupGuide(),
                            style: const TextStyle(fontSize: 14, height: 1.5),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _checkPermissions,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                            ),
                            child: const Text(
                              'Check Again',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _requestAllPermissions,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                            ),
                            child: const Text(
                              'Grant Permissions',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Complete setup button
                    if (_permissionStatus?.allPermissionsGranted == true)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _completeSetup,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          child: const Text(
                            'Complete Setup & Start Blocking',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
    );
  }

  Widget _buildPermissionItem({
    required String title,
    required String description,
    required IconData icon,
    required bool isGranted,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isGranted ? Colors.green : Colors.orange,
          width: 2,
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: (isGranted ? Colors.green : Colors.orange).withOpacity(0.2),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Icon(
            icon,
            color: isGranted ? Colors.green : Colors.orange,
            size: 24,
          ),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(description),
        trailing:
            isGranted
                ? const Icon(Icons.check_circle, color: Colors.green, size: 30)
                : ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Grant'),
                ),
        onTap: isGranted ? null : onTap,
      ),
    );
  }

  Future<void> _requestAllPermissions() async {
    setState(() => _isLoading = true);

    try {
      await _permissionService.requestAllPermissions();

      // Wait a bit for user to potentially grant permissions
      await Future.delayed(const Duration(seconds: 2));

      // Check permissions again
      await _checkPermissions();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error requesting permissions: $e')),
        );
      }
    }
  }

  Future<void> _completeSetup() async {
    setState(() => _isLoading = true);

    try {
      // Start the blocking service
      final success = await _permissionService.startBlockingService();

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('App blocking is now active!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        }
      } else {
        throw Exception('Failed to start blocking service');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting blocking service: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
