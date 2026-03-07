import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppIconWidget extends StatelessWidget {
  final double size;

  const AppIconWidget({super.key, this.size = 42});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icon/windpad-icon.svg',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
