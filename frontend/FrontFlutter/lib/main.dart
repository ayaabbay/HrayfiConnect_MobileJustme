import 'package:flutter/material.dart';
import 'pages/role_selector_page.dart';
import 'pages/auth/login_page.dart';
import 'pages/auth/register_page.dart';
import 'pages/client/client_shell.dart';
import 'pages/artisan/artisan_shell.dart';
import 'pages/admin/admin_shell.dart';

void main() {
  runApp(const FrontFlutterApp());
}

class FrontFlutterApp extends StatelessWidget {
  const FrontFlutterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Front Flutter',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        ClientShell.routeName: (context) => const ClientShell(),
        ArtisanShell.routeName: (context) => const ArtisanShell(),
        AdminShell.routeName: (context) => const AdminShell(),
      },
    );
  }
}


