import 'package:flutter/material.dart';

class SyncStatusIcon extends StatelessWidget {
  final String syncStatus;
  const SyncStatusIcon({super.key, required this.syncStatus});

  @override
  Widget build(BuildContext context) {
    final synced = syncStatus == 'synced';
    return Tooltip(
      message: synced ? 'Synced' : 'Pending sync',
      child: Icon(
        synced ? Icons.check_circle : Icons.hourglass_top,
        color: synced ? Colors.green : Colors.orange,
        size: 18,
      ),
    );
  }
}
