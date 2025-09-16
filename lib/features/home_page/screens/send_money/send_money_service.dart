import 'package:cloud_firestore/cloud_firestore.dart';

class SendMoneyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// **Fetch danh sách outlets từ Firestore**
  Future<List<Map<String, String>>> fetchOutlets() async {
    try {
      QuerySnapshot querySnapshot = await _firestore.collection('outlets').get();
      if (querySnapshot.docs.isEmpty) {
        print("❌ No outlets found in Firestore.");
        return [];
      }

      return querySnapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        return {
          'outletId': doc.id,
          'outletName': data['outletName']?.toString() ?? "Unnamed Outlet",
        };
      }).toList();
    } catch (e) {
      print("⚠️ Error fetching outlets: $e");
      return [];
    }
  }

  /// **Fetch danh sách currency codes từ Firestore**
  Future<List<Map<String, String>>> fetchCurrencyCodes() async {
    try {
      QuerySnapshot querySnapshot = await _firestore.collection('currencyCodes').get();
      if (querySnapshot.docs.isEmpty) return [];

      return querySnapshot.docs.map((doc) {
        return {
          'currencyCode': doc['currencyCode'].toString(),
          'description': doc['description'].toString()
        };
      }).toList();
    } catch (e) {
      print("⚠️ Error fetching currency codes: $e");
      return [];
    }
  }

  /// **Fetch outlet rates từ Firestore dựa trên outletId, fromCurrency, toCurrency**
  Future<Map<String, double>> fetchOutletRates(String outletId, String fromCurrency, String toCurrency) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('outletRates')
          .where('outletId', isEqualTo: outletId)
          .where('localCurrency', isEqualTo: fromCurrency)
          .where('foreignCurrency', isEqualTo: toCurrency)
          .get();

      if (querySnapshot.docs.isEmpty) {
        print("❌ No outlet rates found for $fromCurrency ➡️ $toCurrency");
        return {};
      }

      var data = querySnapshot.docs.first.data() as Map<String, dynamic>;

      return {
        'sendRate': double.tryParse(data['sendRate'].toString()) ?? 0.0,
        'buyRate': double.tryParse(data['buyRate'].toString()) ?? 0.0,
        'sellRate': double.tryParse(data['sellRate'].toString()) ?? 0.0,
      };
    } catch (e) {
      print("⚠️ Error fetching outlet rates: $e");
      return {};
    }
  }
}
