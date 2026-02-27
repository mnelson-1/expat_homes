import 'package:flutter/material.dart';

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

class _LandlordEstate {
  const _LandlordEstate({
    required this.title,
    required this.location,
    required this.price,
    required this.type,
    required this.imagePath,
    required this.description,
    required this.upi,
  });

  final String title;
  final String location;
  final String price;
  final String type; // apartment | house | short_stay
  final String imagePath;
  final String description;
  final String upi;
}

class _LandlordEstatesScreenState extends State<LandlordEstatesScreen> {
  int _selectedFilter = 0; // 0 = All

  static const List<_LandlordEstateFilter> _filters = [
    _LandlordEstateFilter(label: 'All', index: 0),
    _LandlordEstateFilter(label: 'Apartments', index: 1),
    _LandlordEstateFilter(label: 'Houses', index: 2),
    _LandlordEstateFilter(label: 'Short-Stay', index: 3),
  ];

  static const List<_LandlordEstate> _estates = [
    _LandlordEstate(
      title: 'Charm Nest Apartments',
      location: 'KG 286, Kigali Rwanda',
      price: '\$857/mo',
      type: 'apartment',
      imagePath: 'assets/images/Apartments/Charm Nest Apartments/1.jpg',
      description:
          'Charm Nest Apartment by Link in Kigali offers a garden, open-air bath, indoor swimming pool, and free WiFi. Guests enjoy a lounge, lift, 24-hour front desk, and free on-site private parking.\n\nThe apartment features a kitchenette, balcony, washing machine, private bathroom, and city views. Additional amenities include a dining area, work desk, and free WiFi.\n\nLocated 7 km from Kigali International Airport, the property is a 12-minute walk from Kigali Golf Club. Nearby attractions include Niyo Arts Gallery (3.2 km) and Kigali Convention Centre (5 km).',
      upi: 'KG286-APARTMENT-UPI-001',
    ),
    _LandlordEstate(
      title: 'Green Valley Villa',
      location: '49 KG 706 Street 1, Kigali',
      price: '\$2,754/mo',
      type: 'house',
      imagePath: 'assets/images/Houses/Green Valley Villa/1.jpg',
      description:
          'Green Valley Villa in Kigali offers a spacious home with multiple bedrooms, private bathrooms, and a fully equipped kitchen. Guests can enjoy a quiet neighborhood setting with easy access to local amenities.\n\nThe villa includes a balcony, secure parking, and a comfortable living area suitable for both short and long stays.\n\nLocated within driving distance of Kigali\'s key attractions, it provides a good balance of privacy and convenience for families or groups.',
      upi: 'KG706-VILLA-UPI-002',
    ),
    _LandlordEstate(
      title: 'Olympic Hotel',
      location: 'KG 11 AVE, Kigali Rwanda',
      price: '\$1,796/night',
      type: 'short_stay',
      imagePath: 'assets/images/Short-Stay/Olympic Hotel/1.jpg',
      description:
          'Olympic Hotel in Kigali provides hotel-style rooms with on-site dining, bar, and conference facilities. Guests benefit from free WiFi, a 24-hour front desk, and secure parking.\n\nRooms feature private bathrooms, work desks, and comfortable bedding suitable for business and leisure travelers.\n\nThe hotel is conveniently located near key city points of interest, offering quick access to major roads and services.',
      upi: 'KG11-HOTEL-UPI-003',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final estates = _filteredEstates;

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
          child: ListView.builder(
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

  List<_LandlordEstate> get _filteredEstates {
    if (_selectedFilter == 0) return _estates;
    final key = _selectedFilter == 1
        ? 'apartment'
        : _selectedFilter == 2
            ? 'house'
            : 'short_stay';
    return _estates.where((e) => e.type == key).toList();
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
        children:
            _filters.map((f) => _buildFilterItem(textTheme, f)).toList(),
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
                color: selected
                    ? _LandlordEstatesColors.bodyText
                    : _LandlordEstatesColors.hint,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              height: 2,
              width: double.infinity,
              color: selected
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
    _LandlordEstate estate,
  ) {
    final typeLabel = estate.type == 'apartment'
        ? 'Apartment'
        : estate.type == 'house'
            ? 'House'
            : 'Short-Stay';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ListingDetailScreen(
                    title: estate.title,
                    location: estate.location,
                    price: estate.price,
                    typeLabel: typeLabel,
                    imagePaths: [estate.imagePath],
                    description: estate.description,
                    upi: estate.upi,
                    isVerifiedByRdb: true,
                    representativeName: 'Jean Claude (Agent)',
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
                  child: Image.asset(
                    estate.imagePath,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 180,
                      color: Colors.grey.shade300,
                    ),
                  ),
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
                            typeLabel,
                            style: textTheme.bodySmall?.copyWith(
                              color: _LandlordEstatesColors.bodyText,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Builder(
                          builder: (_) {
                            final parts = estate.price.split('/');
                            final amount = parts.isNotEmpty
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
                                      fontSize:
                                          textTheme.titleSmall?.fontSize,
                                      color: _LandlordEstatesColors.bodyText,
                                    ),
                                  ),
                                  TextSpan(
                                    text: suffix,
                                    style: TextStyle(
                                      fontWeight: FontWeight.normal,
                                      fontSize:
                                          textTheme.bodySmall?.fontSize,
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
          SizedBox(
            width: double.infinity,
            height: 44,
            child: FilledButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => LandlordMakeListingScreen(
                      isEdit: true,
                      initialTitle: estate.title,
                      initialPrice: estate.price,
                      initialLocation: estate.location,
                      initialDescription: estate.description,
                      // UPI and owner name will be wired in once
                      // backend data is available.
                      initialUpi: null,
                      initialOwnerName: null,
                    ),
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: _LandlordEstatesColors.bodyText,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
                textStyle: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: const Text('Request Edit'),
            ),
          ),
        ],
      ),
    );
  }

}

