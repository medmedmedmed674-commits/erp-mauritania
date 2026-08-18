import 'package:flutter/material.dart';

/// Role selected on the welcome screen.
/// Drives routing to either the retail or wholesale dashboards.
enum BusinessRole { retail, wholesale }

extension BusinessRoleX on BusinessRole {
  String get arabicLabel => switch (this) {
        BusinessRole.retail => 'تجزئة',
        BusinessRole.wholesale => 'جملة',
      };

  IconData get icon => switch (this) {
        BusinessRole.retail => Icons.storefront_outlined,
        BusinessRole.wholesale => Icons.local_shipping_outlined,
      };

  Color get tint => switch (this) {
        BusinessRole.retail => const Color(0xFF1E6FBA),
        BusinessRole.wholesale => const Color(0xFF6B4FBB),
      };
}

/// Application-wide user representation for auth + dashboards.
@immutable
class AppUser {
  const AppUser({
    required this.businessName,
    required this.ownerName,
    required this.phone,
    required this.city,
    required this.role,
    this.email,
  });

  final String businessName;
  final String ownerName;
  final String phone;
  final String city;
  final BusinessRole role;
  final String? email;

  String get displayName => businessName.isEmpty ? ownerName : businessName;
}
