import 'dart:async';
import 'dart:io';

import 'package:app_envio/models/pending_upload.dart';
import 'package:app_envio/services/auth_service.dart';
import 'package:app_envio/services/image_service.dart';
import 'package:app_envio/services/sync_service.dart';
import 'package:app_envio/view/components/upload_tile.dart';
import 'package:app_envio/view/components/custom_app_bar.dart';
import 'package:app_envio/view/components/custom_scaffold.dart';
import 'package:app_envio/view/components/stat_item.dart';
import 'package:app_envio/view/edit_user_page.dart';
import 'package:app_envio/view/my_properties_page.dart';
import 'package:flutter/material.dart';

enum ImageSource { camera, gallery }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ImageService _imageService = ImageService();
  final SyncService _syncService = SyncService();
  List<PendingUpload> _uploads = [];
  bool _isLoading = false;
  bool _isSyncing = false;
  late StreamSubscription<void> _uploadsSubscription;
  late StreamSubscription<bool> _connectionSubscription;
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    _syncService.initialize();
    _loadUploads();

    _uploadsSubscription = _imageService.onUploadsChanged.listen((_) {
      _loadUploads();
    });

    _connectionSubscription = _syncService.onConnectionStatusChanged.listen((
      isConnected,
    ) {
      if (!mounted) return;
      setState(() => _isConnected = isConnected);

      if (!isConnected) {
        _showConnectionLost();
      } else {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
      }
    });
  }

  @override
  void dispose() {
    _uploadsSubscription.cancel();
    _connectionSubscription.cancel();
    _syncService.dispose();
    super.dispose();
  }

  Future<void> _loadUploads() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final uploads = await _imageService.getAllUploads();
      if (!mounted) return;
      setState(() => _uploads = uploads);
    } catch (e) {
      if (!mounted) return;
      _showError('Erro ao carregar uploads: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      List<File> imageFiles = [];

      if (source == ImageSource.camera) {
        final imageFile = await _imageService.takePhoto();
        if (imageFile != null) {
          imageFiles.add(imageFile);
        }
      } else {
        imageFiles = await _imageService.pickMultipleImagesFromGallery();
      }

      if (imageFiles.isEmpty) return;

      setState(() => _isLoading = true);

      int successCount = 0;
      for (final imageFile in imageFiles) {
        final upload = await _imageService.saveImageForUpload(imageFile);
        if (upload != null) {
          successCount++;
        }
      }

      if (successCount > 0) {
        if (!mounted) return;
        _showSuccess(
          '$successCount imagem(ns) salva(s)! Serão enviadas quando houver conexão.',
        );
        await _loadUploads();
        _syncUploads();
      } else {
        if (!mounted) return;
        _showError('Erro ao salvar imagens');
      }
    } catch (e) {
      if (!mounted) return;
      _showError('Erro: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _syncUploads() async {
    if (_isSyncing) return;

    if (!mounted) return;
    setState(() => _isSyncing = true);

    try {
      final result = await _syncService.syncUploads();
      if (!mounted) return;

      if (result.status == SyncStatus.offline) {
        setState(() => _isConnected = false);
        _showConnectionLost();
      } else {
        if (_isConnected == false) {
          setState(() => _isConnected = true);
          ScaffoldMessenger.of(context).removeCurrentSnackBar();
        }

        if (result.hasSuccess) {
          _showSuccess(result.message);
          await _loadUploads();
        } else if (result.totalAttempted > 0) {
          _showError(result.message);
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  Future<void> _handleLogout(
    AuthService authService,
    BuildContext dialogContext,
  ) async {
    Navigator.pop(dialogContext);

    try {
      await authService.logout();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _openEditUserPage() async {
    final updated = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const EditUserPage()));

    if (updated == true) {
      await AuthService().currentUser?.reload();
      if (!mounted) return;
      setState(() {});
    }
  }

  Future<void> _openMyPropertiesPage() async {
    await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const MyPropertiesPage()));
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Tirar Foto'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Escolher da Galeria'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showConnectionLost() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.cloud_off, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Sem conexão. Uploads serão enviados quando conectar.',
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: Duration(days: 1),
      ),
    );
  }

  void _showPhotographyGuide() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.95,
        ),
        child: SafeArea(child: _buildGuideTab(context)),
      ),
    );
  }

  Widget _buildUploadsTab(
    BuildContext context, {
    required int pendingCount,
    required int uploadingCount,
    required int completedCount,
    required int failedCount,
  }) {
    if (_uploads.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 20),
            Text(
              'Nenhuma imagem ainda',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              'Toque em + para começar',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primaryContainer,
                Theme.of(
                  context,
                ).colorScheme.primaryContainer.withValues(alpha: 0.9),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 6,
                spreadRadius: 3,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              StatItem(
                icon: Icons.cloud_upload,
                label: 'Pendentes',
                count: pendingCount,
                color: Colors.orange,
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.black.withValues(alpha: 0.1),
              ),
              StatItem(
                icon: Icons.cloud_sync,
                label: 'Enviando',
                count: uploadingCount,
                color: Colors.blue,
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.black.withValues(alpha: 0.1),
              ),
              StatItem(
                icon: Icons.cloud_done,
                label: 'Completas',
                count: completedCount,
                color: Colors.green.shade400,
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.black.withValues(alpha: 0.1),
              ),
              StatItem(
                icon: Icons.cloud_off,
                label: 'Erros',
                count: failedCount,
                color: Colors.red,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _uploads.length,
            itemBuilder: (context, index) {
              final upload = _uploads[index];
              return UploadTile(
                upload: upload,
                onDelete: (deleteFromFirebase) async {
                  try {
                    await _imageService.deleteUpload(
                      upload,
                      deleteFromFirebase: deleteFromFirebase,
                    );
                    await _loadUploads();
                    if (!mounted) return;
                    _showSuccess('Upload excluído com sucesso.');
                  } catch (e) {
                    if (!mounted) return;
                    _showError('Erro ao excluir upload: $e');
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGuideTab(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Como tirar as fotos',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Siga as orientações para manter um padrão na captura das imagens:',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/images/example_photo.jpeg',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(
                  height: 180,
                  child: Center(
                    child: Text(
                      'Não foi possível carregar a imagem de exemplo.',
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.flight),
            title: const Text('Drone'),
            subtitle: const Text(
              'Faça fotos de cima, mostrando um conjunto de plantas na área de cultivo.',
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.smartphone),
            title: const Text('Celular'),
            subtitle: const Text(
              'Tire fotos na lateral da planta para destacar folhas, caule e estrutura.',
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.description),
            title: const Text('Use o papel como fundo'),
            subtitle: const Text(
              'Nas fotos com celular, segure uma folha de papel atrás da planta, como no exemplo acima.',
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.wb_sunny),
            title: const Text('Mantenha boa iluminação e foco'),
            subtitle: const Text(
              'Verifique as fotos antes de enviar. Evite fotos desfocadas, muito escuras ou tremidas.',
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final user = authService.currentUser;
    final pendingCount = _uploads
        .where((u) => u.status == UploadStatus.pending)
        .length;
    final uploadingCount = _uploads
        .where((u) => u.status == UploadStatus.uploading)
        .length;
    final completedCount = _uploads
        .where((u) => u.status == UploadStatus.completed)
        .length;
    final failedCount = _uploads
        .where((u) => u.status == UploadStatus.failed)
        .length;

    return CustomScaffold(
      appBar: CustomAppBar(
        leading: InkWell(
          onTap: _openEditUserPage,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.person, color: Colors.white, size: 24),
            ),
          ),
        ),
        title: user?.displayName ?? 'Usuário',
        subtitle: user?.email ?? '',
        actions: [
          if (pendingCount > 0 || failedCount > 0)
            CustomAppBarAction(
              child: Badge(
                label: Text('${pendingCount + failedCount}'),
                child: IconButton(
                  icon: _isSyncing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.cloud_upload, color: Colors.white),
                  onPressed: _isSyncing ? null : _syncUploads,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                ),
              ),
            ),
          CustomAppBarAction(
            child: IconButton(
              icon: const Icon(
                Icons.add_home_work_outlined,
                color: Colors.white,
              ),
              tooltip: 'Minhas propriedades',
              onPressed: _openMyPropertiesPage,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
          ),
          CustomAppBarAction(
            child: IconButton(
              icon: const Icon(Icons.info_outline, color: Colors.white),
              tooltip: 'Como fotografar',
              onPressed: _showPhotographyGuide,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
          ),
          CustomAppBarAction(
            child: IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: () => showDialog(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Tem certeza que deseja sair?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () =>
                          _handleLogout(authService, dialogContext),
                      child: const Text('Sair'),
                    ),
                  ],
                ),
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showImageOptions,
        child: const Icon(Icons.add_a_photo),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildUploadsTab(
              context,
              pendingCount: pendingCount,
              uploadingCount: uploadingCount,
              completedCount: completedCount,
              failedCount: failedCount,
            ),
    );
  }
}
