import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_colors.dart';
import 'account_settings_screen.dart';

class SettingScreen extends StatefulWidget {
  @override
  _SettingScreenState createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationsState();
  }

  Future<void> _loadNotificationsState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    setState(() {
      _notificationsEnabled = value;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(value ? "Notifications Enabled" : "Notifications Disabled")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings", style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // قسم الحساب - Account
          _buildSectionHeader("Account"),
          _buildSettingItem(
            icon: Icons.person_outline,
            title: "Account Settings",
            subtitle: "Change name, email, password...",
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AccountSettingsScreen()),
              );
              // Refresh screen if user data was updated
              if (result == true) {
                // Optionally refresh settings screen
              }
            },
          ),

          const SizedBox(height: 20),

          // قسم الإشعارات - Notifications
          _buildSectionHeader("Notifications"),
          _buildSettingItem(
            icon: Icons.notifications_none,
            title: "Notifications",
            subtitle: "Turn alerts on or off",
            trailing: Switch(
              value: _notificationsEnabled,
              onChanged: _toggleNotifications,
              activeColor: AppColors.primary,
            ),
          ),

          const SizedBox(height: 20),

          // قسم الخصوصية - Privacy
          _buildSectionHeader("Privacy"),
          _buildSettingItem(
            icon: Icons.lock_outline,
            title: "Privacy & Security",
            subtitle: "Data protection, App lock, etc.",
            onTap: () => _showInfoDialog(
                context,
                "Privacy & Security",
                "• App Lock: Enabled (Fingerprint)\n• Data Encryption: AES-256\n• Last Security Check: Today 10:00 AM"
            ),
          ),

          const SizedBox(height: 20),

          // قسم المساعدة - Help
          _buildSectionHeader("Help"),
          _buildSettingItem(
            icon: Icons.help_outline,
            title: "Help & Support",
            subtitle: "FAQ, contact support",
            onTap: () => _showInfoDialog(
                context,
                "Help & Support",
                "• FAQ: How to add transaction?\n• Contact: support@walletapp.com\n• Version: 1.0.2"
            ),
          ),

          const SizedBox(height: 40),

          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).pushReplacementNamed('/'),
              child: const Text("Log Out", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  // دالة لإظهار الـ Dialog بالمعلومات
  void _showInfoDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: TextStyle(color: AppColors.primary)),
        content: Text(content, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close", style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        title,
        style: TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Card(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: Colors.white70),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        trailing: trailing ?? const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
      ),
    );
  }
}
