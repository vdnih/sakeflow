import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

Color bottleColor(String brand) {
  if (brand.contains('獺祭')) return const Color(0xFF3D2B1F);
  if (brand.contains('久保田')) return const Color(0xFF1F2D3D);
  if (brand.contains('十四代')) return const Color(0xFF2D1F3D);
  if (brand.contains('而今')) return const Color(0xFF1F3D2B);
  if (brand.contains('新政')) return const Color(0xFF1A2A3A);
  return kSurface2;
}

class BottlePlaceholder extends StatelessWidget {
  final String brand;
  final double width;
  final double height;
  final double borderRadius;

  const BottlePlaceholder({
    super.key,
    required this.brand,
    required this.width,
    required this.height,
    this.borderRadius = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: bottleColor(brand),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: const Center(
        child: Icon(Icons.liquor_outlined, color: kTextMuted, size: 28),
      ),
    );
  }
}
