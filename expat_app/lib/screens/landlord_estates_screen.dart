import 'package:flutter/material.dart';

import 'package:expat_app/models/listing.dart';
import 'package:expat_app/models/listing_edit_request.dart';
import 'package:expat_app/services/auth_service.dart';
import 'package:expat_app/services/edit_requests_service.dart';
import 'package:expat_app/services/listings_service.dart';
import 'landlord_make_listing_screen.dart';
import 'listing_detail_screen.dart';

class LandlordEstatesScreen extends StatefulWidget {
  const LandlordEstatesScreen({super.key});

  @override
  State<LandlordEstatesScreen> createState() => _LandlordEstatesScreenState();
}

class _LandlordEstatesColors {
  static const Color bodyText = Color(0xFF1A2E35);
  static const Color hint = Color(0xFF9CA5A8);
}

class _LandlordEstateFilter {
  const _LandlordEstateFilter({required this.label, required this.index});
  final String label;
  final int index;
}

class _LandlordEstatesScreenState extends State<LandlordEstatesScreen> {
  int _selectedFilter = 0; // 0 = All

  static const List<_LandlordEstateFilter> _filters = [
    _LandlordEstateFilter(label: 'All', index: 0),
    _LandlordEstateFilter(label: 'Apartments', index: 1),
    _LandlordEstateFilter(label: 'Houses', index: 2),
    _LandlordEstateFilter(label: 'Short-Stay', index: 3),
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final uid = AuthService().currentUser?.uid;
    if (uid == null) {
      return Center(
        child: Text(
          'Sign in as a landlord to see your listings.',
          style: textTheme.bodyMedium?.copyWith(
            color: _LandlordEstatesColors.hint,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return StreamBuilder<List<Listing>>(
      stream: ListingsService().landlordListingsStream(uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: textTheme.bodySmall?.copyWith(color: Colors.red),
            ),
          );
        }
        final all = snapshot.data ?? [];
        final estates = _filterListings(all);
        return _buildContent(context, textTheme, estates);
      },
    );
  }

  List<Listing> _filterListings(List<Listing> list) {
    if (_selectedFilter == 0) return list;
    final type =
        _selectedFilter == 1
            ? ListingType.apartment
            : _selectedFilter == 2
            ? ListingType.house
            : ListingType.shortStay;
    return list.where((e) => e.type == type).toList();
  }

  Widget _buildContent(
    BuildContext context,
    TextTheme textTheme,
    List<Listing> estates,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Center(
          child: Text(
            'My Listings',
            style: textTheme.titleMedium?.copyWith(
              color: _LandlordEstatesColors.bodyText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 8),
        _buildFilters(textTheme),
        const Divider(height: 1, color: Color(0xFFE0E0E0)),
        Expanded(
          child:
              estates.isEmpty
                  ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'No listings yet.',
                          style: textTheme.bodyMedium?.copyWith(
                            color: _LandlordEstatesColors.hint,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder:
                                    (_) => const LandlordMakeListingScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Create a listing'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF8ED966),
                            foregroundColor: const Color(0xFF1A2E35),
                          ),
                        ),
                      ],
                    ),
                  )
                  : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    itemCount: estates.length,
                    itemBuilder: (context, index) {
                      final estate = estates[index];
                      if (index > 0) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Divider(height: 1, color: Color(0xFFE0E0E0)),
                            _buildEstateCard(context, textTheme, estate),
                          ],
                        );
                      }
                      return _buildEstateCard(context, textTheme, estate);
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildFilters(TextTheme textTheme) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x26000000),
            offset: Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: _filters.map((f) => _buildFilterItem(textTheme, f)).toList(),
      ),
    );
  }

  Widget _buildFilterItem(TextTheme textTheme, _LandlordEstateFilter filter) {
    final selected = filter.index == _selectedFilter;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = filter.index),
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              filter.label,
              style: textTheme.titleMedium?.copyWith(
                color:
                    selected
                        ? _LandlordEstatesColors.bodyText
                        : _LandlordEstatesColors.hint,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              height: 2,
              width: double.infinity,
              color:
                  selected
                      ? _LandlordEstatesColors.bodyText
                      : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstateCard(
    BuildContext context,
    TextTheme textTheme,
    Listing estate,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder:
                      (_) => ListingDetailScreenById(
                        listingId: estate.id,
                        showRequestEditOnly: true,
                      ),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _buildListingImage(estate, height: 180),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            estate.title,
                            style: textTheme.titleMedium?.copyWith(
                              color: _LandlordEstatesColors.bodyText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            estate.location,
                            style: textTheme.bodySmall?.copyWith(
                              color: _LandlordEstatesColors.bodyText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _LandlordEstatesColors.hint,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            estate.typeLabel,
                            style: textTheme.bodySmall?.copyWith(
                              color: _LandlordEstatesColors.bodyText,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Builder(
                          builder: (_) {
                            final parts = estate.price.split('/');
                            final amount =
                                parts.isNotEmpty
                                    ? parts[0]
                                    : estate.price; // "$857"
                            final suffix =
                                parts.length > 1 ? '/${parts[1]}' : '';
                            return Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: amount,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: textTheme.titleSmall?.fontSize,
                                      color: _LandlordEstatesColors.bodyText,
                                    ),
                                  ),
                                  TextSpan(
                                    text: suffix,
                                    style: TextStyle(
                                      fontWeight: FontWeight.normal,
                                      fontSize: textTheme.bodySmall?.fontSize,
                                      color: _LandlordEstatesColors.bodyText,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildEditRequestButton(context, textTheme, estate),
        ],
      ),
    );
  }

  /// Contextual edit-request button per listing. Streams the latest
  /// edit request so the label and color update in real time.
  Widget _buildEditRequestButton(
    BuildContext context,
    TextTheme textTheme,
    Listing estate,
  ) {
    return StreamBuilder<ListingEditRequest?>(
      stream: EditRequestsService().listingEditRequestStream(estate.id),
      builder: (context, snapshot) {
        final req = snapshot.data;
        final status = req?.status;

        final String label;
        final Color bgColor;
        final Color fgColor;
        final VoidCallback? onPressed;

        if (status == EditRequestStatus.pending) {
          label = 'Edit Request being Processed';
          bgColor = const Color(0xFFFFD54F);
          fgColor = _LandlordEstatesColors.bodyText;
          onPressed = null;
        } else if (status == EditRequestStatus.approved) {
          label = 'Edit Request Approved';
          bgColor = const Color(0xFF8ED966);
          fgColor = _LandlordEstatesColors.bodyText;
          onPressed = null;
        } else {
          label = 'Request Edit';
          bgColor = _LandlordEstatesColors.bodyText;
          fgColor = Colors.white;
          onPressed = () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder:
                    (_) => LandlordMakeListingScreen(
                      isEdit: true,
                      listingId: estate.id,
                      initialTitle: estate.title,
                      initialPrice: estate.price,
                      initialLocation: estate.location,
                      initialDescription: estate.description,
                      initialUpi: estate.upi,
                      initialOwnerName: estate.representativeName,
                    ),
              ),
            );
          };
        }

        return SizedBox(
          width: double.infinity,
          height: 44,
          child: FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: bgColor,
              foregroundColor: fgColor,
              disabledBackgroundColor: bgColor,
              disabledForegroundColor: fgColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(7),
              ),
              textStyle: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            child: Text(label),
          ),
        );
      },
    );
  }

  Widget _buildListingImage(Listing estate, {required double height}) {
    final url = estate.firstImageUrl;
    if (url == null || url.isEmpty) {
      return Container(
        height: height,
        color: Colors.grey.shade300,
        child: const Center(
          child: Icon(Icons.home, size: 48, color: Colors.grey),
        ),
      );
    }
    if (url.startsWith('http')) {
      return Image.network(
        url,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder:
            (_, __, ___) => Container(
              height: height,
              color: Colors.grey.shade300,
              child: const Center(child: Icon(Icons.broken_image)),
            ),
      );
    }
    return Image.asset(
      url,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder:
          (_, __, ___) =>
              Container(height: height, color: Colors.grey.shade300),
    );
  }
}
