/// Named routes registered on [MaterialApp.onGenerateRoute].
/// Keeps chat → listing navigation out of [messages_screen] ↔ [listing_detail_screen] import cycles.
abstract final class AppRouteNames {
  static const listingDetailFromChat = '/listing-detail-from-chat';
}
