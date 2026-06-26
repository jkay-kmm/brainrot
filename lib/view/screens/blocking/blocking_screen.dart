import 'package:brainrot/view/screens/blocking/widgets/buildRulesTab.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/l10n.dart';
import '../../../view_model/blocking_view_model.dart';
import '../../../data/services/permission_service.dart';

class BlockingScreen extends StatefulWidget {
  const BlockingScreen({super.key});

  @override
  State<BlockingScreen> createState() => _BlockingScreenState();
}

class _BlockingScreenState extends State<BlockingScreen> {
  final PermissionService _permissionService = PermissionService();

  bool _isLoading = true;
  PermissionStatus? _permissionStatus;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() => _isLoading = false);
    });
  }

  Future<void> _checkPermissions() async {
    try {
      final status = await _permissionService.checkAllPermissions();
      setState(() => _permissionStatus = status);
    } catch (e) {
      debugPrint('Error checking permissions: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = S.of(context);

    return Consumer<BlockingViewModel>(
      builder: (context, blockingVM, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFFFE4B5),
          appBar: AppBar(
            title: Text(
              "Blocking",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            backgroundColor: const Color(0xFFFFE4B5),
            elevation: 0,
          ),
          body: buildRulesTab(blockingVM, t),
        );
      },
    );
  }
}
