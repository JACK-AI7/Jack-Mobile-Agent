import 'package:flutter/material.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'More',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'All settings and configuration.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF151515),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                child: Column(
                  children: [
                    _buildListItem(
                      icon: Icons.person_outline,
                      title: 'Account',
                      subtitle: 'Manage your account',
                      onTap: () {},
                      iconColor: const Color(0xFF2B6BFF),
                    ),
                    _buildDivider(),
                    _buildListItem(
                      icon: Icons.settings_outlined,
                      title: 'General',
                      onTap: () {},
                      iconColor: const Color(0xFF2B6BFF),
                    ),
                    _buildDivider(),
                    _buildListItem(
                      icon: Icons.palette_outlined,
                      title: 'Appearance',
                      onTap: () {},
                      iconColor: const Color(0xFF2B6BFF),
                    ),
                    _buildDivider(),
                    _buildListItem(
                      icon: Icons.shield_outlined,
                      title: 'Data & Privacy',
                      onTap: () {},
                      iconColor: const Color(0xFF2B6BFF),
                    ),
                    _buildDivider(),
                    _buildListItem(
                      icon: Icons.help_outline,
                      title: 'Help & Support',
                      onTap: () {},
                      iconColor: const Color(0xFF2B6BFF),
                    ),
                    _buildDivider(),
                    _buildListItem(
                      icon: Icons.info_outline,
                      title: 'About',
                      onTap: () {},
                      iconColor: const Color(0xFF2B6BFF),
                    ),
                    _buildDivider(),
                    _buildListItem(
                      icon: Icons.logout,
                      title: 'Log Out',
                      onTap: () {},
                      iconColor: Colors.redAccent,
                      textColor: Colors.redAccent,
                      showChevron: false,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: Colors.white.withValues(alpha: 0.05),
      height: 1,
      indent: 56,
    );
  }

  Widget _buildListItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    required Color iconColor,
    Color textColor = Colors.white,
    bool showChevron = true,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 14,
              ),
            )
          : null,
      trailing: showChevron
          ? const Icon(
              Icons.chevron_right,
              color: Colors.white38,
            )
          : null,
    );
  }
}
