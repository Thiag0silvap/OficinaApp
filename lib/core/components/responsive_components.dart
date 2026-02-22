import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';
import '../constants/app_version.dart';
import '../../providers/auth_provider.dart';
import '../../services/db_service.dart';

// --- Responsive utilities (consolidated)
class ResponsiveBreakpoints {
  static const double mobile = 600;
  static const double tablet = 1024;
  static const double desktop = 1440;

  static const double maxContentWidth = 1200;
  static const double maxMobileContent = 400;
  static const double maxTabletContent = 800;
}

enum DeviceType { mobile, tablet, desktop }

class ResponsiveUtils {
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < ResponsiveBreakpoints.mobile) return DeviceType.mobile;
    if (width < ResponsiveBreakpoints.tablet) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  static bool isMobile(BuildContext context) => getDeviceType(context) == DeviceType.mobile;
  static bool isTablet(BuildContext context) => getDeviceType(context) == DeviceType.tablet;
  static bool isDesktop(BuildContext context) => getDeviceType(context) == DeviceType.desktop;
  static bool isMobileOrTablet(BuildContext context) => !isDesktop(context);

  static double getContentWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return screenWidth * 0.95;
      case DeviceType.tablet:
        return screenWidth * 0.85;
      case DeviceType.desktop:
        return screenWidth > ResponsiveBreakpoints.maxContentWidth
            ? ResponsiveBreakpoints.maxContentWidth
            : screenWidth * 0.8;
    }
  }

  static EdgeInsets getScreenPadding(BuildContext context) {
    switch (getDeviceType(context)) {
      case DeviceType.mobile:
        return const EdgeInsets.all(16);
      case DeviceType.tablet:
        return const EdgeInsets.all(24);
      case DeviceType.desktop:
        return const EdgeInsets.all(32);
    }
  }

  static EdgeInsets getCardPadding(BuildContext context) {
    switch (getDeviceType(context)) {
      case DeviceType.mobile:
        return const EdgeInsets.all(16);
      case DeviceType.tablet:
        return const EdgeInsets.all(20);
      case DeviceType.desktop:
        return const EdgeInsets.all(24);
    }
  }

  static double getCardSpacing(BuildContext context) {
    switch (getDeviceType(context)) {
      case DeviceType.mobile:
        return 16;
      case DeviceType.tablet:
        return 20;
      case DeviceType.desktop:
        return 24;
    }
  }

  static int getGridColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < ResponsiveBreakpoints.mobile) return 1;
    if (width < ResponsiveBreakpoints.tablet) return 2;
    if (width < ResponsiveBreakpoints.desktop) return 3;
    return 4;
  }

  static double getFontSizeMultiplier(BuildContext context) {
    switch (getDeviceType(context)) {
      case DeviceType.mobile:
        return 1.0;
      case DeviceType.tablet:
        return 1.1;
      case DeviceType.desktop:
        return 1.2;
    }
  }
}

class ResponsiveWidget extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveWidget({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    switch (ResponsiveUtils.getDeviceType(context)) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
    }
  }
}

class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final bool centerContent;
  final EdgeInsets? customPadding;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.centerContent = true,
    this.customPadding,
  });

  @override
  Widget build(BuildContext context) {
    final contentWidth = ResponsiveUtils.getContentWidth(context);
    final padding = customPadding ?? ResponsiveUtils.getScreenPadding(context);

    return Container(
      width: double.infinity,
      padding: padding,
      child: centerContent
          ? Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentWidth),
                child: child,
              ),
            )
          : child,
    );
  }
}

class ResponsiveGridView extends StatelessWidget {
  final List<Widget> children;
  final double? childAspectRatio;
  final EdgeInsets? padding;

  const ResponsiveGridView({
    super.key,
    required this.children,
    this.childAspectRatio,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final columns = ResponsiveUtils.getGridColumns(context);
    final spacing = ResponsiveUtils.getCardSpacing(context);
    final screenPadding = padding ?? ResponsiveUtils.getScreenPadding(context);

    return Padding(
      padding: screenPadding,
      child: GridView.count(
        crossAxisCount: columns,
        childAspectRatio: childAspectRatio ?? 1.0,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        children: children,
      ),
    );
  }
}

class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const ResponsiveText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    final multiplier = ResponsiveUtils.getFontSizeMultiplier(context);
    final base = style ?? const TextStyle(fontSize: 14);
    final adjusted = base.copyWith(fontSize: (base.fontSize ?? 14) * multiplier);

    return Text(
      text,
      style: adjusted,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

class ResponsiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final Color? color;
  final double? elevation;

  const ResponsiveCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    final cardPadding = padding ?? ResponsiveUtils.getCardPadding(context);

    return Card(
      color: color ?? AppColors.secondaryGray,
      elevation: elevation ?? 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: cardPadding,
            child: child,
          ),
        ),
      ),
    );
  }
}

class ResponsiveStatsGrid extends StatelessWidget {
  final List<Widget> children;
  final double? childAspectRatio;

  const ResponsiveStatsGrid({
    super.key,
    required this.children,
    this.childAspectRatio,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = ResponsiveUtils.getCardSpacing(context) * 0.5;
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final isTablet = ResponsiveUtils.isTablet(context);
    final crossAxisCount = isDesktop
        ? 4
        : isTablet
            ? 2
            : 1;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: children.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: childAspectRatio ?? (ResponsiveUtils.isMobile(context) ? 1.9 : 1.6),
      ),
      itemBuilder: (context, index) => children[index],
    );
  }
}

// --- App-level Responsive Layout
class ResponsiveLayout extends StatelessWidget {
  final Widget body;
  final int currentIndex;
  final Function(int) onTap;
  final String title;

  const ResponsiveLayout({
    super.key,
    required this.body,
    required this.currentIndex,
    required this.onTap,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveWidget(
      mobile: _buildMobileLayout(context),
      tablet: _buildTabletLayout(context),
      desktop: _buildDesktopLayout(context),
    );
  }

  Future<void> _confirmAndLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair da conta?'),
        content: const Text('Você precisará fazer login novamente para acessar o sistema.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!context.mounted) return;
    await context.read<AuthProvider>().logout();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const AppBarLogo(),
        backgroundColor: AppColors.secondaryGray,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () => _confirmAndLogout(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: body,
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _buildSideNavigationRail(context),
          Expanded(
            child: Scaffold(
              appBar: AppBar(
                title: Row(
                  children: [
                    const AppBarLogo(),
                    const SizedBox(width: 16),
                    Text(title),
                  ],
                ),
                backgroundColor: AppColors.secondaryGray,
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.cloud_upload),
                    tooltip: 'Backup manual',
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      messenger.showSnackBar(const SnackBar(content: Text('Iniciando backup...')));
                      try {
                        final res = await DBService.instance.exportBackupToUserDocuments();
                        messenger.showSnackBar(SnackBar(content: Text('Backup salvo em: ${res['db']}')));
                      } catch (e) {
                        messenger.showSnackBar(SnackBar(content: Text('Erro ao gerar backup: $e')));
                      }
                    },
                  ),
                  IconButton(icon: const Icon(Icons.refresh), onPressed: () {}),
                  IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
                  IconButton(
                    icon: const Icon(Icons.logout),
                    tooltip: 'Sair',
                    onPressed: () => _confirmAndLogout(context),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
              body: body,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _buildSideNavigationDrawer(context),
          Expanded(
            child: Scaffold(
              appBar: AppBar(
                title: Row(
                  children: [
                    const AppBarLogo(),
                    const SizedBox(width: 16),
                    Text(title),
                  ],
                ),
                backgroundColor: AppColors.secondaryGray,
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.cloud_upload),
                    tooltip: 'Backup manual',
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      messenger.showSnackBar(const SnackBar(content: Text('Iniciando backup...')));
                      try {
                        final res = await DBService.instance.exportBackupToUserDocuments();
                        messenger.showSnackBar(SnackBar(content: Text('Backup salvo em: ${res['db']}')));
                      } catch (e) {
                        messenger.showSnackBar(SnackBar(content: Text('Erro ao gerar backup: $e')));
                      }
                    },
                  ),
                  IconButton(icon: const Icon(Icons.refresh), onPressed: () {}),
                  IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
                  IconButton(
                    icon: const Icon(Icons.logout),
                    tooltip: 'Sair',
                    onPressed: () => _confirmAndLogout(context),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
              body: body,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppColors.secondaryGray,
      selectedItemColor: AppColors.primaryYellow,
      unselectedItemColor: AppColors.white.withValues(alpha: 0.6),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
        BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Clientes'),
        BottomNavigationBarItem(icon: Icon(Icons.description), label: 'Orçamentos'),
        BottomNavigationBarItem(icon: Icon(Icons.attach_money), label: 'Financeiro'),
      ],
    );
  }

  Widget _buildSideNavigationRail(BuildContext context) {
    return NavigationRail(
      backgroundColor: AppColors.secondaryGray,
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      labelType: NavigationRailLabelType.all,
      selectedIconTheme: const IconThemeData(color: AppColors.primaryYellow),
      selectedLabelTextStyle: const TextStyle(color: AppColors.primaryYellow),
      unselectedIconTheme: IconThemeData(color: AppColors.white.withValues(alpha: 0.6)),
      unselectedLabelTextStyle: TextStyle(color: AppColors.white.withValues(alpha: 0.6)),
      trailing: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: IconButton(
          icon: const Icon(Icons.logout, color: AppColors.white),
          tooltip: 'Sair',
          onPressed: () => _confirmAndLogout(context),
        ),
      ),
      destinations: const [
        NavigationRailDestination(icon: Icon(Icons.dashboard), label: Text('Dashboard')),
        NavigationRailDestination(icon: Icon(Icons.people), label: Text('Clientes')),
        NavigationRailDestination(icon: Icon(Icons.description), label: Text('Orçamentos')),
        NavigationRailDestination(icon: Icon(Icons.attach_money), label: Text('Financeiro')),
      ],
    );
  }

  Widget _buildSideNavigationDrawer(BuildContext context) {
    return Container(
      width: 280,
      color: AppColors.secondaryGray,
      child: Column(
        children: [
          Container(
            height: 120,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryYellow, Color(0xFFFFB000)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Center(child: DrawerLogo()),
          ),
          Expanded(
            child: ListView(
              children: [
                _buildDrawerItem(context, icon: Icons.dashboard, title: 'Dashboard', index: 0),
                _buildDrawerItem(context, icon: Icons.people, title: 'Clientes', index: 1),
                _buildDrawerItem(context, icon: Icons.description, title: 'Orçamentos', index: 2),
                _buildDrawerItem(context, icon: Icons.attach_money, title: 'Financeiro', index: 3),
                const Divider(color: AppColors.lightGray),
                ListTile(
                  leading: const Icon(Icons.settings, color: AppColors.white),
                  title: const Text('Configurações', style: TextStyle(color: AppColors.white)),
                  onTap: () {},
                ),
                ListTile(
                  leading: const Icon(Icons.cloud_upload, color: AppColors.white),
                  title: const Text('Backup (manual)', style: TextStyle(color: AppColors.white)),
                  onTap: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    messenger.showSnackBar(const SnackBar(content: Text('Iniciando backup...')));
                    try {
                      final res = await DBService.instance.exportBackupToUserDocuments();
                      messenger.showSnackBar(SnackBar(content: Text('Backup salvo em: ${res['db']}')));
                    } catch (e) {
                      messenger.showSnackBar(SnackBar(content: Text('Erro ao gerar backup: $e')));
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.help, color: AppColors.white),
                  title: const Text('Ajuda', style: TextStyle(color: AppColors.white)),
                  onTap: () {},
                ),
                const Divider(color: AppColors.lightGray),
                ListTile(
                  leading: const Icon(Icons.logout, color: AppColors.white),
                  title: const Text('Sair', style: TextStyle(color: AppColors.white)),
                  onTap: () => _confirmAndLogout(context),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Versão ${AppVersion.current}',
              style: const TextStyle(color: AppColors.lightGray, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required int index,
  }) {
    final isSelected = currentIndex == index;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryYellow.withValues(alpha: 0.1) : null,
        borderRadius: BorderRadius.circular(12),
        border: isSelected ? Border.all(color: AppColors.primaryYellow.withValues(alpha: 0.3)) : null,
      ),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? AppColors.primaryYellow : AppColors.white),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? AppColors.primaryYellow : AppColors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: () => onTap(index),
      ),
    );
  }
}

class ResponsiveListCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? leading;
  final VoidCallback? onTap;
  final List<Widget>? actions;

  const ResponsiveListCard({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.leading,
    this.onTap,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final fontMultiplier = ResponsiveUtils.getFontSizeMultiplier(context);

    return ResponsiveCard(
      onTap: onTap,
      child: Column(
        children: [
          Row(
            children: [
              if (leading != null) ...[
                leading!,
                SizedBox(width: isDesktop ? 16 : 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: (isDesktop ? 18 : 16) * fontMultiplier,
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: (isDesktop ? 14 : 12) * fontMultiplier,
                          color: AppColors.white.withValues(alpha: 0.7),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          if (actions != null && actions!.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(color: AppColors.lightGray),
            const SizedBox(height: 10),

            // ✅ Melhor: Wrap + largura mínima para botões não ficarem esmagados
            LayoutBuilder(
              builder: (ctx, c) {
                final isNarrow = c.maxWidth < 420;
                return Wrap(
                  alignment: WrapAlignment.center,
                  runAlignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 8,
                  children: actions!
                      .map((w) => ConstrainedBox(
                            constraints: BoxConstraints(minWidth: isNarrow ? 140 : 160),
                            child: w,
                          ))
                      .toList(),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class ResponsiveDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget>? actions;

  const ResponsiveDialog({
    super.key,
    required this.title,
    required this.content,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final fontMultiplier = ResponsiveUtils.getFontSizeMultiplier(context);

    return Dialog(
      backgroundColor: AppColors.secondaryGray,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: AnimatedPadding(
        padding: MediaQuery.of(context).viewInsets,
        duration: const Duration(milliseconds: 150),
        curve: Curves.decelerate,
        child: Container(
          width: isDesktop ? 520 : ResponsiveUtils.getContentWidth(context),
          padding: EdgeInsets.all(isDesktop ? 24 : 16),
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20 * fontMultiplier,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryYellow,
                  ),
                ),
                const SizedBox(height: 16),
                content,
                if (actions != null && actions!.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    alignment: WrapAlignment.end,
                    children: actions!
                        .map((a) => ConstrainedBox(
                              constraints: const BoxConstraints(minWidth: 140),
                              child: a,
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
