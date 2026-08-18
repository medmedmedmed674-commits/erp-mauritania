import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Animated celebration banner shown after a successful registration
/// or login. Confetti-style animated dots + brand-aligned success
/// card with a single "متابعة" CTA.
///
/// Shown via [showCelebrationDialog] helper from any screen.
class CelebrationDialog extends StatefulWidget {
  const CelebrationDialog({
    super.key,
    this.title = 'مبروك! تم تسجيل حسابك',
    this.subtitle = 'في نظام ERP موريتانيا',
    this.ctaLabel = 'متابعة إلى لوحة التحكم',
    required this.onContinue,
  });

  final String title;
  final String subtitle;
  final String ctaLabel;
  final VoidCallback onContinue;

  @override
  State<CelebrationDialog> createState() => _CelebrationDialogState();
}

class _CelebrationDialogState extends State<CelebrationDialog>
    with TickerProviderStateMixin {
  late final AnimationController _scaleController = AnimationController(
    duration: const Duration(milliseconds: 360),
    vsync: this,
  );
  late final AnimationController _confettiController = AnimationController(
    duration: const Duration(seconds: 2),
    vsync: this,
  )..repeat();

  late final Animation<double> _scale =
      Tween<double>(begin: 0.7, end: 1.0).animate(
    CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ),
  );

  @override
  void initState() {
    super.initState();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Confetti layer
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _confettiController,
                    builder: (context, _) {
                      return CustomPaint(
                        painter: _ConfettiPainter(
                          progress: _confettiController.value,
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Main card
              ScaleTransition(
                scale: _scale,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppTheme.success.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            AppTheme.success.withValues(alpha: 0.2),
                        blurRadius: 32,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Trophy icon
                      Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.celebration_outlined,
                          size: 56,
                          color: AppTheme.success,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.subtitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Feature pills
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: const [
                          _FeaturePill(
                              icon: Icons.point_of_sale, label: 'نقطة بيع'),
                          _FeaturePill(
                              icon: Icons.inventory_2_outlined,
                              label: 'مخزون'),
                          _FeaturePill(
                              icon: Icons.analytics_outlined,
                              label: 'تقارير'),
                        ],
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.success,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: widget.onContinue,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(widget.ctaLabel),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_back, size: 18),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: AppTheme.primary),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// A simple confetti painter: colored rectangles falling from the top
/// of the dialog box, repeating every 2 seconds.
class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.progress});
  final double progress;

  static const _colors = [
    Color(0xFFD4A24E),
    Color(0xFF1F9D63),
    Color(0xFF2E7DD2),
    Color(0xFFD64545),
    Color(0xFF6B4FBB),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rng = List<int>.generate(30, (i) => i);
    for (final i in rng) {
      final seed = i * 17.3;
      final startX = (seed * 31) % size.width;
      final startY = -20.0;
      final endY = size.height + 20;
      final y = startY + (endY - startY) * progress;
      final x = startX + (i % 2 == 0 ? 10 : -10) * progress;
      final color = _colors[i % _colors.length];
      final paint = Paint()..color = color.withValues(alpha: 0.8);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(progress * 6.28 + i);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: 6, height: 12),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Convenience helper that shows the celebration dialog and waits for
/// the user to dismiss it.
Future<void> showCelebrationDialog(
  BuildContext context, {
  required VoidCallback onContinue,
  String title = 'مبروك! تم تسجيل حسابك',
  String subtitle = 'في نظام ERP موريتانيا',
  String ctaLabel = 'متابعة إلى لوحة التحكم',
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => CelebrationDialog(
      title: title,
      subtitle: subtitle,
      ctaLabel: ctaLabel,
      onContinue: onContinue,
    ),
  );
}
