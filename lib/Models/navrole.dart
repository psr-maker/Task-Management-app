import 'package:flutter/material.dart';
import 'package:staff_work_track/utils/enum.dart';

class NavItem {
  final IconData icon;
  final String label;

  NavItem(this.icon, this.label);
}

final Map<UserRole, List<NavItem>> roleNavItems = {
  UserRole.superAdmin: [
    NavItem(Icons.dashboard, "Dashboard"),
    NavItem(Icons.group, "Users"),
    NavItem(Icons.checklist, "Tasks"),
    NavItem(Icons.assignment, "Reports"),
  ],

  UserRole.admin: [
    NavItem(Icons.dashboard, "Dashboard"),
    NavItem(Icons.people, "Employees"),
    NavItem(Icons.work, " my Work"),
    NavItem(Icons.fact_check, "Work Log"),
  ],

  UserRole.staff: [
    NavItem(Icons.home, "Home"),
    NavItem(Icons.assignment, "My Work"),
    NavItem(Icons.edit_note, "Work Log"),
    NavItem(Icons.person, "Profile"),
  ],
};
