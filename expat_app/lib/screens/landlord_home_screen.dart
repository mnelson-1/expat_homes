import 'package:flutter/material.dart';

import 'agent_profile_screen.dart';
import 'messages_screen.dart';

/// Landlord home screen – landing view after signup/login.
///
/// First tab is "Find Agent" with a region search field and intro text.
/// Bottom navigation mirrors the Expat view but with a Payments tab.
class LandlordHomeScreen extends StatefulWidget {
  const LandlordHomeScreen({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<LandlordHomeScreen> createState() => _LandlordHomeScreenState();
}

class _LandlordHomeColors {
  static const Color primaryDark = Color(0xFF1A2E35);
  static const Color accentGreen = Color(0xFF8ED966);
  static const Color bodyText = Color(0xFF1A2E35);
  static const Color helper = Color(0xFF9CA5A8);
  static const Color hint = Color(0xFF9CA5A8);
}

class _LandlordHomeScreenState extends State<LandlordHomeScreen> {
  int _selectedBottomIndex = 0; // 0 = Find Agent, 1 = Estates, 2 = Messages, 3 = Payments
  final TextEditingController _regionController = TextEditingController();
  String _activeRegion = '';

  final List<_AgentSummary> _agents = const [
    _AgentSummary(
      name: 'Jean Claude',
      agentId: 'KM-201903',
      region: 'Kimironko',
      rating: 4.5,
      ratingCount: 18,
    ),
    _AgentSummary(
      name: 'Aline Uwase',
      agentId: 'RM-204112',
      region: 'Remera',
      rating: 4.7,
      ratingCount: 24,
    ),
    _AgentSummary(
      name: 'Eric Niyonzima',
      agentId: 'KG-198745',
      region: 'Kacyiru',
      rating: 4.3,
      ratingCount: 9,
    ),
    _AgentSummary(
      name: 'Linda Mukamana',
      agentId: 'KG-205678',
      region: 'Kimironko',
      rating: 4.9,
      ratingCount: 31,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedBottomIndex = widget.initialIndex;
  }

  @override
  void dispose() {
    _regionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(textTheme),
          _buildSearchSection(textTheme),
          Expanded(
            child: _buildBodyForIndex(textTheme),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(textTheme),
    );
  }

  Widget _buildHeader(TextTheme textTheme) {
    return Container(
      color: _LandlordHomeColors.primaryDark,
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'expat',
              style: textTheme.titleLarge?.copyWith(
                color: _LandlordHomeColors.accentGreen,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            Row(
              children: const [
                Icon(Icons.notifications_none, color: Colors.white),
                SizedBox(width: 16),
                Icon(Icons.person_outline, color: Colors.white),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSection(TextTheme textTheme) {
    return Column(
      children: [
        Container(
          color: const Color(0xFFF4F5F7),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF4F5F7),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _LandlordHomeColors.bodyText),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            child: TextField(
              controller: _regionController,
              textInputAction: TextInputAction.search,
              style: textTheme.bodyMedium?.copyWith(
                color: _LandlordHomeColors.bodyText,
              ),
              decoration: InputDecoration(
                hintText: 'Type a Region',
                hintStyle: textTheme.bodyMedium?.copyWith(
                  color: _LandlordHomeColors.hint,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onSubmitted: (value) {
                setState(() {
                  _activeRegion = value.trim();
                });
              },
            ),
          ),
        ),
        Container(
          height: 2,
          color: _LandlordHomeColors.accentGreen,
        ),
      ],
    );
  }

  Widget _buildBodyForIndex(TextTheme textTheme) {
    if (_selectedBottomIndex == 0) {
      if (_activeRegion.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              "Welcome to 'Find Agents'. Here you will be able to "
              'browse the RWAREB\'s list of verified Agents according to their various regions.',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: _LandlordHomeColors.bodyText,
              ),
            ),
          ),
        );
      }

      final query = _activeRegion.toLowerCase();
      final matches = _agents
          .where(
            (a) => a.region.toLowerCase().contains(query),
          )
          .toList();

      if (matches.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'No agents found for "$_activeRegion".',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: _LandlordHomeColors.helper,
              ),
            ),
          ),
        );
      }

      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: matches.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final agent = matches[index];
          return _buildAgentCard(context, agent, textTheme);
        },
      );
    }

    if (_selectedBottomIndex == 1) {
      return Center(
        child: Text(
          'Landlord Estates view will live here.',
          style: textTheme.bodyMedium?.copyWith(
            color: _LandlordHomeColors.helper,
          ),
        ),
      );
    }

    if (_selectedBottomIndex == 2) {
      return const MessagesScreen();
    }

    // Payments tab placeholder.
    return Center(
      child: Text(
        'Payments will live here.',
        style: textTheme.bodyMedium?.copyWith(
          color: _LandlordHomeColors.helper,
        ),
      ),
    );
  }

  Widget _buildBottomNav(TextTheme textTheme) {
    return Container(
      decoration: BoxDecoration(
        color: _LandlordHomeColors.primaryDark,
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
                _buildBottomItem(
                  textTheme,
                  index: 0,
                  imagePath: 'assets/images/Community Icon.png',
                  label: 'Find Agent',
                ),
                _buildBottomItem(
                  textTheme,
                  index: 1,
                  imagePath: 'assets/images/Estates Icon.png',
                  label: 'Estates',
                ),
                _buildBottomItem(
                  textTheme,
                  index: 2,
                  imagePath: 'assets/images/Messages icon.png',
                  label: 'Messages',
                ),
                _buildBottomItem(
                  textTheme,
                  index: 3,
                  imagePath: 'assets/images/Payment Icon.png',
                  label: 'Payments',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomItem(
    TextTheme textTheme, {
    required int index,
    required String imagePath,
    required String label,
  }) {
    final bool selected = _selectedBottomIndex == index;
    final Color color =
        selected ? _LandlordHomeColors.accentGreen : Colors.white;

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
            errorBuilder: (_, __, ___) =>
                Icon(Icons.circle, size: 22, color: color),
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

class _AgentSummary {
  const _AgentSummary({
    required this.name,
    required this.agentId,
    required this.region,
    required this.rating,
    required this.ratingCount,
  });

  final String name;
  final String agentId;
  final String region;
  final double rating;
  final int ratingCount;
}

Widget _buildAgentCard(
  BuildContext context,
  _AgentSummary agent,
  TextTheme textTheme,
) {
  return InkWell(
    onTap: () {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => AgentProfileScreen(
            agentName: agent.name,
            agentFullName: agent.name,
            agentId: agent.agentId,
            locationTag: agent.region,
            showAssignProperty: true,
          ),
        ),
      );
    },
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey.shade300,
                child: const Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      agent.name,
                      style: textTheme.titleMedium?.copyWith(
                        color: _LandlordHomeColors.bodyText,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Agent ID: ${agent.agentId}',
                      style: textTheme.bodySmall?.copyWith(
                        color: _LandlordHomeColors.hint,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _LandlordHomeColors.hint.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  agent.region,
                  style: textTheme.bodySmall?.copyWith(
                    color: _LandlordHomeColors.bodyText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.verified,
                  size: 18, color: _LandlordHomeColors.accentGreen),
              const SizedBox(width: 4),
              Text(
                'RWAREB verified Agent',
                style: textTheme.bodySmall?.copyWith(
                  color: _LandlordHomeColors.accentGreen,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                agent.rating.toStringAsFixed(1),
                style: textTheme.titleMedium?.copyWith(
                  color: _LandlordHomeColors.bodyText,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.star,
                  size: 18, color: _LandlordHomeColors.bodyText),
              const SizedBox(width: 8),
              Text(
                '${agent.ratingCount}+ Ratings',
                style: textTheme.bodySmall?.copyWith(
                  color: _LandlordHomeColors.hint,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}


