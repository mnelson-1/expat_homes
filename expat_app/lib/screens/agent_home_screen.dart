import 'package:flutter/material.dart';

import 'package:expat_app/models/user_profile.dart';
import 'package:expat_app/services/auth_service.dart';
import 'agent_assigned_listings_screen.dart';
import 'agent_bio_view_screen.dart';
import 'agent_payments_screen.dart';
import 'account_profile_screen.dart';
import 'messages_screen.dart' show MessagesScreen, kRoleAgent;

/// Agent home – landing after sign up. Tabs: Bio-View, Estates (Assigned Listings), Messages, Payments.
class AgentHomeScreen extends StatefulWidget {
  const AgentHomeScreen({super.key, this.initialIndex = 1});

  /// Default 1 = Estates (Assigned Listings) so agents land on assignments.
  final int initialIndex;

  @override
  State<AgentHomeScreen> createState() => _AgentHomeScreenState();
}

class _AgentHomeScreenState extends State<AgentHomeScreen> {
  static const Color _primaryDark = Color(0xFF1A2E35);
  static const Color _accentGreen = Color(0xFF8ED966);

  late int _selectedBottomIndex;
  String _userName = '';
  String? _userProfileImageUrl;

  @override
  void initState() {
    super.initState();
    _selectedBottomIndex = widget.initialIndex;
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final profile = await AuthService().getCurrentUserProfile();
    if (profile != null && mounted) {
      setState(() {
        _userName = profile.legalName;
        _userProfileImageUrl = profile.profileImageUrl;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(textTheme),
          Expanded(child: _buildBody(textTheme)),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(textTheme),
    );
  }

  Widget _buildHeader(TextTheme textTheme) {
    return Container(
      color: _primaryDark,
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Text(
              'expat',
              style: textTheme.titleLarge?.copyWith(
                color: _accentGreen,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: SizedBox.shrink()),
            const Icon(Icons.notifications_none, color: Colors.white),
            const SizedBox(width: 4),
            _buildProfileMenu(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAvatar({double radius = 16}) {
    if (_userProfileImageUrl != null && _userProfileImageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(_userProfileImageUrl!),
        backgroundColor: Colors.grey.shade200,
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: _accentGreen,
      child: Text(
        _userName.isNotEmpty ? _userName[0].toUpperCase() : '?',
        style: TextStyle(
          color: _primaryDark,
          fontWeight: FontWeight.w600,
          fontSize: radius * 0.9,
        ),
      ),
    );
  }

  Widget _buildProfileMenu() {
    return GestureDetector(
      onTap: () => _openAccountProfile(),
      child: _buildProfileAvatar(),
    );
  }

  void _openAccountProfile() {
    Navigator.of(context)
        .push<void>(
          MaterialPageRoute<void>(
            builder: (_) => const AccountProfileScreen(role: UserRole.agent),
          ),
        )
        .then((_) {
          if (mounted) _loadUserProfile();
        });
  }

  Widget _buildBody(TextTheme textTheme) {
    if (_selectedBottomIndex == 0) {
      return const AgentBioViewScreen();
    }
    if (_selectedBottomIndex == 1) {
      return const AgentAssignedListingsScreen();
    }
    if (_selectedBottomIndex == 2) {
      return MessagesScreen(
        currentUserRole: kRoleAgent,
        emptyStateMessage:
            'You have no messages yet. Either no Landlord has assigned you a Listing, or no Expat has made inquiries.',
      );
    }
    // Payments tab
    return const AgentPaymentsScreen();
  }

  Widget _buildBottomNav(TextTheme textTheme) {
    return Container(
      decoration: BoxDecoration(
        color: _primaryDark,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  textTheme,
                  0,
                  'assets/images/Bio-View Icon.png',
                  'Bio-View',
                ),
                _buildNavItem(
                  textTheme,
                  1,
                  'assets/images/Estates Icon.png',
                  'Estates',
                ),
                _buildNavItem(
                  textTheme,
                  2,
                  'assets/images/Messages icon.png',
                  'Messages',
                ),
                _buildNavItem(
                  textTheme,
                  3,
                  'assets/images/Payment Icon.png',
                  'Payments',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    TextTheme textTheme,
    int index,
    String imagePath,
    String label,
  ) {
    final selected = _selectedBottomIndex == index;
    final color = selected ? _accentGreen : Colors.white;

    return InkWell(
      onTap: () => setState(() => _selectedBottomIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            imagePath,
            width: 22,
            height: 22,
            color: color,
            colorBlendMode: BlendMode.srcIn,
            errorBuilder:
                (_, __, ___) => Icon(Icons.circle, size: 22, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

