import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'language_switcher.dart';
import 'responsive.dart';

/// Adaptive scaffold that switches between a [BottomNavigationBar]
/// on mobile and a [NavigationRail] / sidebar on tablet + desktop.
///
/// Both dashboards (retail + wholesale) reuse this shell so the
/// adaptive navigation behaviour is consistent.
class AdaptiveDashboardScaffold extends StatelessWidget {
  const AdaptiveDashboardScaffold({
    super.key,
    required this.title,
    required this.businessName,
    required this.tabs,
    required this.currentIndex,
    required this.onIndexChanged,
    required this.child,
  });

  final String title;
  final String businessName;
  final List<DashboardTab> tabs;
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Responsive(
        builder: (context, device, _) {
          if (device == DeviceType.mobile) {
            return Scaffold(
              backgroundColor: AppTheme.background,
              appBar: _buildAppBar(context, compact: true),
              body: SafeArea(child: child),
              bottomNavigationBar: _BottomNav(
                tabs: tabs,
                current: currentIndex,
                onChanged: onIndexChanged,
              ),
            );
          }

          // Tablet / Desktop — sidebar
          return Scaffold(
            backgroundColor: AppTheme.background,
            appBar: _buildAppBar(context, compact: false),
            body: Row(
              children: [
                _SideRail(
                  tabs: tabs,
                  current: currentIndex,
                  onChanged: onIndexChanged,
                  expanded: device == DeviceType.desktop,
                  businessName: businessName,
                ),
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppTheme.background,
                      border: Border(
                        right: BorderSide(
                            color: AppTheme.divider, width: 1),
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: child,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context,
      {required bool compact}) {
    final activeTab = tabs[currentIndex];
    return AppBar(
      backgroundColor: AppTheme.primary,
      elevation: 0,
      titleSpacing: 16,
      title: Row(
        children: [
          Icon(activeTab.icon, color: AppTheme.accent, size: 22),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                activeTab.label,
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        // Language switcher — compact pill (Arabic ⇄ French)
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: LanguageSwitcher(compact: true),
        ),
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {},
        ),
        const SizedBox(width: 8),
        CircleAvatar(
          radius: 16,
          backgroundColor: AppTheme.accent.withValues(alpha: 0.3),
          child: const Icon(Icons.person, size: 18, color: Colors.white),
        ),
        const SizedBox(width: 16),
      ],
    );
  }
}

class DashboardTab {
  const DashboardTab({
    required this.label,
    required this.icon,
    required this.subtitle,
  });
  final String label;
  final IconData icon;
  final String subtitle;
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.tabs,
    required this.current,
    required this.onChanged,
  });

  final List<DashboardTab> tabs;
  final int current;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.divider, width: 1)),
      ),
      child: BottomNavigationBar(
        currentIndex: current,
        onTap: onChanged,
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppTheme.surface,
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: AppTheme.textSecondary,
        selectedLabelStyle:
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        items: tabs
            .map(
              (t) => BottomNavigationBarItem(
                icon: Icon(t.icon, size: 22),
                label: t.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _SideRail extends StatelessWidget {
  const _SideRail({
    required this.tabs,
    required this.current,
    required this.onChanged,
    required this.expanded,
    required this.businessName,
  });

  final List<DashboardTab> tabs;
  final int current;
  final ValueChanged<int> onChanged;
  final bool expanded;
  final String businessName;

  @override
  Widget build(BuildContext context) {
    final width = expanded ? 260.0 : 80.0;
    return Container(
      width: width,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppTheme.primaryDark, AppTheme.primary],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            if (expanded) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppTheme.accent.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: const Icon(Icons.storefront,
                          color: AppTheme.accent, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ERP Mauritania',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            businessName,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Divider(color: Colors.white24),
              ),
            ] else ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    const Icon(Icons.storefront, color: AppTheme.accent, size: 20),
              ),
              const SizedBox(height: 20),
            ],
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 12),
                itemCount: tabs.length,
                itemBuilder: (context, i) {
                  final tab = tabs[i];
                  final selected = i == current;
                  if (!expanded) {
                    return Tooltip(
                      message: tab.label,
                      preferBelow: false,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: selected
                              ? AppTheme.accent.withValues(alpha: 0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => onChanged(i),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 12),
                              child: Column(
                                children: [
                                  Icon(tab.icon,
                                      color: selected
                                          ? AppTheme.accent
                                          : Colors.white.withValues(
                                              alpha: 0.7),
                                      size: 22),
                                  const SizedBox(height: 4),
                                  Text(
                                    tab.label,
                                    style: TextStyle(
                                      color: selected
                                          ? Colors.white
                                          : Colors.white.withValues(
                                              alpha: 0.7),
                                      fontSize: 10,
                                      fontWeight: selected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Material(
                      color: selected
                          ? Colors.white.withValues(alpha: 0.10)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => onChanged(i),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: selected
                                ? Border.all(
                                    color: AppTheme.accent
                                        .withValues(alpha: 0.5),
                                    width: 1,
                                  )
                                : null,
                          ),
                          child: Row(
                            children: [
                              Icon(tab.icon,
                                  color: selected
                                      ? AppTheme.accent
                                      : Colors.white.withValues(alpha: 0.85),
                                  size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tab.label,
                                      style: TextStyle(
                                        color: selected
                                            ? Colors.white
                                            : Colors.white.withValues(
                                                alpha: 0.85),
                                        fontSize: 14,
                                        fontWeight: selected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      tab.subtitle,
                                      style: TextStyle(
                                        color: Colors.white
                                            .withValues(alpha: 0.5),
                                        fontSize: 11,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (expanded)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppTheme.accent.withValues(alpha: 0.3),
                      child: const Icon(Icons.person,
                          size: 18, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'المستخدم',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'إصدار 1.0',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.logout,
                        color: Colors.white.withValues(alpha: 0.6), size: 18),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
