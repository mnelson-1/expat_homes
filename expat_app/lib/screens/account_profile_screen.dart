import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'package:expat_app/constants/user_profile_options.dart';
import 'package:expat_app/models/user_profile.dart';
import 'package:expat_app/services/agents_service.dart';
import 'package:expat_app/services/auth_service.dart';

import 'agent_edit_field_screen.dart';

/// Full-screen account profile: photo, sectional fields, role-specific ID, logout.
/// All roles: preferred language (same options as registration). Expats only:
/// country of citizenship (from registration, editable). Expat/Landlord may edit
/// name, email, bio; IDs read-only. Agent name/email read-only; bio & phone sync
/// with licensed_agents (bio-view).
class AccountProfileScreen extends StatefulWidget {
  const AccountProfileScreen({super.key, required this.role})
    : assert(
        role == UserRole.expat ||
            role == UserRole.landlord ||
            role == UserRole.agent,
        'Use expat, landlord, or agent only.',
      );

  final UserRole role;

  @override
  State<AccountProfileScreen> createState() => _AccountProfileScreenState();
}

class _AccountProfileScreenState extends State<AccountProfileScreen> {
  static const Color _primaryDark = Color(0xFF1A2E35);
  static const Color _accentGreen = Color(0xFF8ED966);
  static const Color _bgWhite = Color(0xFFFFFFFF);
  static const Color _rowSurface = Color(0xFFDFDFDF);
  String? _uid;
  String? _imageUrl;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _uid = AuthService().currentUser?.uid;
  }

  static (String, String) _splitFullName(String full) {
    final t = full.trim();
    final i = t.indexOf(' ');
    if (i < 0) return (t, '');
    return (t.substring(0, i).trim(), t.substring(i + 1).trim());
  }

  String get _idLabel {
    switch (widget.role) {
      case UserRole.agent:
        return 'Agent ID';
      case UserRole.landlord:
        return 'Landlord ID';
      case UserRole.expat:
        return 'Expat ID';
      case UserRole.superAdmin:
        return 'User ID';
    }
  }

  String _idDisplayValue(UserProfile? profile) {
    if (widget.role == UserRole.agent) {
      final aid = profile?.agentId;
      if (aid != null && aid.trim().isNotEmpty) return aid.trim();
      return '—';
    }
    return _uid ?? '—';
  }

  bool get _canEditNameEmail =>
      widget.role == UserRole.expat || widget.role == UserRole.landlord;

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
        setState(() {
          _imageUrl = url;
          _uploading = false;
        });
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

  EdgeInsets _pagePadding(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return EdgeInsets.fromLTRB(20, 24, 20, 28 + bottom + 24);
  }

  Future<void> _logout() async {
    await AuthService().signOut();
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _editName(UserProfile? profile, String currentName) async {
    if (!_canEditNameEmail) return;
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => AgentEditFieldScreen(
          title: 'Edit name',
          label: 'Name',
          hintText: 'Full name',
          helperText: 'This name may appear to landlords and agents.',
          initialValue: currentName == '—' ? '' : currentName,
          keyboardType: TextInputType.name,
        ),
      ),
    );
    if (result == null || result.trim().isEmpty || !mounted) return;
    final (first, last) = _splitFullName(result);
    try {
      await AuthService().updateLegalName(
        legalFirstName: first,
        legalLastName: last,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update name: $e')),
        );
      }
    }
  }

  Future<void> _editEmail(String currentEmail) async {
    if (!_canEditNameEmail) return;
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => AgentEditFieldScreen(
          title: 'Edit email',
          label: 'Email',
          hintText: 'you@example.com',
          helperText: 'Updates your profile. Sign-in email may require re-login.',
          initialValue: currentEmail == '—' ? '' : currentEmail,
          keyboardType: TextInputType.emailAddress,
        ),
      ),
    );
    if (result == null || result.trim().isEmpty || !mounted) return;
    try {
      await AuthService().updateUserEmail(result.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Profile email saved. Check your inbox to verify the new address for sign-in.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update email: $e')),
        );
      }
    }
  }

  String _languageDisplay(UserProfile? profile) {
    final s = profile?.preferredLanguage.trim();
    if (s == null || s.isEmpty) return 'English';
    return s;
  }

  String _countryDisplay(UserProfile? profile) {
    final s = profile?.countryOfCitizenship?.trim();
    if (s == null || s.isEmpty) return '—';
    return s;
  }

  Future<void> _pickPreferredLanguage(String currentDisplay) async {
    final options = <String>[
      ...kPreferredLanguages,
    ];
    if (!options.contains(currentDisplay)) {
      options.insert(0, currentDisplay);
    }
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Text(
                  'Preferred language',
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                    color: _primaryDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              for (final o in options)
                ListTile(
                  title: Text(
                    o,
                    style: const TextStyle(
                      color: _primaryDark,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing:
                      o == currentDisplay
                          ? const Icon(Icons.check, color: _primaryDark)
                          : null,
                  onTap: () => Navigator.pop(ctx, o),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (picked == null || !mounted || picked == currentDisplay) return;
    try {
      await AuthService().updatePreferredLanguage(picked);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update language: $e')),
        );
      }
    }
  }

  Future<void> _pickCountryOfCitizenship(String currentDisplay) async {
    final stored = currentDisplay == '—' ? '' : currentDisplay;
    final options = List<String>.from(kCountryOfCitizenshipOptions);
    if (stored.isNotEmpty && !options.contains(stored)) {
      options.insert(0, stored);
    }
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Text(
                  'Country of citizenship',
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                    color: _primaryDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              for (final o in options)
                ListTile(
                  title: Text(
                    o,
                    style: const TextStyle(
                      color: _primaryDark,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing:
                      o == stored
                          ? const Icon(Icons.check, color: _primaryDark)
                          : null,
                  onTap: () => Navigator.pop(ctx, o),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (picked == null || !mounted) return;
    if (stored.isNotEmpty && picked == stored) return;
    try {
      await AuthService().updateCountryOfCitizenship(picked);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update country: $e')),
        );
      }
    }
  }

  Future<void> _editBioExpatLandlord(String current) async {
    if (!_canEditNameEmail) return;
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => AgentEditFieldScreen(
          title: 'Edit bio',
          label: 'Bio',
          hintText: 'Tell others a bit about you',
          initialValue: current == '—' ? '' : current,
          keyboardType: TextInputType.multiline,
          maxLines: 4,
        ),
      ),
    );
    if (result == null || !mounted) return;
    try {
      await AuthService().updateUserBio(result.trim());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update bio: $e')),
        );
      }
    }
  }

  Future<void> _editBioAgent(String agentId, String current) async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => AgentEditFieldScreen(
          title: 'Edit bio',
          label: 'Bio',
          hintText: 'Describe your experience and languages',
          helperText:
              'Advertise yourself – languages you speak, etc. – and state your rates.',
          initialValue: current.isEmpty || current == '—' ? '' : current,
          keyboardType: TextInputType.multiline,
          maxLines: 4,
        ),
      ),
    );
    if (result == null || !mounted) return;
    try {
      await AgentsService().updateLicensedAgentProfile(
        agentId,
        bio: result.trim(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update bio: $e')),
        );
      }
    }
  }

  Future<void> _editPhoneAgent(String agentId, String current) async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => AgentEditFieldScreen(
          title: 'Edit phone number',
          label: 'Phone Number',
          hintText: 'Type new phone number',
          helperText: 'This will be used in receiving payments',
          initialValue: current.isEmpty || current == '—' ? '' : current,
          keyboardType: TextInputType.phone,
        ),
      ),
    );
    if (result == null || !mounted) return;
    try {
      await AgentsService().updateLicensedAgentProfile(
        agentId,
        phone: result.trim(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update phone: $e')),
        );
      }
    }
  }

  PreferredSizeWidget _appBar(BuildContext context, String title) {
    final textTheme = Theme.of(context).textTheme;
    return AppBar(
      backgroundColor: _primaryDark,
      foregroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.white),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      title: Text(
        title,
        style: textTheme.titleMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: _primaryDark,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _tappableRow({
    required String value,
    bool showChevron = true,
    VoidCallback? onTap,
  }) {
    return Material(
      color: _rowSurface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value.isEmpty ? '—' : value,
                  style: const TextStyle(
                    color: _primaryDark,
                    fontSize: 16,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (showChevron && onTap != null)
                Icon(
                  Icons.chevron_right,
                  color: _primaryDark.withValues(alpha: 0.35),
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _idRow(String idValue) {
    return Material(
      color: _rowSurface,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: SelectableText(
                idValue,
                style: const TextStyle(
                  color: _primaryDark,
                  fontSize: 15,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            IconButton(
              tooltip: 'Copy',
              onPressed: idValue == '—'
                  ? null
                  : () async {
                      await Clipboard.setData(ClipboardData(text: idValue));
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied to clipboard')),
                      );
                    },
              icon: Icon(
                Icons.copy,
                color: idValue == '—'
                    ? _primaryDark.withValues(alpha: 0.2)
                    : _primaryDark.withValues(alpha: 0.7),
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _readOnlyRow(String value) {
    return _tappableRow(value: value, showChevron: false, onTap: null);
  }

  Widget _logoutButton(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton.icon(
        onPressed: _logout,
        icon: Icon(Icons.logout_rounded, color: _primaryDark, size: 30),
        label: Text(
          'Log out',
          style: textTheme.titleMedium?.copyWith(
            color: _primaryDark,
            fontWeight: FontWeight.w900,
          ),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: _accentGreen,
          foregroundColor: _primaryDark,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _avatarBlock(String name, String? displayImage) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            if (_uploading)
              const SizedBox(
                width: 112,
                height: 112,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: _accentGreen,
                ),
              )
            else
              CircleAvatar(
                radius: 56,
                backgroundColor: _accentGreen,
                backgroundImage:
                    displayImage != null && displayImage.isNotEmpty
                        ? NetworkImage(displayImage)
                        : null,
                child:
                    displayImage == null || displayImage.isEmpty
                        ? Text(
                          name.isNotEmpty && name != '—'
                              ? name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: _primaryDark,
                            fontWeight: FontWeight.w700,
                            fontSize: 40,
                          ),
                        )
                        : null,
              ),
            if (!_uploading)
              Positioned(
                right: 4,
                bottom: 4,
                child: GestureDetector(
                  onTap: _pickAndUpload,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _accentGreen,
                      shape: BoxShape.circle,
                      border: Border.all(color: _rowSurface, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 18,
                      color: _primaryDark,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Edit',
          style: TextStyle(
            color: _primaryDark,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = _uid;

    if (uid == null) {
      return Scaffold(
        backgroundColor: _bgWhite,
        appBar: _appBar(context, 'Profile'),
        body: const Center(
          child: Text(
            'Not signed in.',
            style: TextStyle(color: _primaryDark),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _bgWhite,
      appBar: _appBar(context, 'Profile'),
      body: StreamBuilder<UserProfile?>(
        stream: AuthService().userProfileStream(uid),
        builder: (context, snap) {
          final profile = snap.data;
          final name =
              profile?.legalName ??
              AuthService().currentUser?.email ??
              '—';
          final email =
              profile?.email ??
              AuthService().currentUser?.email ??
              '—';
          final displayImage = _imageUrl ?? profile?.profileImageUrl;
          final idVal = _idDisplayValue(profile);
          final bioExpat = profile?.bio?.trim();
          final bioText = (bioExpat != null && bioExpat.isNotEmpty)
              ? bioExpat
              : '—';
          final langLine = _languageDisplay(profile);
          final countryLine = _countryDisplay(profile);

          if (widget.role == UserRole.agent) {
            final agentId = profile?.agentId;
            if (agentId == null || agentId.isEmpty) {
              return ListView(
                padding: _pagePadding(context),
                children: [
                  Center(child: _avatarBlock(name, displayImage)),
                  const SizedBox(height: 28),
                  _sectionLabel('Name'),
                  _readOnlyRow(name),
                  const SizedBox(height: 20),
                  _sectionLabel(_idLabel),
                  _idRow(idVal),
                  const SizedBox(height: 20),
                  _sectionLabel('Email'),
                  _readOnlyRow(email),
                  const SizedBox(height: 20),
                  _sectionLabel('Preferred language'),
                  _tappableRow(
                    value: langLine,
                    onTap: () => _pickPreferredLanguage(langLine),
                  ),
                  const SizedBox(height: 32),
                  _logoutButton(context),
                ],
              );
            }

            return FutureBuilder(
              key: ValueKey(agentId),
              future: AgentsService().getAgent(agentId),
              builder: (context, agentSnap) {
                final agent = agentSnap.data;
                final displayName = agent?.fullName ?? name;
                final bioAgent = agent?.bio?.trim();
                final phoneAgent = agent?.phone?.trim();
                final bioDisp =
                    (bioAgent != null && bioAgent.isNotEmpty) ? bioAgent : '—';
                final phoneDisp =
                    (phoneAgent != null && phoneAgent.isNotEmpty)
                        ? phoneAgent
                        : '—';

                return ListView(
                  padding: _pagePadding(context),
                  children: [
                    Center(child: _avatarBlock(displayName, displayImage)),
                    const SizedBox(height: 28),
                    _sectionLabel('Name'),
                    _readOnlyRow(displayName),
                    const SizedBox(height: 20),
                    _sectionLabel(_idLabel),
                    _idRow(idVal),
                    const SizedBox(height: 20),
                    _sectionLabel('Email'),
                    _readOnlyRow(email),
                    const SizedBox(height: 20),
                    _sectionLabel('Preferred language'),
                    _tappableRow(
                      value: langLine,
                      onTap: () => _pickPreferredLanguage(langLine),
                    ),
                    const SizedBox(height: 20),
                    _sectionLabel('Bio'),
                    _tappableRow(
                      value: bioDisp,
                      onTap: () => _editBioAgent(agentId, bioDisp),
                    ),
                    const SizedBox(height: 20),
                    _sectionLabel('Phone number'),
                    _tappableRow(
                      value: phoneDisp,
                      onTap: () => _editPhoneAgent(agentId, phoneDisp),
                    ),
                    const SizedBox(height: 32),
                    _logoutButton(context),
                  ],
                );
              },
            );
          }

          // Expat / landlord
          return ListView(
            padding: _pagePadding(context),
            children: [
              Center(child: _avatarBlock(name, displayImage)),
              const SizedBox(height: 28),
              _sectionLabel('Name'),
              _tappableRow(
                value: name,
                onTap: () => _editName(profile, name),
              ),
              const SizedBox(height: 20),
              _sectionLabel(_idLabel),
              _idRow(idVal),
              const SizedBox(height: 20),
              _sectionLabel('Email'),
              _tappableRow(
                value: email,
                onTap: () => _editEmail(email),
              ),
              const SizedBox(height: 20),
              _sectionLabel('Preferred language'),
              _tappableRow(
                value: langLine,
                onTap: () => _pickPreferredLanguage(langLine),
              ),
              if (widget.role == UserRole.expat) ...[
                const SizedBox(height: 20),
                _sectionLabel('Country of citizenship'),
                _tappableRow(
                  value: countryLine,
                  onTap: () => _pickCountryOfCitizenship(countryLine),
                ),
              ],
              const SizedBox(height: 20),
              _sectionLabel('Bio'),
              _tappableRow(
                value: bioText,
                onTap: () => _editBioExpatLandlord(
                  bioText == '—' ? '' : bioText,
                ),
              ),
              const SizedBox(height: 32),
              _logoutButton(context),
            ],
          );
        },
      ),
    );
  }
}
