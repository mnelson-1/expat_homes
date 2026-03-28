/// Result of "Get a Ride" / "Explore Area" on a listing detail sheet.
class ListingLocationPayload {
  const ListingLocationPayload({
    required this.openExploreTab,
    required this.location,
  });

  /// `false` → Rides tab with destination; `true` → Explore tab with search anchor.
  final bool openExploreTab;
  final String location;
}
