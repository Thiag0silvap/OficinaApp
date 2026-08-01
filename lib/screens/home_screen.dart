import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/components/responsive_components.dart';
import '../core/utils/app_feedback.dart';
import '../providers/app_provider.dart';
import 'dashboard_screen.dart';
import 'clientes_screen.dart';
import 'orcamentos_screen.dart';
import 'financeiro_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    ClientesScreen(),
    OrcamentosScreen(),
    FinanceiroScreen(),
  ];

  final List<String> _titles = [
    'Dashboard',
    'Clientes',
    'Orçamentos',
    'Financeiro',
  ];

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final error = app.lastErrorMessage;
    if (error != null && error.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        AppFeedback.showError(context, error);
        context.read<AppProvider>().clearLastError();
      });
    }

    return ResponsiveLayout(
      currentIndex: _currentIndex,
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      title: _titles[_currentIndex],
      body: _screens[_currentIndex],
    );
  }
}
