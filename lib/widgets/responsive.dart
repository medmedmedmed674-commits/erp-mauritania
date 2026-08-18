import 'package:flutter/material.dart';

/// Responsive breakpoints used across the app.
/// Aligns with Material 3 window-size classes plus a custom
/// split-screen breakpoint for POS-style multi-pane layouts.
class FormFactor {
  const FormFactor._();

  static const double phone = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
  static const double split = 1024;
}

enum DeviceType { mobile, tablet, desktop }

/// Helper that exposes layout decisions based on the available width.
class Responsive extends StatelessWidget {
  const Responsive({
    super.key,
    required this.builder,
  });

  final Widget Function(BuildContext context, DeviceType device, BoxConstraints constraints)
      builder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final device = width < FormFactor.phone
            ? DeviceType.mobile
            : width < FormFactor.tablet
                ? DeviceType.tablet
                : DeviceType.desktop;
        return builder(context, device, constraints);
      },
    );
  }
}

/// Convenience extensions on [BuildContext] for quick breakpoint checks.
extension ResponsiveContext on BuildContext {
  bool get isMobile => MediaQuery.sizeOf(this).width < FormFactor.phone;
  bool get isTablet =>
      MediaQuery.sizeOf(this).width >= FormFactor.phone &&
      MediaQuery.sizeOf(this).width < FormFactor.tablet;
  bool get isDesktop => MediaQuery.sizeOf(this).width >= FormFactor.tablet;
  bool get isSplit => MediaQuery.sizeOf(this).width >= FormFactor.split;

  /// Recommended grid cross-axis count per device class.
  int gridCrossAxisCount({int? mobile, int? tablet, int? desktop}) {
    final width = MediaQuery.sizeOf(this).width;
    if (width < FormFactor.phone) return mobile ?? 2;
    if (width < FormFactor.tablet) return tablet ?? 3;
    return desktop ?? 4;
  }
}

/// A configurable 12-column-ish responsive gap.
class ResponsiveGap extends StatelessWidget {
  const ResponsiveGap({super.key, this.mobile = 8, this.tablet = 16, this.desktop = 24});
  final double mobile;
  final double tablet;
  final double desktop;

  @override
  Widget build(BuildContext context) {
    return Responsive(
      builder: (context, device, _) {
        final size = switch (device) {
          DeviceType.mobile => mobile,
          DeviceType.tablet => tablet,
          DeviceType.desktop => desktop,
        };
        return SizedBox(width: size, height: size);
      },
    );
  }
}
