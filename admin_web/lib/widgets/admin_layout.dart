import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'admin_sidebar.dart';
import 'admin_header.dart';

/// Layout chung cho tất cả admin screens
/// Bao gồm Sidebar và Header
/// Sidebar không bị reload khi chuyển route
class AdminLayout extends StatefulWidget {
  final Widget child;

  const AdminLayout({
    super.key,
    required this.child,
  });

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  bool _sidebarExpanded = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar - chỉ có 1 instance, không bị reload
          AdminSidebar(
            expanded: _sidebarExpanded,
            onToggle: () {
              setState(() {
                _sidebarExpanded = !_sidebarExpanded;
              });
            },
          ),
          // Main content
          Expanded(
            child: Column(
              children: [
                // Header
                AdminHeader(
                  onLogout: () async {
                    await FirebaseAuth.instance.signOut();
                    // Navigation sẽ được handle bởi AuthWrapper
                  },
                ),
                // Content
                Expanded(
                  child: widget.child,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

