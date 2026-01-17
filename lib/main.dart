import 'package:flutter/material.dart';
// استيراد الشاشات
import 'screens/login_screen.dart';
import 'screens/transaction_screen.dart'; // سطر جديد مضاف
import 'screens/statistics_screen.dart';  // سطر جديد مضاف
// استيراد الألوان والوسائل المساعدة
import 'utils/app_colors.dart';

void main() {
  // التأكد من تهيئة الإضافات قبل تشغيل التطبيق (ضروري لقاعدة البيانات)
  WidgetsFlutterBinding.ensureInitialized();
  runApp(ExpenseTrackerApp());
}

class ExpenseTrackerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gilded Wallet',

      // إعداد الثيم العام للتطبيق
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,

        // تحسين مظهر النصوص
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white),
        ),

        // تنسيق عام للأزرار
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        // تنسيق الحقول النصية (TextFields)
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          hintStyle: const TextStyle(color: Colors.grey),
        ),
      ),

      // نقطة البداية
      home: LoginScreen(),



      // الجزء المسؤول عن حل مشكلة الشاشة السوداء (تعريف المسارات)
      routes: {
        '/transaction': (context) => TransactionScreen(),
        '/stats': (context) => StatisticsScreen(),
      },
    );
  }
}
