import 'dart:io';

import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'ar_measurement_page.dart';
import 'land_measurement.dart';

class CameraMeasurementPage extends StatefulWidget {
  const CameraMeasurementPage({super.key});

  @override
  State<CameraMeasurementPage> createState() => _CameraMeasurementPageState();
}

class _CameraMeasurementPageState extends State<CameraMeasurementPage>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  final ImagePicker _imagePicker = ImagePicker();

  bool _isInitializing = true;
  bool _isProcessing = false;
  bool _showGrid = true;

  String? _errorMessage;

  FlashMode _flashMode = FlashMode.off;

  Offset? _focusPoint;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _cameraController?.dispose();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;

    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      controller.dispose();
      _cameraController = null;
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    if (!mounted) return;

    setState(() {
      _isInitializing = true;
      _errorMessage = null;
    });

    try {
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        throw Exception('No camera was found on this device.');
      }

      CameraDescription selectedCamera = cameras.first;

      for (final camera in cameras) {
        if (camera.lensDirection == CameraLensDirection.back) {
          selectedCamera = camera;
          break;
        }
      }

      final controller = CameraController(
        selectedCamera,
        ResolutionPreset.max,
        enableAudio: false,
      );

      await controller.initialize();

      await controller.setFlashMode(_flashMode);

      if (!mounted) {
        await controller.dispose();
        return;
      }

      _cameraController = controller;

      setState(() {
        _isInitializing = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isInitializing = false;
        _errorMessage = 'Unable to start camera.\n$e';
      });
    }
  }

  Future<void> _takePicture() async {
    final controller = _cameraController;

    if (controller == null ||
        !controller.value.isInitialized ||
        controller.value.isTakingPicture) {
      return;
    }

    try {
      setState(() {
        _isProcessing = true;
      });

      final XFile image = await controller.takePicture();

      await _openImageMeasurement(image.path);
    } catch (e) {
      if (!mounted) return;

      _showMessage('Unable to take picture: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _chooseImage() async {
    try {
      setState(() {
        _isProcessing = true;
      });

      if (kIsWeb) {
        final XFile? image = await _imagePicker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 100,
        );

        if (image != null) {
          await _openImageMeasurement(image.path);
        }

        return;
      }

      if (Platform.isAndroid || Platform.isIOS) {
        final XFile? image = await _imagePicker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 100,
        );

        if (image != null) {
          await _openImageMeasurement(image.path);
        }

        return;
      }

      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: false,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final path = result.files.single.path;

      if (path == null || path.isEmpty) {
        _showMessage('Unable to access the selected image.');
        return;
      }

      await _openImageMeasurement(path);
    } catch (e) {
      if (mounted) {
        _showMessage('Unable to select image: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _openImageMeasurement(String imagePath) async {
    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ARMeasurementPage(
          imagePath: imagePath,
        ),
      ),
    );
  }

  void _openManualMeasurement() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const LandMeasurementPage(),
      ),
    );
  }

  Future<void> _cycleFlashMode() async {
    final controller = _cameraController;

    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    FlashMode nextMode;

    switch (_flashMode) {
      case FlashMode.off:
        nextMode = FlashMode.auto;
        break;
      case FlashMode.auto:
        nextMode = FlashMode.always;
        break;
      case FlashMode.always:
        nextMode = FlashMode.torch;
        break;
      case FlashMode.torch:
        nextMode = FlashMode.off;
        break;
    }

    try {
      await controller.setFlashMode(nextMode);

      if (mounted) {
        setState(() {
          _flashMode = nextMode;
        });
      }
    } catch (e) {
      _showMessage('Flash mode is not supported on this camera.');
    }
  }

  IconData _flashIcon() {
    switch (_flashMode) {
      case FlashMode.off:
        return Icons.flash_off;
      case FlashMode.auto:
        return Icons.flash_auto;
      case FlashMode.always:
        return Icons.flash_on;
      case FlashMode.torch:
        return Icons.highlight;
    }
  }

  void _focusCamera(
    TapDownDetails details,
    BoxConstraints constraints,
  ) {
    final controller = _cameraController;

    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    final RenderBox? box = context.findRenderObject() as RenderBox?;

    if (box == null) return;

    final Offset localPosition = box.globalToLocal(details.globalPosition);

    final double x = (localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0);

    final double y = (localPosition.dy / constraints.maxHeight).clamp(0.0, 1.0);

    setState(() {
      _focusPoint = Offset(x, y);
    });

    try {
      controller.setFocusPoint(Offset(x, y));
      controller.setExposurePoint(Offset(x, y));
    } catch (_) {
      // Some desktop cameras do not support manual focus.
    }

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _focusPoint = null;
        });
      }
    });
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildCameraPreview() {
    final controller = _cameraController;

    if (controller == null || !controller.value.isInitialized) {
      return Container(
        color: Colors.black,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(
          color: Colors.white,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTapDown: (details) {
            _focusCamera(details, constraints);
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              CameraPreview(controller),
              if (_showGrid)
                CustomPaint(
                  painter: CameraGridPainter(),
                ),
              if (_focusPoint != null)
                Positioned(
                  left: _focusPoint!.dx * constraints.maxWidth - 24,
                  top: _focusPoint!.dy * constraints.maxHeight - 24,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.yellow,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Place a ruler or known scale inside the measurement area.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCameraUnavailable() {
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.no_photography_outlined,
            color: Colors.white70,
            size: 70,
          ),
          const SizedBox(height: 18),
          Text(
            _errorMessage ?? 'Camera is unavailable.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _initializeCamera,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Camera Measurement',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _showGrid = !_showGrid;
              });
            },
            tooltip: 'Toggle grid',
            icon: Icon(
              _showGrid ? Icons.grid_on : Icons.grid_off,
            ),
          ),
          IconButton(
            onPressed: _cycleFlashMode,
            tooltip: 'Flash',
            icon: Icon(_flashIcon()),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isInitializing
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  )
                : _errorMessage != null
                    ? _buildCameraUnavailable()
                    : _buildCameraPreview(),
          ),
          if (_isProcessing)
            const LinearProgressIndicator(
              minHeight: 3,
            ),
          Container(
            color: Colors.black,
            padding: const EdgeInsets.fromLTRB(
              16,
              14,
              16,
              18,
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  const Text(
                    'Choose how you want to measure',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _CameraActionButton(
                          icon: Icons.camera_alt,
                          label: 'Take Picture',
                          backgroundColor: const Color(0xFF2E7D32),
                          onPressed: _isProcessing ? null : _takePicture,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _CameraActionButton(
                          icon: Icons.photo_library_outlined,
                          label: 'Select From Gallery',
                          backgroundColor: Colors.blueGrey.shade700,
                          onPressed: _isProcessing ? null : _chooseImage,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isProcessing ? null : _openManualMeasurement,
                      icon: const Icon(
                        Icons.straighten,
                      ),
                      label: const Text(
                        'Calculate Manually',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(
                          color: Colors.white54,
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final VoidCallback? onPressed;

  const _CameraActionButton({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(
        label,
        textAlign: TextAlign.center,
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          vertical: 14,
        ),
      ),
    );
  }
}

class CameraGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..strokeWidth = 1;

    final double thirdWidth = size.width / 3;
    final double thirdHeight = size.height / 3;

    for (int i = 1; i < 3; i++) {
      canvas.drawLine(
        Offset(thirdWidth * i, 0),
        Offset(thirdWidth * i, size.height),
        paint,
      );

      canvas.drawLine(
        Offset(0, thirdHeight * i),
        Offset(size.width, thirdHeight * i),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant CameraGridPainter oldDelegate,
  ) {
    return false;
  }
}
