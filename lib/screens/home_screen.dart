import 'package:flutter/material.dart';
import '../core/components/responsive_components.dart';
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