import 'dart:io';

import 'package:app_envio/models/pending_upload.dart';
import 'package:flutter/material.dart';

class UploadTile extends StatelessWidget {
  final PendingUpload upload;
  final Future<void> Function(bool deleteFromFirebase) onDelete;

  const UploadTile({super.key, required this.upload, required this.onDelete});

  IconData get _statusIcon {
    return switch (upload.status) {
      UploadStatus.pending => Icons.cloud_upload,
      UploadStatus.uploading => Icons.cloud_sync,
      UploadStatus.completed => Icons.cloud_done,
      UploadStatus.failed => Icons.cloud_off,
    };
  }

  Color _statusColor(BuildContext context) {
    return switch (upload.status) {
      UploadStatus.pending => Colors.orange,
      UploadStatus.uploading => Colors.blue,
      UploadStatus.completed => Colors.green,
      UploadStatus.failed => Colors.red,
    };
  }

  bool get _hasLocation => upload.latitude != null && upload.longitude != null;

  void _showErrorDetails(BuildContext context) {
    if (upload.status != UploadStatus.failed || upload.errorMessage == null) {
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Falha no Upload'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A imagem não pôde ser enviada. Tente novamente mais tarde.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'Detalhes técnicos:',
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              upload.errorMessage!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _showFullscreenImage(BuildContext context, File imageFile) {
    showDialog(
      context: context,
      barrierColor: Colors.black,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Image.file(imageFile, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 40,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    bool deleteFromFirebase = false;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            'Excluir imagem',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Deseja excluir esta imagem?',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: deleteFromFirebase,
                onChanged: (value) {
                  setDialogState(() => deleteFromFirebase = value ?? false);
                },
                title: Text(
                  'Também excluir da nuvem',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                subtitle: Text(
                  'Remove a cópia online da imagem.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(
                'Cancelar',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(
                'Excluir',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ],
        ),
      ),
    );

    if (shouldDelete == true) {
      await onDelete(deleteFromFirebase);
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageFile = File(upload.imagePath);

    return GestureDetector(
      onLongPress: () => _showErrorDetails(context),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.3),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 4,
          ),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: imageFile.existsSync()
                    ? () => _showFullscreenImage(context, imageFile)
                    : null,
                child: Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey[300],
                  child: imageFile.existsSync()
                      ? Image.file(imageFile, fit: BoxFit.cover)
                      : Icon(
                          Icons.broken_image,
                          size: 40,
                          color: Colors.grey[400],
                        ),
                ),
              ),
            ),
          ),
          title: Row(
            children: [
              Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                _formatDate(upload.createdAt),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              // Indicador de localização
              if (_hasLocation)
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.blue[500]),
                    const SizedBox(width: 6),
                    Text(
                      'Localização salva',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.blue[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              // Indicador de falha
              if (upload.status == UploadStatus.failed) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.error_outline, size: 14, color: Colors.red),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Aguarde e tente novamente',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.red[600],
                          fontStyle: FontStyle.italic,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_statusIcon, color: _statusColor(context)),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 20,
                ),
                onPressed: () => _confirmDelete(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final difference = DateTime.now().difference(date);
    if (difference.inDays == 0) {
      return 'Hoje às ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Ontem às ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
    return '${date.day}/${date.month}/${date.year}';
  }
}
