import 'package:flutter/material.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tools', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            Text('Connect and use powerful tools.', style: TextStyle(color: Colors.white70, fontSize: 14)),
          ],
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          _buildFilterRow(),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildToolCard('Google', Icons.g_mobiledata, const Color(0xFF4285F4), true),
                _buildToolCard('GitHub', Icons.code, const Color(0xFF333333), true),
                _buildToolCard('Notion', Icons.description, const Color(0xFFEBEBEB), false, iconDark: true),
                _buildToolCard('Slack', Icons.hub, const Color(0xFF4A154B), true),
                _buildToolCard('Gmail', Icons.mail, const Color(0xFFEA4335), false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    final filters = ['All', 'Connected', 'Available'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: filters.map((filter) {
          final isSelected = filter == 'All';
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Chip(
              label: Text(filter),
              labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.white70),
              backgroundColor: isSelected ? const Color(0xFF2B6BFF) : const Color(0xFF151515),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide.none,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildToolCard(String name, IconData icon, Color color, bool isConnected, {bool iconDark = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconDark ? Colors.black : Colors.white, size: 28),
        ),
        title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isConnected ? Colors.transparent : const Color(0xFF2B6BFF),
            borderRadius: BorderRadius.circular(20),
            border: isConnected ? Border.all(color: Colors.white24) : null,
          ),
          child: Text(
            isConnected ? 'Connected' : 'Connect',
            style: TextStyle(
              color: isConnected ? Colors.white70 : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
