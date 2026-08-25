import 'package:flutter/material.dart';

import 'app_copy.dart';

class ExportBar extends StatelessWidget {
  const ExportBar({
    super.key,
    required this.enabled,
    required this.busy,
    required this.onShare,
    required this.onDownload,
    this.downloadLabel = AppCopy.saveToPhotos,
    this.shareLabel = AppCopy.share,
  });

  final bool enabled;
  final bool busy;
  final VoidCallback onShare;
  final VoidCallback onDownload;
  final String downloadLabel;
  final String shareLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: enabled && !busy ? onShare : null,
            icon: busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.ios_share),
            label: Text(busy ? AppCopy.wait : shareLabel),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: enabled && !busy ? onDownload : null,
            icon: const Icon(Icons.photo_library_outlined),
            label: Text(downloadLabel),
          ),
        ),
      ],
    );
  }
}
