import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:expat_app/services/auth_service.dart';
import 'agent_assigned_listings_screen.dart';
import 'agent_bio_view_screen.dart';
import 'agent_payments_screen.dart';
import 'agent_profile_screen.dart';
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
                  icon: const Icon(
                    Icons.notifications_none,
                    color: Colors.white,
                  ),
                  onPressed: () {},
                ),
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
        return _AgentProfilePopup(
          userName: _userName,
          userEmail: _userEmail,
          profileImageUrl: _userProfileImageUrl,
          onImageUpdated: (url) {
            setState(() => _userProfileImageUrl = url);
          },
          onViewProfile: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const AgentSignedInProfileScreen(),
              ),
            );
          },
        );
      },
    );
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

class _AgentProfilePopup extends StatefulWidget {
  const _AgentProfilePopup({
    required this.userName,
    required this.userEmail,
    required this.profileImageUrl,
    required this.onImageUpdated,
    required this.onViewProfile,
  });

  final String userName;
  final String userEmail;
  final String? profileImageUrl;
  final ValueChanged<String> onImageUpdated;
  final VoidCallback onViewProfile;

  @override
  State<_AgentProfilePopup> createState() => _AgentProfilePopupState();
}

class _AgentProfilePopupState extends State<_AgentProfilePopup> {
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
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: accentGreen,
                        ))
                    : CircleAvatar(
                        radius: 36,
                        backgroundColor: accentGreen,
                        backgroundImage:
                            _imageUrl != null && _imageUrl!.isNotEmpty
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
                      child: const Icon(Icons.camera_alt, size: 14,
                          color: primaryDark),
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
              leading: const Icon(Icons.person, color: Colors.white),
              title: Text('Profile',
                  style: textTheme.bodyMedium?.copyWith(color: Colors.white)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              onTap: () {
                Navigator.of(context).pop();
                widget.onViewProfile();
              },
            ),
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
