import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'screens/home_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/docs_screen.dart';
import 'screens/faq_screen.dart';
import 'utils/theme.dart';
import 'widgets/custom_nav_bar.dart';

class AquaWatchApp extends StatelessWidget {
  const AquaWatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: Consumer<AppProvider>(
        builder: (context, provider, _) {
          return MaterialApp(
            title: 'AquaWatch - Irrigation Water Requirements',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: provider.isDark ? ThemeMode.dark : ThemeMode.light,
            home: const MainScreen(),
          );
        },
      ),
    );
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    final screens = [
      const HomeScreen(),
      const DashboardScreen(),
      const ChatScreen(),
      const DocsScreen(),
      const FAQScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: provider.currentIndex,
        children: screens,
      ),
      bottomNavigationBar: const CustomNavBar(),
    );
  }
}
