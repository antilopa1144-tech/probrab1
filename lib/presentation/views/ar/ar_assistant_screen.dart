import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

/// Экран AR-помощника (базовая версия).
class ArAssistantScreen extends StatefulWidget {
  const ArAssistantScreen({super.key});

  @override
  State<ArAssistantScreen> createState() => _ArAssistantScreenState();
}

class _ArAssistantScreenState extends State<ArAssistantScreen> {
  CameraController? _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          setState(() => _isInitialized = false);
        }
        return;
      }

      _controller = CameraController(cameras.first, ResolutionPreset.medium);

      await _controller!.initialize();
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isInitialized = false);
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized || !mounted)
      return;

    try {
      await _controller!.takePicture();
      // Изображение сохранено
      // В будущем здесь будет обработка для измерения размеров
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Изображение сохранено. Функция измерения в разработке.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка съёмки: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AR-помощник (бета)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.straighten),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Функция измерения в разработке')),
              );
            },
          ),
        ],
      ),
      body: _isInitialized && _controller != null
          ? Stack(
              children: [
                CameraPreview(_controller!),
                // Здесь можно добавить наложение измерений
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: FloatingActionButton(
                      onPressed: _takePicture,
                      child: const Icon(Icons.camera_alt),
                    ),
                  ),
                ),
              ],
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.camera_alt, size: 64),
                  const SizedBox(height: 16),
                  const Text('Камера недоступна'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _initializeCamera,
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            ),
    );
  }
}
