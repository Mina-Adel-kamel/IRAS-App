import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart'; // ده السطر اللي كان ناقص عشان يشوف الصفحة الجديدة

void main() {
  runApp(const IRASApp());
}

class IRASApp extends StatelessWidget {
  const IRASApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'IRAS',
      theme: ThemeData(
        brightness: Brightness.dark, // عشان يظبط الألوان الغامقة تلقائي
        primaryColor: const Color(0xFFC5FF29),
      ),
      // لو عايز تفتح الداشبورد علطول جرب تغير LoginScreen لـ DashboardScreen
      home: const LoginScreen(), 
    );
  }
}