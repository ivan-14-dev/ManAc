import 'dart:io';
import 'package:flutter/material.dart';

/// A safe image widget that handles missing files, empty paths, and errors
class SafeImage extends StatelessWidget {
  final String? imagePath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;

  const SafeImage({
    super.key,
    this.imagePath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    // If no path, show placeholder
    if (imagePath == null || imagePath!.isEmpty) {
      return _buildPlaceholder();
    }

    // Check if it's a network URL
    if (imagePath!.startsWith('http://') || imagePath!.startsWith('https://')) {
      return _buildNetworkImage();
    }

    // It's a file path
    return _buildFileImage();
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: borderRadius,
      ),
      child: placeholder ?? 
        const Icon(Icons.image, color: Colors.grey, size: 40),
    );
  }

  Widget _buildNetworkImage() {
    final imageWidget = Image.network(
      imagePath!,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: width,
          height: height,
          color: Colors.grey[200],
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return _buildErrorPlaceholder();
      },
    );

    return borderRadius != null
        ? ClipRRect(borderRadius: borderRadius!, child: imageWidget)
        : imageWidget;
  }

  Widget _buildFileImage() {
    final file = File(imagePath!);
    
    if (!file.existsSync()) {
      return _buildErrorPlaceholder();
    }

    final imageWidget = Image.file(
      file,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return _buildErrorPlaceholder();
      },
    );

    return borderRadius != null
        ? ClipRRect(borderRadius: borderRadius!, child: imageWidget)
        : imageWidget;
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: borderRadius,
      ),
      child: errorWidget ?? 
        const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image, color: Colors.grey, size: 30),
            SizedBox(height: 4),
            Text(
              'Image non disponible',
              style: TextStyle(color: Colors.grey, fontSize: 10),
            ),
          ],
        ),
    );
  }
}

/// Extension to easily use SafeImage with optional parameters
extension SafeImageExtension on String? {
  Widget toSafeImage({
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    return SafeImage(
      imagePath: this,
      width: width,
      height: height,
      fit: fit,
      borderRadius: borderRadius,
      placeholder: placeholder,
      errorWidget: errorWidget,
    );
  }
}
