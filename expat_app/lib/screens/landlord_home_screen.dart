import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:expat_app/models/licensed_agent.dart';
import 'package:expat_app/services/agents_service.dart';
import 'package:expat_app/services/auth_service.dart';
import 'agent_profile_screen.dart';
import 'landlord_estates_screen.dart';
import 'landlord_make_listing_screen.dart';
import 'landlord_payments_screen.dart';
import 'messages_screen.dart' show MessagesScreen, kRoleLandlord;

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
  /// Verification badge and "RWAREB verified Agent" text (blue for contrast on white).
  static const Color verifiedBlue = Color(0xFF1976D2);
}

class _LandlordHomeScreenState extends State<LandlordHomeScreen> {
  int _selectedBottomIndex = 0; // 0 = Find Agent, 1 = Estates, 2 = Messages, 3 = Payments
  final TextEditingController _regionController = TextEditingController();
  String _activeRegion = '';
  String _userName = '';
  String _userEmail = '';
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
        _userEmail = profile.email;
        _userProfileImageUrl = profile.profileImageUrl;
      });
    }
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
          if (_selectedBottomIndex == 0) _buildSearchSection(textTheme),
          Expanded(
            child: _buildBodyForIndex(textTheme),
          ),
        ],
      ),
      floatingActionButtonLocation: const _LandlordMakeListingFabLocation(),
      floatingActionButton: _selectedBottomIndex == 1
          ? _buildMakeListingButton(context, textTheme)
          : null,
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
              children: [
                const Icon(Icons.notifications_none, color: Colors.white),
                const SizedBox(width: 8),
                _buildProfileMenu(textTheme),
              ],
            ),
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
      backgroundColor: _LandlordHomeColors.accentGreen,
      child: Text(
        _userName.isNotEmpty ? _userName[0].toUpperCase() : '?',
        style: TextStyle(
          color: _LandlordHomeColors.primaryDark,
          fontWeight: FontWeight.w600,
          fontSize: radius * 0.9,
        ),
      ),
    );
  }

  Widget _buildProfileMenu(TextTheme textTheme) {
    return GestureDetector(
      onTap: () => _showProfilePopup(textTheme),
      child: _buildProfileAvatar(),
    );
  }

  void _showProfilePopup(TextTheme textTheme) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return _LandlordProfilePopup(
          userName: _userName,
          userEmail: _userEmail,
          profileImageUrl: _userProfileImageUrl,
          onImageUpdated: (url) {
            setState(() => _userProfileImageUrl = url);
          },
        );
      },
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

      return StreamBuilder<List<LicensedAgent>>(
        stream: AgentsService().agentsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final allAgents = snapshot.data ?? [];
      final query = _activeRegion.toLowerCase();
          final matches = allAgents
              .where((a) => a.region.toLowerCase().contains(query))
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
        },
      );
    }

    if (_selectedBottomIndex == 1) {
      return const LandlordEstatesScreen();
    }

    if (_selectedBottomIndex == 2) {
      return MessagesScreen(currentUserRole: kRoleLandlord);
    }

    // Payments tab.
    return const LandlordPaymentsScreen();
  }

  Widget _buildBottomNav(TextTheme textTheme) {
    return Container(
      decoration: BoxDecoration(
        color: _LandlordHomeColors.primaryDark,
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

/// [endDocked] overlaps the bottom bar by design; this uses [endFloat] plus extra
/// lift so the wide "Make a Listing" control clears the landlord nav + home indicator.
class _LandlordMakeListingFabLocation extends FloatingActionButtonLocation {
  const _LandlordMakeListingFabLocation();

  static const double _extraLift = 16;

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final base =
        FloatingActionButtonLocation.endFloat.getOffset(scaffoldGeometry);
    return Offset(base.dx, base.dy - _extraLift);
  }

  @override
  String toString() => 'LandlordMakeListingFabLocation';
}

Widget _buildMakeListingButton(BuildContext context, TextTheme textTheme) {
  const bodyText = _LandlordHomeColors.bodyText;
  const accentGreen = _LandlordHomeColors.accentGreen;
  final width = MediaQuery.of(context).size.width;

  // Builder gives correct context for Navigator. Avoid Transform.translate here —
  // it moves the button visually but hit-testing stays in the original place, so taps miss.
  return Builder(
    builder: (ctx) {
      return SizedBox(
      height: 56,
      width: (width * 0.52).clamp(200.0, width - 24),
      child: ElevatedButton(
        onPressed: () {
            Navigator.of(ctx).push(
            MaterialPageRoute<void>(
              builder: (_) => const LandlordMakeListingScreen(),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: accentGreen,
          foregroundColor: bodyText,
          elevation: 6,
          side: const BorderSide(
            color: Colors.black,
            width: 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: Text(
                  'Make a Listing',
                  maxLines: 1,
                  style: textTheme.titleMedium?.copyWith(
                    color: bodyText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.add,
              size: 24,
              color: bodyText,
            ),
          ],
        ),
      ),
      );
    },
  );
}

Widget _buildAgentCard(
  BuildContext context,
  LicensedAgent agent,
  TextTheme textTheme,
) {
  return InkWell(
    onTap: () {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => AgentProfileScreen(
            agentName: agent.fullName,
            agentFullName: agent.fullName,
            agentId: agent.agentId,
            locationTag: agent.region,
            bio: agent.bio,
            phone: agent.phone ?? '',
            rating: agent.rating,
            ratingCount: agent.ratingCount,
            profileImageUrl: agent.profileImageUrl,
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
            color: Colors.black.withValues(alpha: 0.04),
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
                      agent.fullName,
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
                  color: _LandlordHomeColors.hint.withValues(alpha: 0.2),
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
                  size: 18, color: _LandlordHomeColors.verifiedBlue),
              const SizedBox(width: 4),
              Text(
                'RWAREB verified Agent',
                style: textTheme.bodySmall?.copyWith(
                  color: _LandlordHomeColors.verifiedBlue,
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

class _LandlordProfilePopup extends StatefulWidget {
  const _LandlordProfilePopup({
    required this.userName,
    required this.userEmail,
    required this.profileImageUrl,
    required this.onImageUpdated,
  });

  final String userName;
  final String userEmail;
  final String? profileImageUrl;
  final ValueChanged<String> onImageUpdated;

  @override
  State<_LandlordProfilePopup> createState() => _LandlordProfilePopupState();
}

class _LandlordProfilePopupState extends State<_LandlordProfilePopup> {
  String? _imageUrl;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _imageUrl = widget.profileImageUrl;
  }

  Future<void> _pickAndUpload() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;
    setState(() => _uploading = true);
    try {
      final url = await AuthService().uploadProfileImage(picked);
      if (mounted) {
        setState(() { _imageUrl = url; _uploading = false; });
        widget.onImageUpdated(url);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    const primaryDark = Color(0xFF1A2E35);
    const accentGreen = Color(0xFF8ED966);

    return Dialog(
      alignment: Alignment.topRight,
      backgroundColor: primaryDark,
      insetPadding: const EdgeInsets.only(top: 70, right: 12, left: 80),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                _uploading
                    ? const SizedBox(
                        width: 72, height: 72,
                        child: CircularProgressIndicator(strokeWidth: 3))
                    : CircleAvatar(
                        radius: 36,
                        backgroundColor: accentGreen,
                        backgroundImage: _imageUrl != null && _imageUrl!.isNotEmpty
                            ? NetworkImage(_imageUrl!)
                            : null,
                        child: _imageUrl == null || _imageUrl!.isEmpty
                            ? Text(
                                widget.userName.isNotEmpty
                                    ? widget.userName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: primaryDark,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 28,
                                ))
                            : null,
                      ),
                Positioned(
                  bottom: 0, right: 0,
                  child: GestureDetector(
                    onTap: _uploading ? null : _pickAndUpload,
                    child: Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: accentGreen,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt, size: 14, color: primaryDark),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(widget.userName,
                style: textTheme.titleMedium?.copyWith(
                    color: Colors.white, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(widget.userEmail,
                style: textTheme.bodySmall?.copyWith(color: Colors.white70)),
            const SizedBox(height: 20),
            const Divider(height: 1, color: Colors.white24),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.white),
              title: Text('Log out',
                  style: textTheme.bodyMedium?.copyWith(color: Colors.white)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              onTap: () async {
                Navigator.of(context, rootNavigator: true).pop();
                await AuthService().signOut();
              },
            ),
          ],
        ),
      ),
    );
  }
}
