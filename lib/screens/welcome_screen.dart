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

class _Body extends StatelessWidget {
  const _Body({required this.device});

  final DeviceType device;

  @override
  Widget build(BuildContext context) {
    final useRow = device == DeviceType.desktop ||
        (device == DeviceType.tablet &&
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

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.title,
    required this.englishHint,
    required this.description,
    required this.cta,
    required this.tint,
    this.highlight = false,
  });

  final BusinessRole role;
  final String title;
  final String englishHint;
  final String description;
  final String cta;
  final Color tint;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: highlight ? tint : AppTheme.divider,
          width: highlight ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: tint.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(role.icon, color: tint, size: 28),
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
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AuthScreen(role: role),
                  ),
                ),
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
