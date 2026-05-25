import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../models/resource_item.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'pdf_viewer_screen.dart';

const int _kMaxFileSizeBytes = 10 * 1024 * 1024;
const int _kMaxResourcesPerGroup = 20;

class ResourceVaultScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const ResourceVaultScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<ResourceVaultScreen> createState() => _ResourceVaultScreenState();
}

class _ResourceVaultScreenState extends State<ResourceVaultScreen> {
  double? _uploadProgress;

  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.link, color: AppTheme.primary),
                ),
                title: Text('Add Link',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(ctx).colorScheme.onSurface)),
                subtitle: Text('Paste a URL to any resource',
                    style: TextStyle(
                        color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                        fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showAddLink();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.upload_file, color: AppTheme.primary),
                ),
                title: Text('Upload File',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(ctx).colorScheme.onSurface)),
                subtitle: Text('PDF, DOCX, PPTX, images — max 10 MB',
                    style: TextStyle(
                        color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                        fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadFile();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddLink() {
    final titleCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Link Resource',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(ctx).colorScheme.onSurface)),
            const SizedBox(height: 16),
            TextField(
              controller: titleCtrl,
              decoration: InputDecoration(
                labelText: 'Title',
                filled: true,
                fillColor: Theme.of(ctx).scaffoldBackgroundColor,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlCtrl,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                labelText: 'URL (https://...)',
                filled: true,
                fillColor: Theme.of(ctx).scaffoldBackgroundColor,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final title = titleCtrl.text.trim();
                  final url = urlCtrl.text.trim();
                  if (title.isEmpty || url.isEmpty) return;
                  await FirestoreService()
                      .addLinkResource(widget.groupId, title, url);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Add Resource'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadFile() async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final count =
          await FirestoreService().getResourceCount(widget.groupId);
      if (count >= _kMaxResourcesPerGroup) {
        messenger.showSnackBar(SnackBar(
          content: Text(
              'This group has reached the $_kMaxResourcesPerGroup resource limit.'),
          backgroundColor: AppTheme.error,
        ));
        return;
      }
    } catch (_) {}

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'pdf', 'doc', 'docx', 'ppt', 'pptx', 'xls', 'xlsx',
        'txt', 'png', 'jpg', 'jpeg', 'gif', 'zip',
      ],
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return;

    final picked = result.files.first;

    if (picked.size > _kMaxFileSizeBytes) {
      messenger.showSnackBar(const SnackBar(
        content: Text('File exceeds the 10 MB size limit.'),
        backgroundColor: AppTheme.error,
      ));
      return;
    }

    final filePath = picked.path;
    if (filePath == null) return;

    String title = picked.name;
    if (!mounted) return;
    final titleResult = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final ctrl = TextEditingController(text: _stripExtension(picked.name));
        return AlertDialog(
          backgroundColor: Theme.of(ctx).colorScheme.surface,
          title: Text('File Title',
              style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface)),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Display title',
              filled: true,
              fillColor: Theme.of(ctx).scaffoldBackgroundColor,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel',
                    style: TextStyle(
                        color: Theme.of(ctx).colorScheme.onSurfaceVariant))),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white),
              child: const Text('Upload'),
            ),
          ],
        );
      },
    );

    if (titleResult == null || titleResult.isEmpty) return;
    title = titleResult;

    if (!mounted) return;
    setState(() => _uploadProgress = 0);

    try {
      final result = await StorageService().uploadResourceFile(
        widget.groupId,
        File(filePath),
        picked.name,
        onProgress: (p) {
          if (mounted) setState(() => _uploadProgress = p);
        },
      );

      await FirestoreService().addFileResource(
        widget.groupId,
        title: title,
        fileName: picked.name,
        fileSize: picked.size,
        downloadUrl: result.url,
        storagePath: result.storagePath,
      );
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(
          content: Text('Upload failed: $e'),
          backgroundColor: AppTheme.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _uploadProgress = null);
    }

    if (!mounted) return;
    navigator.pop();
  }

  String _stripExtension(String name) {
    final dot = name.lastIndexOf('.');
    return dot > 0 ? name.substring(0, dot) : name;
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0.5,
        leading: const BackButton(color: AppTheme.primary),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resource Vault',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                    height: 1.4)),
            Text(widget.groupName,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: AppTheme.primary),
            onPressed: _showAddOptions,
          ),
        ],
      ),
      body: Stack(
        children: [
          StreamBuilder<List<ResourceItem>>(
            stream: FirestoreService().resourcesStream(widget.groupId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final resources = snapshot.data ?? [];
              if (resources.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.folder_open_outlined,
                          size: 56,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant
                              .withValues(alpha: 0.4)),
                      const SizedBox(height: 12),
                      Text('No resources yet',
                          style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              fontSize: 15)),
                      const SizedBox(height: 4),
                      Text('Tap + to add a link or upload a file',
                          style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              fontSize: 13)),
                    ],
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: resources.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final r = resources[i];
                  return _ResourceTile(
                    resource: r,
                    canDelete: r.uploadedBy == myUid,
                    onDelete: () => FirestoreService()
                        .deleteResource(widget.groupId, r.id),
                  );
                },
              );
            },
          ),
          if (_uploadProgress != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: Theme.of(context).colorScheme.surface,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Uploading…',
                        style: TextStyle(
                            fontSize: 13,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: _uploadProgress,
                      color: AppTheme.primary,
                      backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddOptions,
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _ResourceTile extends StatelessWidget {
  final ResourceItem resource;
  final bool canDelete;
  final VoidCallback onDelete;

  const _ResourceTile({
    required this.resource,
    required this.canDelete,
    required this.onDelete,
  });

  Future<void> _open(BuildContext context) async {
    final ext = (resource.fileName ?? '').split('.').last.toLowerCase();
    if (ext == 'pdf') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfViewerScreen(
            url: resource.url,
            title: resource.fileName ?? resource.title,
          ),
        ),
      );
      return;
    }
    final uri = Uri.tryParse(resource.url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  IconData get _icon {
    if (resource.type == 'link') return Icons.link;
    final ext = (resource.fileName ?? '').split('.').last.toLowerCase();
    if (ext == 'pdf') return Icons.picture_as_pdf_outlined;
    if (['png', 'jpg', 'jpeg', 'gif'].contains(ext)) return Icons.image_outlined;
    if (['ppt', 'pptx'].contains(ext)) return Icons.slideshow_outlined;
    if (['xls', 'xlsx'].contains(ext)) return Icons.table_chart_outlined;
    if (['doc', 'docx'].contains(ext)) return Icons.description_outlined;
    return Icons.insert_drive_file_outlined;
  }

  String? get _subtitle {
    if (resource.type == 'link') return resource.url;
    final name = resource.fileName;
    final size = resource.fileSize;
    if (name == null) return null;
    if (size == null) return name;
    return '$name  ·  ${_formatBytes(size)}';
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _open(context),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_icon, color: AppTheme.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(resource.title,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface)),
                  const SizedBox(height: 3),
                  if (_subtitle != null)
                    Text(_subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: resource.type == 'link'
                                ? AppTheme.primary
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 12)),
                  const SizedBox(height: 3),
                  Text('by ${resource.uploadedByName}',
                      style: TextStyle(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 11)),
                ],
              ),
            ),
            if (canDelete)
              IconButton(
                icon: Icon(Icons.delete_outline,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 20),
                onPressed: onDelete,
              )
            else
              Icon(Icons.open_in_new,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 18),
          ],
        ),
      ),
    );
  }
}
