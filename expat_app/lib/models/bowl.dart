import 'package:cloud_firestore/cloud_firestore.dart';

class Bowl {
  Bowl({
    required this.id,
    required this.name,
    required this.description,
    this.type = 'topic',
    this.imageUrl,
    this.countryCode,
    this.createdAt,
  });

  final String id;
  final String name;
  final String description;
  final String type;
  final String? imageUrl;
  final String? countryCode;
  final DateTime? createdAt;

  factory Bowl.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) throw StateError('Bowl ${doc.id} has no data');
    return Bowl(
      id: doc.id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      type: data['type'] as String? ?? 'topic',
      imageUrl: data['imageUrl'] as String?,
      countryCode: data['countryCode'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'description': description,
        'type': type,
        'imageUrl': imageUrl,
        'countryCode': countryCode,
      };

  Map<String, dynamic> toFirestoreCreate() {
    final map = toFirestore();
    map['createdAt'] = FieldValue.serverTimestamp();
    return map;
  }
}
