import 'package:flutter/material.dart';
import 'screens/login_page.dart';
import 'screens/dashboard_page.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final loggedIn = await AuthService.isLoggedIn();
  final userName = await AuthService.getCurrentName();
  runApp(IntelligentLandMeasurementApp(
    isLoggedIn: loggedIn,
    userName: userName,
  ));
}

class IntelligentLandMeasurementApp extends StatelessWidget {
  final bool isLoggedIn;
  final String userName;

  const IntelligentLandMeasurementApp({
    super.key,
    this.isLoggedIn = false,
    this.userName = 'User',
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Intelligent Land Measurement',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
        ),
        useMaterial3: true,
      ),
      home: isLoggedIn
          ? DashboardPage(userName: userName)
          : const LoginPage(),
    );
  }
}
