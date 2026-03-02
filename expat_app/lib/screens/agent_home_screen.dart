import 'package:flutter/material.dart';

import 'agent_assigned_listings_screen.dart';
import 'agent_payments_screen.dart';
import 'agent_profile_screen.dart';
import 'messages_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _selectedBottomIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(textTheme),
          Expanded(
            child: _buildBody(textTheme),
          ),
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'expat',
              style: textTheme.titleLarge?.copyWith(
                color: _accentGreen,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_none, color: Colors.white),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.person_outline, color: Colors.white),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const AgentProfileScreen(
                          showAssignProperty: false,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(TextTheme textTheme) {
    if (_selectedBottomIndex == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Bio-View: Your profile and documents (placeholder).',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(color: const Color(0xFF1A2E35)),
          ),
        ),
      );
    }
    if (_selectedBottomIndex == 1) {
      return const AgentAssignedListingsScreen();
    }
    if (_selectedBottomIndex == 2) {
      return const MessagesScreen();
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
            color: Colors.black.withOpacity(0.12),
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
                _buildNavItem(textTheme, 0, 'assets/images/Bio-View Icon.png', 'Bio-View'),
                _buildNavItem(textTheme, 1, 'assets/images/Estates Icon.png', 'Estates'),
                _buildNavItem(textTheme, 2, 'assets/images/Messages icon.png', 'Messages'),
                _buildNavItem(textTheme, 3, 'assets/images/Payment Icon.png', 'Payments'),
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
            errorBuilder: (_, __, ___) => Icon(Icons.circle, size: 22, color: color),
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
