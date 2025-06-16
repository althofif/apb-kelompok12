// widgets/optimized_menu_image.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/cloudinary_service.dart';

class OptimizedMenuImage extends StatelessWidget {
  final String imageUrl;
  final String? publicId;
  final double width;
  final double height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final bool showLoadingIndicator;
  final bool showErrorIcon;

  const OptimizedMenuImage({
    Key? key,
    required this.imageUrl,
    this.publicId,
    this.width = 150,
    this.height = 150,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.showLoadingIndicator = true,
    this.showErrorIcon = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final CloudinaryService cloudinaryService = CloudinaryService();

    // Jika ada publicId, buat optimized URL
    final String displayUrl =
        publicId != null && publicId!.isNotEmpty
            ? cloudinaryService.getOptimizedUrl(
              publicId!,
              width: width.toInt(),
              height: height.toInt(),
            )
            : imageUrl;

    Widget imageWidget = CachedNetworkImage(
      imageUrl: displayUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder:
          showLoadingIndicator
              ? (context, url) => Container(
                width: width,
                height: height,
                color: Colors.grey[200],
                child: Center(
                  child: SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ),
              )
              : null,
      errorWidget:
          showErrorIcon
              ? (context, url, error) => Container(
                width: width,
                height: height,
                color: Colors.grey[200],
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_not_supported_outlined,
                      size: 40,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Image not found',
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
              : null,
    );

    // Apply border radius if provided
    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: imageWidget);
    }

    return imageWidget;
  }
}

// Alternative widget untuk grid/list dengan aspect ratio
class ResponsiveMenuImage extends StatelessWidget {
  final String imageUrl;
  final String? publicId;
  final double aspectRatio;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const ResponsiveMenuImage({
    Key? key,
    required this.imageUrl,
    this.publicId,
    this.aspectRatio = 1.0,
    this.fit = BoxFit.cover,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: OptimizedMenuImage(
        imageUrl: imageUrl,
        publicId: publicId,
        width: double.infinity,
        height: double.infinity,
        fit: fit,
        borderRadius: borderRadius,
      ),
    );
  }
}

// Hero image widget untuk detail page
class MenuHeroImage extends StatelessWidget {
  final String imageUrl;
  final String? publicId;
  final String heroTag;
  final double height;

  const MenuHeroImage({
    Key? key,
    required this.imageUrl,
    this.publicId,
    required this.heroTag,
    this.height = 250,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: heroTag,
      child: Container(
        width: double.infinity,
        height: height,
        child: OptimizedMenuImage(
          imageUrl: imageUrl,
          publicId: publicId,
          width: double.infinity,
          height: height,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

// Circular menu image untuk avatar/profile
class CircularMenuImage extends StatelessWidget {
  final String imageUrl;
  final String? publicId;
  final double radius;

  const CircularMenuImage({
    Key? key,
    required this.imageUrl,
    this.publicId,
    this.radius = 30,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: OptimizedMenuImage(
        imageUrl: imageUrl,
        publicId: publicId,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
      ),
    );
  }
}
