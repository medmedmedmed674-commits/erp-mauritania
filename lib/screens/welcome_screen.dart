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
/// Hover interaction: hovering one card smoothly elevates it while
/// lowering the other (desktop only — touch devices don't have hover).
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

class _BodyState extends State<_Body> {
  /// The role currently being hovered (null = no hover / both neutral).
  BusinessRole? _hovered;

  void _navigate(BusinessRole role) {
    // Slide-left transition into the auth screen. On RTL layouts
    // "forward" feels more natural as a left-to-right slide.
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 380),
        reverseTransitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (context, animation, secondaryAnimation) =>
            AuthScreen(role: role),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Slide from right (slide-left motion in RTL reading direction)
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
    return Container(
      padding: const EdgeInsets.all(24).copyWith(top: 32),
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1080),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionTitle(
              title: 'اختر نوع نشاطك التجاري',
              subtitle: 'سيتم توجيهك تلقائياً إلى لوحة التحكم المناسبة لنشاطك',
              icon: Icons.account_tree_outlined,
            ),
            const SizedBox(height: 24),
            Flexible(
              child: useRow
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _RoleCard(
                            role: BusinessRole.retail,
                            title: 'مجمع / متجر تجاري',
                            englishHint: 'Retail & Supermarket',
                            description:
                                'نقطة بيع سريعة، إدارة مخزون وزبناء ومشتريات،'
                                ' مناسب للمتاجر الصغيرة والمتوسطة والمجمعات التجارية.',
                            cta: 'ادخل كتاجر تجزئة',
                            tint: BusinessRole.retail.tint,
                            highlight: true,
                            isHovered: _hovered == BusinessRole.retail,
                            isOtherHovered:
                                _hovered != null &&
                                    _hovered != BusinessRole.retail,
                            onHover: (h) => setState(() => _hovered =
                                h ? BusinessRole.retail : null),
                            onTap: () => _navigate(BusinessRole.retail),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _RoleCard(
                            role: BusinessRole.wholesale,
                            title: 'تاجر جملة / مستودعات وتوزيع',
                            englishHint: 'Wholesale & Distribution',
                            description:
                                'بيع بالجملة، إدارة مخازن متعددة، استيراد وموردين،'
                                ' وتحليلات تنفيذية لمؤسسات التوزيع الكبرى.',
                            cta: 'ادخل كتاجر جملة',
                            tint: BusinessRole.wholesale.tint,
                            isHovered: _hovered == BusinessRole.wholesale,
                            isOtherHovered:
                                _hovered != null &&
                                    _hovered != BusinessRole.wholesale,
                            onHover: (h) => setState(() => _hovered =
                                h ? BusinessRole.wholesale : null),
                            onTap: () => _navigate(BusinessRole.wholesale),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        _RoleCard(
                          role: BusinessRole.retail,
                          title: 'مجمع / متجر تجاري',
                          englishHint: 'Retail & Supermarket',
                          description:
                              'نقطة بيع سريعة، إدارة مخزون وزبناء ومشتريات،'
                              ' مناسب للمتاجر الصغيرة والمتوسطة والمجمعات التجارية.',
                          cta: 'ادخل كتاجر تجزئة',
                          tint: BusinessRole.retail.tint,
                          highlight: true,
                          isHovered: false,
                          isOtherHovered: false,
                          onHover: (_) {},
                          onTap: () => _navigate(BusinessRole.retail),
                        ),
                        const SizedBox(height: 16),
                        _RoleCard(
                          role: BusinessRole.wholesale,
                          title: 'تاجر جملة / مستودعات وتوزيع',
                          englishHint: 'Wholesale & Distribution',
                          description:
                              'بيع بالجملة، إدارة مخازن متعددة، استيراد وموردين،'
                              ' وتحليلات تنفيذية لمؤسسات التوزيع الكبرى.',
                          cta: 'ادخل كتاجر جملة',
                          tint: BusinessRole.wholesale.tint,
                          isHovered: false,
                          isOtherHovered: false,
                          onHover: (_) {},
                          onTap: () => _navigate(BusinessRole.wholesale),
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

/// Animated role card. The card smoothly elevates when hovered and
/// shrinks slightly when the sibling card is hovered.
class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.title,
    required this.englishHint,
    required this.description,
    required this.cta,
    required this.tint,
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
  final bool highlight;
  final bool isHovered;
  final bool isOtherHovered;
  final VoidCallback onTap;
  final ValueChanged<bool> onHover;

  @override
  Widget build(BuildContext context) {
    // Animated elevation: 0 → 12 when hovered, 0 → -4 (lowered) when
    // the sibling card is hovered.
    final baseElevation = isOtherHovered ? -4.0 : 0.0;
    final hoverElevation = isHovered ? 12.0 : baseElevation;

    // Animated scale: 1.0 → 1.03 when hovered, 1.0 → 0.98 when sibling
    // is hovered.
    final scale = 1.0 +
        (isHovered ? 0.03 : 0.0) +
        (isOtherHovered ? -0.02 : 0.0);

    return MouseRegion(
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, -hoverElevation, 0)
          ..scale(scale),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 220),
          opacity: isOtherHovered ? 0.85 : 1.0,
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: highlight
                    ? tint
                    : (isHovered
                        ? tint.withValues(alpha: 0.6)
                        : AppTheme.divider),
                width: highlight || isHovered ? 1.5 : 1,
              ),
            ),
            elevation: isHovered ? 8 : 0,
            shadowColor: tint.withValues(alpha: 0.3),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: tint.withValues(
                                alpha: isHovered ? 0.20 : 0.12),
                            borderRadius: BorderRadius.circular(14),
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
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                  letterSpacing: 0.4,
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
