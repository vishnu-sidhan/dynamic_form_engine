import 'package:flutter/material.dart';

class AppBrandLogo extends StatelessWidget {
  final double size;
  final Color? color;

  const AppBrandLogo({
    super.key,
    this.size = 36.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo_df.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            border: Border.all(
              color: color ?? Theme.of(context).colorScheme.primary,
              width: 2.5,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            'DF',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: size * 0.45,
              color: color ?? Theme.of(context).colorScheme.primary,
            ),
          ),
        );
      },
    );
  }
}
