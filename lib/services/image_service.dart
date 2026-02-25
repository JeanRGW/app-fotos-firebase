import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../database/database_helper.dart';
import '../models/pending_upload.dart';
import 'firestore_upload_service.dart';

class ImageService {
  static final ImageService _instance = ImageService._internal();

  factory ImageService() => _instance;

  ImageService._internal();

  final ImagePicker _picker = ImagePicker();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirestoreUploadService _firestoreService = FirestoreUploadService();
  final Uuid _uuid = const Uuid();

  final StreamController<void> _uploadsChangedController =
      StreamController<void>.broadcast();

  // Habilitar salvamento na Firestore
  final bool saveToFirestore = true;

  Stream<void> get onUploadsChanged => _uploadsChangedController.stream;

  void _notifyUploadsChanged() {
    _uploadsChangedController.add(null);
  }

  // Escolher uma imagem da galeria
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 3840,
        maxHeight: 3840,
        imageQuality: 95,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Tirar uma foto usando a câmera
  Future<File?> takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 3840,
        maxHeight: 3840,
        imageQuality: 95,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Escolher múltiplas imagens da galeria
  Future<List<File>> pickMultipleImagesFromGallery() async {
    try {
      final pickedFiles = await _picker.pickMultiImage(
        maxWidth: 3840,
        maxHeight: 3840,
        imageQuality: 95,
        limit: 100,
      );

      return pickedFiles.map((xFile) => File(xFile.path)).toList();
    } catch (e) {
      return [];
    }
  }

  // Salvar cópia da imagem para upload posterior
  Future<String> _saveImageToAppDirectory(File imageFile) async {
    final appDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${appDir.path}/pending_images');

    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    final fileName = '${_uuid.v4()}${path.extension(imageFile.path)}';
    final newPath = '${imagesDir.path}/$fileName';

    await imageFile.copy(newPath);
    return newPath;
  }

  // Obter localização atual do dispositivo ou null se não for possível
  Future<Position?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      print('DEBUG: Obtendo localização atual...');

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 10,
        ),
      );
    } catch (e) {
      return null;
    }
  }

  // Salvar imagem para upload posterior, incluindo localização se possível
  Future<PendingUpload?> saveImageForUpload(File imageFile) async {
    try {
      // Salvar (armazenar) a imagem
      final savedPath = await _saveImageToAppDirectory(imageFile);

      Position? position = await getCurrentLocation();

      print("DEBUG: position = $position");

      // Objeto de upload pendente
      final upload = PendingUpload(
        id: _uuid.v4(),
        imagePath: savedPath,
        latitude: position?.latitude,
        longitude: position?.longitude,
        createdAt: DateTime.now(),
        status: UploadStatus.pending,
      );

      // Salvar no banco de dados
      await _dbHelper.insertPendingUpload(upload.toMap());
      _notifyUploadsChanged();

      return upload;
    } catch (e) {
      return null;
    }
  }

  // Realizar upload de fato
  Future<String?> uploadImageToFirebase(PendingUpload upload) async {
    try {
      final file = File(upload.imagePath);
      if (!await file.exists()) {
        throw Exception('Erro: arquivo da imagem não encontrado');
      }

      await _dbHelper.updateUploadStatus(upload.id, 'uploading');
      _notifyUploadsChanged();

      // Montar caminho no Firebase Storage: uploads/{userId}/{uploadId}/{fileName}
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('Erro: usuário não autenticado');
      }

      final fileName = path.basename(upload.imagePath);
      final storageRef = _storage.ref().child(
        'uploads/$userId/${upload.id}/$fileName',
      );

      // Metadados do arquivo
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploadId': upload.id,
          'uploadedAt': DateTime.now().toIso8601String(),
          if (upload.latitude != null) 'latitude': upload.latitude.toString(),
          if (upload.longitude != null)
            'longitude': upload.longitude.toString(),
        },
      );

      // Iniciar upload
      final uploadTask = storageRef.putFile(file, metadata);

      // Concluir e obter URL de download duradoura
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      await _dbHelper.updateUploadStatus(
        upload.id,
        'completed',
        firebaseUrl: downloadUrl,
      );
      _notifyUploadsChanged();

      // Salvar
      if (saveToFirestore) {
        try {
          await _firestoreService.saveUploadMetadata(
            uploadId: upload.id,
            imageUrl: downloadUrl,
            latitude: upload.latitude,
            longitude: upload.longitude,
            uploadedAt: upload.createdAt,
          );
        } catch (e) {
          print(
            'Erro ao salvar dados extras na Firestore, continuando mesmo assim: $e',
          );
        }
      }

      return downloadUrl;
    } catch (e) {
      await _dbHelper.updateUploadStatus(
        upload.id,
        'failed',
        errorMessage: e.toString(),
      );
      _notifyUploadsChanged();

      return null;
    }
  }

  Future<int> resetStuckUploads() async {
    final updatedCount = await _dbHelper.resetUploadingToPending();
    if (updatedCount > 0) {
      _notifyUploadsChanged();
    }
    return updatedCount;
  }

  Future<List<PendingUpload>> getPendingUploads() async {
    final maps = await _dbHelper.getPendingUploads();
    return maps.map((map) => PendingUpload.fromMap(map)).toList();
  }

  Future<List<PendingUpload>> getPendingAndFailedUploads() async {
    final maps = await _dbHelper.getPendingAndFailedUploads();
    return maps.map((map) => PendingUpload.fromMap(map)).toList();
  }

  Future<List<PendingUpload>> getAllUploads() async {
    final maps = await _dbHelper.getAllUploads();
    return maps.map((map) => PendingUpload.fromMap(map)).toList();
  }

  // Deleta upload e arquivo local; opcionalmente remove dados no Firebase
  Future<void> deleteUpload(
    PendingUpload upload, {
    bool deleteFromFirebase = false,
  }) async {
    try {
      if (deleteFromFirebase) {
        final userId = _auth.currentUser?.uid;
        if (userId == null) {
          throw Exception('Usuário não autenticado');
        }

        // Excluir arquivo no Storage
        if (upload.firebaseUrl != null && upload.firebaseUrl!.isNotEmpty) {
          await _storage.refFromURL(upload.firebaseUrl!).delete();
        } else {
          final uploadFolderRef = _storage.ref().child(
            'uploads/$userId/${upload.id}',
          );
          final items = await uploadFolderRef.listAll();
          for (final item in items.items) {
            await item.delete();
          }
        }

        // Excluir metadados no Firestore
        await _firestoreService.deleteUploadMetadata(upload.id);
      }

      final file = File(upload.imagePath);
      if (await file.exists()) {
        await file.delete();
      }
      await _dbHelper.deleteUpload(upload.id);
      _notifyUploadsChanged();
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
