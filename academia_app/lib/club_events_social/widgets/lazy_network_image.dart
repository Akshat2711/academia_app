import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// A lazy-loading image widget that only loads when visible
class LazyNetworkImage extends StatefulWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final String? cacheKey;
  final BorderRadius? borderRadius;
  final Color placeholderColor;
  final Duration fadeInDuration;

  const LazyNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.cacheKey,
    this.borderRadius,
    this.placeholderColor = const Color(0xFF0D0D0D),
    this.fadeInDuration = const Duration(milliseconds: 300),
  });

  @override
  State<LazyNetworkImage> createState() => _LazyNetworkImageState();
}

class _LazyNetworkImageState extends State<LazyNetworkImage> {
  bool _shouldLoadImage = false;

  @override
  void initState() {
    super.initState();
    // Delay image loading slightly to prioritize visible content
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() => _shouldLoadImage = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldLoadImage) {
      // Show placeholder while waiting to load
      return _buildPlaceholder();
    }

    final child = CachedNetworkImage(
      imageUrl: widget.imageUrl,
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
      cacheKey: widget.cacheKey,
      fadeInDuration: widget.fadeInDuration,
      placeholder: (context, url) => _buildPlaceholder(),
      errorWidget: (context, url, error) => Container(
        width: widget.width,
        height: widget.height,
        color: widget.placeholderColor,
        child: const Center(
          child: Icon(Icons.image_not_supported, color: Colors.white38),
        ),
      ),
    );

    if (widget.borderRadius != null) {
      return ClipRRect(
        borderRadius: widget.borderRadius!,
        child: child,
      );
    }

    return child;
  }

  Widget _buildPlaceholder() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: widget.placeholderColor,
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            color: Colors.white38,
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }
}
