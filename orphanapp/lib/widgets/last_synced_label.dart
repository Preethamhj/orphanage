import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LastSyncedLabel extends StatelessWidget {
  final DateTime? lastSyncedAt;
  const LastSyncedLabel({super.key, required this.lastSyncedAt});

  @override
  Widget build(BuildContext context) {
    final text = lastSyncedAt == null
        ? 'Last synced: -'
        : 'Last synced: ${DateFormat('dd MMM, hh:mm a').format(lastSyncedAt!)}';

    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
        ),
      ),
    );
  }
}
