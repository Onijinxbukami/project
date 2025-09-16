import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class OutletsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String apiKey = "AIzaSyAlo98WKmqmQT-sSLLdFv97GTmns6tOG_0&";

  Future<List<Map<String, String>>> fetchOutlets() async {
    try {
      QuerySnapshot querySnapshot =
          await _firestore.collection('outlets').get();

      if (querySnapshot.docs.isEmpty) {
        print("❌ No outlets found in Firestore.");
        return [];
      }

      return querySnapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;

        return {
          'outletId': doc.id,
          'outletName': data['outletName']?.toString() ?? "Unnamed Outlet",
          'outletAddress': data['outletAddress']?.toString() ?? "No Address",
          'localCurrencyCode':
              data['localCurrencyCode']?.toString() ?? "No local currency code",
          'countryCode': data['countryCode']?.toString() ?? "No country code",
          'country': data['country']?.toString() ?? "No country",
          'city': data['city']?.toString() ?? "No city",
        };
      }).toList();
    } catch (e) {
      print("⚠️ Error fetching outlets: $e");
      return [];
    }
  }
  Future<List<Map<String, dynamic>>> fetchOutletCurrencies(String outletId) async {
  try {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('outletRates')
        .where('outletId', isEqualTo: outletId)
        .get();

    if (querySnapshot.docs.isEmpty) {
      return [];
    }

    List<Map<String, dynamic>> outletCurrencies = querySnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;

      return {
        'localCurrency': data['localCurrency'] ?? '',
        'foreignCurrency': data['foreignCurrency'] ?? '',
        'buyRate': data['buyRate'] ?? 0.0,
        'sellRate': data['sellRate'] ?? 0.0,
        'sendRate': data['sendRate'] ?? 0.0,
      };
    }).toList();

    return outletCurrencies;
  } catch (e) {
    print("⚠️ Error fetching outlet currencies: $e");
    return [];
  }
}


Future<List<Map<String, String>>> fetchCurrencyCodes() async {
  try {
    QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance.collection('currencyCodes').get();

    if (querySnapshot.docs.isEmpty) {
      return [];
    }

    List<Map<String, String>> currencyList = querySnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;

      return {
        'currencyCode': data['currencyCode']?.toString() ?? 'N/A',
        'description': data['description']?.toString() ?? 'No description'
      };
    }).toList();

    return currencyList;
  } catch (e) {
    print("⚠️ Error fetching currency codes: $e");
    return []; // Return empty list on error
  }
}
Future<List<Map<String, dynamic>>> fetchAllOutletRates(String outletId) async {
    try {
      // Giả sử dữ liệu được lấy từ Firestore
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('outletRates')
          .where('outletId', isEqualTo: outletId)
          .get();

      if (querySnapshot.docs.isEmpty) return [];

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'localCurrency': data['localCurrency'] ?? '',
          'foreignCurrency': data['foreignCurrency'] ?? '',
          'sendRate': data['sendRate'] ?? 0.0,
          'buyRate': data['buyRate'] ?? 0.0,
          'sellRate': data['sellRate'] ?? 0.0,
        };
      }).toList();
    } catch (e) {
      print("⚠️ Error fetching outlet currencies: $e");
      return [];
    }
  }


  Future<Map<String, dynamic>?> fetchOutletRates({
    required String outletId,
    required String fromCurrency,
    required String toCurrency,
  }) async {
    try {
      // Validate inputs
      if (outletId.isEmpty || fromCurrency.isEmpty || toCurrency.isEmpty) {
        print("⚠️ Missing required parameters for fetching outlet rates.");
        return null;
      }

      // Query Firestore with conditions
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('outletRates')
          .where('outletId', isEqualTo: outletId)
          .where('localCurrency', isEqualTo: fromCurrency)
          .where('foreignCurrency', isEqualTo: toCurrency)
          .get();

      if (querySnapshot.docs.isEmpty) {
        print("❌ No outlet rates found for $fromCurrency ➡️ $toCurrency");
        return null; // Return null if no data found
      }

      // Get the first document's data
      var data = querySnapshot.docs.first.data() as Map<String, dynamic>;

      // Return structured data
      return {
        'sendRate': double.tryParse(data['sendRate'].toString()) ?? 0.0,
        'buyRate': double.tryParse(data['buyRate'].toString()) ?? 0.0,
        'sellRate': double.tryParse(data['sellRate'].toString()) ?? 0.0,
        'localCurrency': data['localCurrency'] ?? '',
        'foreignCurrency': data['foreignCurrency'] ?? '',
      };
    } catch (e) {
      print("⚠️ Error fetching outlet rates: $e");
      return null; // Return null on error
    }
  }




  // Future<Map<String, dynamic>?> getGeocode(String address) async {
  //   final String url =
  //       "https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(address)}&key=$apiKey";

  //   try {
  //     final response = await http.get(Uri.parse(url));
  //     if (response.statusCode == 200) {
  //       return json.decode(response.body);
  //     } else {
  //       print("❌ Lỗi API: ${response.statusCode}");
  //       return null;
  //     }
  //   } catch (e) {
  //     print("❌ Lỗi khi gọi Google Geocoding API: $e");
  //     return null;
  //   }
  // }
}
