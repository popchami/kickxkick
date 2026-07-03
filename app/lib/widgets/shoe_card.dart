import 'dart:io';

import 'package:flutter/material.dart';

class ShoeCard extends StatelessWidget {
  final String brandName;
  final String modelName;
  final String size;
  final String color;
  final String? statusLabel;
  final String? imagePath;
  final String? archiveNumber;
  final VoidCallback onTap;

  const ShoeCard({
    super.key,
    required this.brandName,
    required this.modelName,
    required this.size,
    required this.color,
    this.statusLabel,
    this.imagePath,
    this.archiveNumber,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 130;
        final tiny = constraints.maxWidth < 90;
        final titleFontSize = (constraints.maxWidth * 0.11).clamp(10.0, 16.0);
        final panelPadding = (constraints.maxWidth * 0.07).clamp(5.0, 12.0);
        final colors = Theme.of(context).colorScheme;

        return GestureDetector(
          onTap: onTap,
          child: Card(
            clipBehavior: Clip.antiAlias,
            color: colors.surface.withValues(alpha: 0.88),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: colors.outlineVariant.withValues(alpha: 0.55),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ColoredBox(
                    color: colors.surfaceContainerHighest,
                    child: SizedBox.expand(
                      child: _ShoeImage(imagePath: imagePath),
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(panelPadding),
                  decoration: BoxDecoration(
                    color: colors.surface.withValues(alpha: 0.82),
                    border: Border(
                      top: BorderSide(
                        color: colors.outlineVariant.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        modelName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: colors.onSurface,
                              fontWeight: FontWeight.w700,
                              fontSize: titleFontSize,
                              height: 1.08,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (!tiny) ...[
                        SizedBox(height: compact ? 2 : 4),
                        Text(
                          brandName,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: colors.onSurfaceVariant,
                                fontSize: compact ? 9 : null,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (!compact && statusLabel?.isNotEmpty == true) ...[
                        const SizedBox(height: 4),
                        Text(
                          statusLabel!,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: colors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                      if (!compact && archiveNumber != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          archiveNumber!,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: colors.onSurfaceVariant,
                                fontSize: 10,
                                letterSpacing: 0.5,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ShoeImage extends StatelessWidget {
  final String? imagePath;

  const _ShoeImage({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    final path = imagePath;
    if (path == null || path.isEmpty) {
      return _ImagePlaceholder(
        iconColor: Theme.of(context).colorScheme.outline,
      );
    }

    return Image.file(
      File(path),
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, __, ___) => _ImagePlaceholder(
        iconColor: Theme.of(context).colorScheme.outline,
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  final Color iconColor;

  const _ImagePlaceholder({required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        Icons.image_outlined,
        size: 64,
        color: iconColor,
      ),
    );
  }
}
