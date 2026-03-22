import 'package:expat_app/models/listing.dart';

/// Default listing currency in UI (landlord form collects USD amount).
const String kListingCurrencySymbol = '\$';

/// Billing phrase for the reference design, e.g. "$857/per month".
String defaultBillingSuffix(ListingType type) {
  switch (type) {
    case ListingType.shortStay:
      return 'per night';
    case ListingType.apartment:
    case ListingType.house:
      return 'per month';
  }
}

/// Strips currency, commas, and `/suffix` to get the numeric part for forms and storage.
String listingPriceNumericCore(String raw) {
  var s = raw.trim();
  if (s.contains('/')) {
    s = s.split('/').first.trim();
  }
  s = s.replaceAll(RegExp(r'[\$,]'), '').trim();
  final m = RegExp(r'(\d+\.?\d*|\.\d+)').firstMatch(s);
  return m?.group(0) ?? '';
}

String _formatThousands(String intPart) {
  if (intPart.isEmpty) return '0';
  final reversed = intPart.split('').reversed.join();
  final buf = StringBuffer();
  for (var i = 0; i < reversed.length; i++) {
    if (i > 0 && i % 3 == 0) buf.write(',');
    buf.write(reversed[i]);
  }
  return buf.toString().split('').reversed.join();
}

/// Adds comma grouping to integer part; preserves one decimal segment if present.
String formatListingAmountWithCommas(String core) {
  if (core.isEmpty) return '0';
  final parts = core.split('.');
  final intPart = parts[0].isEmpty ? '0' : parts[0];
  final dec = parts.length > 1 ? '.${parts[1]}' : '';
  return '${_formatThousands(intPart)}$dec';
}

String _canonicalSuffixFromStored(String rest, ListingType fallbackType) {
  final low = rest.toLowerCase().replaceAll('-', ' ');
  if (low.contains('night')) return 'per night';
  if (low.contains('month') || low == 'mo') return 'per month';
  if (rest.trim().isNotEmpty) return rest.trim();
  return defaultBillingSuffix(fallbackType);
}

/// Split for [RichText]: bold currency+amount, smaller "/per month" or "/per night".
class ListingPriceParts {
  const ListingPriceParts(this.amountWithSymbol, this.slashSuffix);

  /// e.g. `$857` or `$1,234.50`
  final String amountWithSymbol;

  /// e.g. `/per month` (includes leading slash)
  final String slashSuffix;
}

ListingPriceParts splitListingPriceForDisplay(
  ListingType type,
  String raw,
) {
  final trimmed = raw.trim();
  var amountSegment = trimmed;
  var suffixWords = defaultBillingSuffix(type);

  if (trimmed.contains('/')) {
    final idx = trimmed.indexOf('/');
    amountSegment = trimmed.substring(0, idx).trim();
    final rest = trimmed.substring(idx + 1).trim();
    if (rest.isNotEmpty) {
      suffixWords = _canonicalSuffixFromStored(rest, type);
    }
  }

  var core = listingPriceNumericCore(amountSegment);
  if (core.isEmpty) core = '0';
  final pretty = formatListingAmountWithCommas(core);

  return ListingPriceParts(
    '$kListingCurrencySymbol$pretty',
    '/$suffixWords',
  );
}

/// Single string for messages metadata, assignment flow, etc.
String formatListingPricePlain(ListingType type, String raw) {
  final p = splitListingPriceForDisplay(type, raw);
  return '${p.amountWithSymbol}${p.slashSuffix}';
}

/// Best-effort type when only the stored price string is available (e.g. old conversations).
ListingType inferListingTypeFromPriceString(String raw) {
  final lower = raw.toLowerCase();
  if (lower.contains('night')) return ListingType.shortStay;
  return ListingType.apartment;
}

/// Display price for conversation cards when [listingType] is unknown.
String formatConversationListingPrice(String raw) {
  return formatListingPricePlain(
    inferListingTypeFromPriceString(raw),
    raw,
  );
}
