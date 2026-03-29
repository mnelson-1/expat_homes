/// Stable IDs for workflow performance export (role-specific charts).
///
/// Each probe run exports one row per role with [chartOrderForRole] keys and the same
/// stat keys (`avg_ms`, `max_ms`, `p90_ms`, `n`).
abstract final class PerfWorkflowIds {
  // --- Landlord (listing, assignment, payments tab data, messaging) ---
  static const landlordListingCreation = 'landlord_listing_creation';
  static const landlordListingAssignment = 'landlord_listing_assignment';
  static const landlordPaymentWorkflow = 'landlord_payment_workflow';
  static const landlordMessaging = 'landlord_messaging';

  static const List<String> chartOrderLandlord = <String>[
    landlordListingCreation,
    landlordListingAssignment,
    landlordPaymentWorkflow,
    landlordMessaging,
  ];

  // --- Agent (payments, assignments load, bio-view update) ---
  static const agentPaymentWorkflow = 'agent_payment_workflow';
  static const agentListingAssignment = 'agent_listing_assignment';
  static const agentBioViewUpdate = 'agent_bio_view_update';

  static const List<String> chartOrderAgent = <String>[
    agentPaymentWorkflow,
    agentListingAssignment,
    agentBioViewUpdate,
  ];

  // --- Expat (Places explore, rides/directions, community feed, listing inquiry) ---
  static const expatExploreArea = 'expat_explore_area';
  static const expatRidesMaps = 'expat_rides_maps';
  static const expatCommunityWorkflow = 'expat_community_workflow';
  static const expatListingInquiryMessaging = 'expat_listing_inquiry_messaging';

  static const List<String> chartOrderExpat = <String>[
    expatExploreArea,
    expatRidesMaps,
    expatCommunityWorkflow,
    expatListingInquiryMessaging,
  ];

  static List<String> chartOrderForRole(String role) {
    switch (role.trim().toLowerCase()) {
      case 'landlord':
        return chartOrderLandlord;
      case 'agent':
        return chartOrderAgent;
      case 'expat':
        return chartOrderExpat;
      default:
        return chartOrderLandlord;
    }
  }

  /// Human-readable labels (charts / docs).
  static const Map<String, String> labels = <String, String>{
    landlordListingCreation: 'Listing creation',
    landlordListingAssignment: 'Listing assignment',
    landlordPaymentWorkflow: 'Payment workflow (commission slips)',
    landlordMessaging: 'Messaging',
    agentPaymentWorkflow: 'Payment workflow (commission slips)',
    agentListingAssignment: 'Listing assignment (your assignments)',
    agentBioViewUpdate: 'Bio-View update',
    expatExploreArea: 'Explore area (Places)',
    expatRidesMaps: 'Rides / maps (Directions)',
    expatCommunityWorkflow: 'Community (feed)',
    expatListingInquiryMessaging: 'Listing inquiry & messaging',
  };
}
