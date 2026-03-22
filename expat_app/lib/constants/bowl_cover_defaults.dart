import 'package:expat_app/constants/bowl_ids.dart';
import 'package:expat_app/models/bowl.dart';

/// Default cover images for the three seeded bowls (used when Firestore
/// `imageUrl` is null). These are stable public URLs so you do **not** have to
/// upload to Firebase Storage unless you want custom art.
///
/// To use your own images: set `imageUrl` on each bowl document in Firestore
/// (e.g. a Firebase Storage download URL). That value always wins over these
/// defaults.
///
/// Sources: Wikimedia Commons (Nigeria flag), Unsplash (stock photos).
const Map<String, String> kDefaultBowlCoverImageUrls = {
  kBowlNigeria:
      'https://upload.wikimedia.org/wikipedia/commons/thumb/7/79/Flag_of_Nigeria.svg/480px-Flag_of_Nigeria.svg.png',
  kBowlJobHunting:
      'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?auto=format&w=400&h=400&fit=crop&q=80',
  kBowlExpatLife:
      'https://images.unsplash.com/photo-1596414089193-620558fcd6db?auto=format&w=600&q=80',
};

/// Effective cover URL: Firestore [Bowl.imageUrl] if set, else built-in default for known IDs.
String? resolvedBowlCoverUrl(Bowl bowl) {
  final u = bowl.imageUrl;
  if (u != null && u.trim().isNotEmpty) return u.trim();
  return kDefaultBowlCoverImageUrls[bowl.id];
}
