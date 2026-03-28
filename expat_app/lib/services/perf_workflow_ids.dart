/// Stable IDs for cross-run / cross-chart workflow performance comparison.
///
/// Each probe run exports one row per [workflowIds] with the same stat keys
/// (`avg_ms`, `max_ms`, `p90_ms`, …) so Sheets/Python can plot grouped bars.
abstract final class PerfWorkflowIds {
  static const landlordListingUpload = 'landlord_listing_upload';
  static const messageTranslate = 'message_translate';
  static const ridesEstimate = 'rides_estimate';
  static const explorePlaces = 'explore_places';
  static const listingAssignment = 'listing_assignment';

  /// Order used for charts (legend / bar clusters).
  static const List<String> chartOrder = <String>[
    landlordListingUpload,
    messageTranslate,
    ridesEstimate,
    explorePlaces,
    listingAssignment,
  ];

  static const Map<String, String> labels = <String, String>{
    landlordListingUpload: 'Landlord listing upload',
    messageTranslate: 'Message translate (ML Kit)',
    ridesEstimate: 'Rides (Directions + fare estimate)',
    explorePlaces: 'Explore (Places autocomplete)',
    listingAssignment: 'Listing assignment',
  };
}
