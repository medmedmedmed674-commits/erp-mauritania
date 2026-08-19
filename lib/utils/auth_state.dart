import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';

/// Lightweight in-memory auth state. Replace with a real backend
/// integration when shipping; the surface stays the same so the UI
/// code does not need to change.
class AuthState extends ChangeNotifier {
  AppUser? _user;
  bool _rememberMe = true;

  AppUser? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get rememberMe => _rememberMe;

  void setRememberMe(bool value) {
    _rememberMe = value;
    notifyListeners();
  }

  /// Login flow used by the auth screen.
  ///
  /// In a production deployment this would authenticate against the
  /// backend and load the real user profile from the `users` table.
  /// For now, we use the phone number as the identifier and set a
  /// sensible default business name derived from the phone — the user
  /// can always edit it later from the profile screen.
  ///
  /// IMPORTANT: we do NOT hardcode "مؤسسة النور التجارية" — that was
  /// the old mock behavior. The business name now comes from the
  /// registration flow (or is left blank so the dashboard shows a
  /// placeholder until the user sets it).
  void login({
    required String identifier,
    required String password,
    required BusinessRole role,
  }) {
    _user = AppUser(
      businessName: '', // Will be populated from DB / profile edit
      ownerName: '', // Will be populated from DB / profile edit
      phone: identifier,
      city: '', // Will be populated from DB / profile edit
      role: role,
    );
    notifyListeners();
  }

  /// Registration flow used by the auth screen.
  void register({
    required String businessName,
    required String ownerName,
    required String phone,
    required String city,
    required BusinessRole role,
    String? email,
  }) {
    _user = AppUser(
      businessName: businessName,
      ownerName: ownerName,
      phone: phone,
      city: city,
      role: role,
      email: email,
    );
    notifyListeners();
  }

  void logout() {
    _user = null;
    notifyListeners();
  }
}

/// Convenience accessor for the [AuthState] provided higher in the tree.
AuthState authOf(BuildContext context) => context.read<AuthState>();
