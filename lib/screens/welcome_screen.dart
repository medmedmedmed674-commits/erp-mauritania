import 'package:flutter/material.dart';

import '../models/user.dart';
import '../theme/app_theme.dart';
import '../widgets/responsive.dart';
import '../widgets/shared_widgets.dart';
import 'auth_screen.dart';

/// Module 1 — Welcome & Role Selection.
///
/// Adaptive layout:
/// - Mobile portrait: dark gradient header + stacked role cards.
/// - Tablet/Desktop: side-by-side role cards centered, larger header.
///
/// ## Hover interaction (desktop only)
/// Hovering one card smoothly elevates it (translation Y), applies a
/// subtle scale shift, and adds a coloured border glow; the sibling
/// card lowers and dims to draw attention to the hovered one.
///
/// ## Entrance animation
/// The body content uses [AnimatedSwitcher] + [TweenAnimationBuilder]
/// chains so the cards fade in and slide up from below the moment the
/// welcome screen mounts — giving the splash a fresh, alive feel.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const String route = '/welcome';

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: Responsive(
          builder: (context, device, _) {
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: BrandedHeader(
                    icon: Icons.storefront,
                    title: 'أهلاً وسهلاً بك',
                    subtitle: 'في نظام الإدارة المتكامل لمؤسستك',
                    height: device == DeviceType.desktop ? 260 : 220,
                  ),
                ),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _Body(device: device),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Body extends StatefulWidget {
  const _Body({required this.device});

  final DeviceType device;

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body>
    with SingleTickerProviderStateMixin {
  /// The role currently being hovered (null = no hover / both neutral).
  BusinessRole? _hovered;

  /// Entrance animation controller — runs once on mount.
  late final AnimationController _entrance = AnimationController(
    duration: const Duration(milliseconds: 900),
    vsync: this,
  );

  @override
  void initState() {
    super.initState();
    // Trigger the entrance animation on first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _entrance.forward();
    });
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  void _navigate(BusinessRole role) {
    // Slide-left transition into the auth screen.
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 380),
        reverseTransitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (context, animation, secondaryAnimation) =>
            AuthScreen(role: role),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final tween = Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeOutCubic));
          return SlideTransition(
            position: animation.drive(tween),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final useRow = widget.device == DeviceType.desktop ||
        (widget.device == DeviceType.tablet &&
            MediaQuery.sizeOf(context).width >= 720);

    // Two-stagger entrance: cards fade in + slide up.
    final fadeSlideRetail = _entrance.drive(
      Tween<double>(begin: 0.0, end: 1.0).chain(
        CurveTween(curve: const Interval(0.10, 0.70, curve: Curves.easeOut)),
      ),
    );
    final offsetRetail = _entrance.drive(
      Tween<Offset>(
        begin: const Offset(0, 0.18),
        end: Offset.zero,
      ).chain(
        CurveTween(curve: const Interval(0.10, 0.70, curve: Curves.easeOut)),
      ),
    );
    final fadeSlideWholesale = _entrance.drive(
      Tween<double>(begin: 0.0, end: 1.0).chain(
        CurveTween(curve: const Interval(0.25, 0.85, curve: Curves.easeOut)),
      ),
    );
    final offsetWholesale = _entrance.drive(
      Tween<Offset>(
        begin: const Offset(0, 0.18),
        end: Offset.zero,
      ).chain(
        CurveTween(curve: const Interval(0.25, 0.85, curve: Curves.easeOut)),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(24).copyWith(top: 32),
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1080),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Section title also fades in.
            FadeTransition(
              opacity: _entrance.drive(
                Tween<double>(begin: 0.0, end: 1.0).chain(
                  CurveTween(
                      curve: const Interval(0.0, 0.5, curve: Curves.easeOut)),
                ),
              ),
              child: const SlideTransition(
                position: AlwaysStoppedAnimation(Offset.zero),
                child: SectionTitle(
                  title: 'اختر نوع نشاطك التجاري',
                  subtitle: 'سيتم توجيهك تلقائياً إلى لوحة التحكم المناسبة لنشاطك',
                  icon: Icons.account_tree_outlined,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Flexible(
              child: useRow
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: FadeTransition(
                            opacity: fadeSlideRetail,
                            child: SlideTransition(
                              position: offsetRetail,
                              child: _RoleCard(
                                role: BusinessRole.retail,
                                title: 'مجمع / متجر تجاري',
                                englishHint: 'Retail & Supermarket',
                                description: 'نقطة بيع سريعة، إدارة مخزون وزبناء ومشتريات،'
                                    ' مناسب للمتاجر الصغيرة والمتوسطة والمجمعات التجارية.',
                                cta: 'ادخل كتاجر تجزئة',
                                tint: BusinessRole.retail.tint,
                                accentGradient: const [
                                  Color(0xFF1E6FBA),
                                  Color(0xFF4FB3D9),
                                ],
                                highlight: true,
                                isHovered: _hovered == BusinessRole.retail,
                                isOtherHovered: _hovered != null &&
                                    _hovered != BusinessRole.retail,
                                onHover: (h) => setState(() =>
                                    _hovered = h ? BusinessRole.retail : null),
                                onTap: () => _navigate(BusinessRole.retail),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: FadeTransition(
                            opacity: fadeSlideWholesale,
                            child: SlideTransition(
                              position: offsetWholesale,
                              child: _RoleCard(
                                role: BusinessRole.wholesale,
                                title: 'تاجر جملة / مستودعات وتوزيع',
                                englishHint: 'Wholesale & Distribution',
                                description: 'بيع بالجملة، إدارة مخازن متعددة، استيراد وموردين،'
                                    ' وتحليلات تنفيذية لمؤسسات التوزيع الكبرى.',
                                cta: 'ادخل كتاجر جملة',
                                tint: BusinessRole.wholesale.tint,
                                accentGradient: const [
                                  Color(0xFF6B4FBB),
                                  Color(0xFF9B7FE0),
                                ],
                                isHovered: _hovered == BusinessRole.wholesale,
                                isOtherHovered: _hovered != null &&
                                    _hovered != BusinessRole.wholesale,
                                onHover: (h) => setState(() =>
                                    _hovered = h ? BusinessRole.wholesale : null),
                                onTap: () => _navigate(BusinessRole.wholesale),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        FadeTransition(
                          opacity: fadeSlideRetail,
                          child: SlideTransition(
                            position: offsetRetail,
                            child: _RoleCard(
                              role: BusinessRole.retail,
                              title: 'مجمع / متجر تجاري',
                              englishHint: 'Retail & Supermarket',
                              description: 'نقطة بيع سريعة، إدارة مخزون وزبناء ومشتريات،'
                                  ' مناسب للمتاجر الصغيرة والمتوسطة والمجمعات التجارية.',
                              cta: 'ادخل كتاجر تجزئة',
                              tint: BusinessRole.retail.tint,
                              accentGradient: const [
                                Color(0xFF1E6FBA),
                                Color(0xFF4FB3D9),
                              ],
                              highlight: true,
                              isHovered: false,
                              isOtherHovered: false,
                              onHover: (_) {},
                              onTap: () => _navigate(BusinessRole.retail),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        FadeTransition(
                          opacity: fadeSlideWholesale,
                          child: SlideTransition(
                            position: offsetWholesale,
                            child: _RoleCard(
                              role: BusinessRole.wholesale,
                              title: 'تاجر جملة / مستودعات وتوزيع',
                              englishHint: 'Wholesale & Distribution',
                              description: 'بيع بالجملة، إدارة مخازن متعددة، استيراد وموردين،'
                                  ' وتحليلات تنفيذية لمؤسسات التوزيع الكبرى.',
                              cta: 'ادخل كتاجر جملة',
                              tint: BusinessRole.wholesale.tint,
                              accentGradient: const [
                                Color(0xFF6B4FBB),
                                Color(0xFF9B7FE0),
                              ],
                              isHovered: false,
                              isOtherHovered: false,
                              onHover: (_) {},
                              onTap: () => _navigate(BusinessRole.wholesale),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 32),
            const _SecurityFooter(),
          ],
        ),
      ),
    );
  }
}

/// Animated role card with hover elevation + scale + border glow.
class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.title,
    required this.englishHint,
    required this.description,
    required this.cta,
    required this.tint,
    required this.accentGradient,
    required this.onTap,
    required this.onHover,
    required this.isHovered,
    required this.isOtherHovered,
    this.highlight = false,
  });

  final BusinessRole role;
  final String title;
  final String englishHint;
  final String description;
  final String cta;
  final Color tint;
  final List<Color> accentGradient;
  final bool highlight;
  final bool isHovered;
  final bool isOtherHovered;
  final VoidCallback onTap;
  final ValueChanged<bool> onHover;

  @override
  Widget build(BuildContext context) {
    // Animated elevation: 0 → 12 when hovered, 0 → -4 (lowered) when sibling is hovered.
    final baseElevation = isOtherHovered ? -4.0 : 0.0;
    final hoverElevation = isHovered ? 12.0 : baseElevation;

    // Animated scale: 1.0 → 1.03 when hovered, 1.0 → 0.98 when sibling is hovered.
    final scale = 1.0 +
        (isHovered ? 0.03 : 0.0) +
        (isOtherHovered ? -0.02 : 0.0);

    return MouseRegion(
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, -hoverElevation, 0)..scale(scale),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 220),
          opacity: isOtherHovered ? 0.85 : 1.0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                // Subtle drop shadow that intensifies on hover.
                BoxShadow(
                  color: isHovered
                      ? tint.withValues(alpha: 0.30)
                      : Colors.black.withValues(alpha: 0.04),
                  blurRadius: isHovered ? 24 : 6,
                  spreadRadius: isHovered ? 2 : 0,
                  offset: const Offset(0, 8),
                ),
                // Border glow ring on hover.
                if (isHovered)
                  BoxShadow(
                    color: tint.withValues(alpha: 0.20),
                    blurRadius: 36,
                    spreadRadius: 4,
                  ),
              ],
            ),
            child: Card(
              color: Colors.transparent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(
                  color: isHovered
                      ? tint.withValues(alpha: 0.8)
                      : (highlight ? tint.withValues(alpha: 0.6) : AppTheme.divider),
                  width: (highlight || isHovered) ? 1.8 : 1,
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: onTap,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      // Vibrant gradient background that fades in on hover.
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutCubic,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isHovered
                                ? [
                                    accentGradient.first.withValues(alpha: 0.06),
                                    accentGradient.last.withValues(alpha: 0.12),
                                  ]
                                : [Colors.white, Colors.white],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 280),
                                  curve: Curves.easeOutCubic,
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        tint.withValues(
                                            alpha: isHovered ? 0.30 : 0.18),
                                        tint.withValues(
                                            alpha: isHovered ? 0.18 : 0.10),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: tint.withValues(
                                          alpha: isHovered ? 0.5 : 0.25),
                                      width: 1,
                                    ),
                                  ),
                                  child: Icon(role.icon,
                                      color: tint, size: 28),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        englishHint,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color:
                                              tint.withValues(alpha: 0.85),
                                          letterSpacing: 0.4,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              description,
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.6,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const Spacer(),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: tint,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size.fromHeight(48),
                                  elevation: isHovered ? 8 : 0,
                                  shadowColor: tint.withValues(alpha: 0.4),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: onTap,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(cta),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.arrow_back, size: 18),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SecurityFooter extends StatelessWidget {
  const _SecurityFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.success.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.verified_user_outlined,
              size: 18, color: AppTheme.success),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'نظام آمن ومشفّر بالكامل لحماية بياناتك المالية',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.success.withValues(alpha: 0.9),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
