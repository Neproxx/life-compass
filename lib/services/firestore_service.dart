import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:life/models/prayer.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Method to create a Prayer from a Firestore document
  static Prayer prayerFromDocumentSnapshot(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id; // Necessary
    return Prayer.fromJson(data);
  }

  // Method to create a retrieval query for prayers
  Query getPrayerQuery(String userId, {bool withArchived = false}) {
    Query query = _db.collection('users').doc(userId).collection('prayers');
    if (!withArchived) {
      query = query.where('isArchived', isEqualTo: false);
    }
    return query;
  }

  // Continuously returns a list of prayers from a stream of snapshots
  Stream<List<Prayer>> getPrayersStream(
    String? userId, {
    bool withArchived = false,
  }) {
    if (userId == null) {
      return const Stream.empty();
    }
    return getPrayerQuery(userId, withArchived: withArchived).snapshots().map(
        (snapshot) => snapshot.docs
            .map((doc) => prayerFromDocumentSnapshot(doc))
            .toList());
  }

  // Returns a list of prayers only once
  Future<List<Prayer>> getPrayers(
    String? userId, {
    bool withArchived = false,
  }) async {
    if (userId == null) {
      return const [];
    }
    QuerySnapshot snapshot =
        await getPrayerQuery(userId, withArchived: withArchived).get();
    return snapshot.docs.map((doc) => prayerFromDocumentSnapshot(doc)).toList();
  }

  // Method to get a reference to a specific prayer document.
  // If prayerId is null, a new document reference is returned.
  DocumentReference getDocRef(String userId, [String? prayerId]) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('prayers')
        .doc(prayerId);
  }

  Future<bool> _modifyPrayers(List<Prayer> prayers, String? userId,
      void Function(WriteBatch, DocumentReference, Prayer) operation) async {
    if (userId == null) {
      return false;
    }

    try {
      WriteBatch batch = _db.batch();

      for (var prayer in prayers) {
        var docRef = getDocRef(userId, prayer.id);
        operation(batch, docRef, prayer);
      }

      await batch.commit();
      return true;
    } catch (e) {
      return false;
    }
  }

  /* FUNCTIONS ON MULTIPLE PRAYERS */
  Future<bool> addPrayers(List<Prayer> prayers, String? userId) async {
    return _modifyPrayers(prayers, userId,
        (batch, doc, prayer) => batch.set(doc, prayer.toJson()));
  }

  Future<bool> updatePrayers(List<Prayer> prayers, String? userId) async {
    return _modifyPrayers(prayers, userId,
        (batch, doc, prayer) => batch.update(doc, prayer.toJson()));
  }

  Future<bool> deletePrayers(List<Prayer> prayers, String? userId) async {
    return _modifyPrayers(
        prayers, userId, (batch, doc, prayer) => batch.delete(doc));
  }

  /* FUNCTIONS ON SINGLE PRAYERS */
  // Method to apply a Firestore operation to a prayer document
  // and return a boolean indicating success or failure
  Future<bool> _modifyPrayer(Prayer? prayer, String? userId,
      Future Function(DocumentReference) operation,
      [String? prayerId]) async {
    if (userId == null) {
      return false;
    }
    try {
      await operation(getDocRef(userId, prayerId ?? prayer?.id));
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> addPrayer(Prayer prayer, String? userId) async {
    return _modifyPrayer(prayer, userId, (doc) => doc.set(prayer.toJson()));
  }

  Future<bool> updatePrayer(Prayer prayer, String? userId) async {
    return _modifyPrayer(prayer, userId, (doc) => doc.update(prayer.toJson()));
  }

  Future<bool> deletePrayer(String prayerId, String? userId) async {
    return _modifyPrayer(null, userId, (doc) => doc.delete(), prayerId);
  }
}
