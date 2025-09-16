import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> updateUserInformation({
    required String userId,
    required String userName,
    required String firstName,
    required String lastName,
    required String address,
    required String nationality,
    required String bankCode,
    required String bankSwiftCode,
    required String bankName,
    required String bankNumber,
    required String identificationNumber,
    required String passportNumber,
    Uint8List? idFrontPhoto,
    Uint8List? idRearPhoto,
    Uint8List? passportPhoto,
  }) async {
    try {
      DocumentReference userRef = _firestore.collection('users').doc(userId);

      Future<String?> uploadImage(Uint8List? imageBytes, String path) async {
        if (imageBytes == null) return null;
        Reference ref = _storage.ref().child(path);
        UploadTask uploadTask = ref.putData(imageBytes);
        TaskSnapshot snapshot = await uploadTask;
        return await snapshot.ref.getDownloadURL();
      }

      String? idFrontUrl =
          await uploadImage(idFrontPhoto, 'users/$userId/id_front.jpg');
      String? idRearUrl =
          await uploadImage(idRearPhoto, 'users/$userId/id_rear.jpg');
      String? passportUrl =
          await uploadImage(passportPhoto, 'users/$userId/passport.jpg');

      Map<String, dynamic> updatedData = {
        'userName': userName,
        'firstName': firstName,
        'lastName': lastName,
        'address': address,
        'nationality': nationality,
        'bankCode': bankCode,
        'bankSwiftCode': bankSwiftCode,
        'bankName': bankName,
        'bankNumber': bankNumber,
        'identificationNumber': identificationNumber,
        'passportNumber': passportNumber,
      };

      if (idFrontUrl != null) updatedData['idFrontPhoto'] = idFrontUrl;
      if (idRearUrl != null) updatedData['idRearPhoto'] = idRearUrl;
      if (passportUrl != null) updatedData['passportPhoto'] = passportUrl;

      await userRef.update(updatedData);
      print('User information updated successfully');
    } catch (e) {
      print('Error updating user information: $e');
    }
  }

  Future<Map<String, dynamic>?> fetchUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      return userDoc.exists ? userDoc.data() : null;
    } catch (e) {
      print('Error fetching user data: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> fetchUserTransactions() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print("❌ No user logged in.");
        return [];
      }

      print("🔍 Fetching transactions for user: ${user.uid}");

      final querySnapshot = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: user.uid) // Lọc userId
          .get();

      final transactions = querySnapshot.docs.map((doc) {
        final data = doc.data();
        //print("📌 Raw Transaction Data: $data"); // Log dữ liệu chi tiết từng giao dịch
        return {
          'transactionId': doc.id,
          'sendAmount': data['amount']
              ?['sendAmount'], 
          'receiveAmount': data['amount']
              ?['receiveAmount'], 
          'fromCurrency': data['currency']?['fromCurrency'],
          'toCurrency': data['currency']?['toCurrency'],
          'sellRate': data['sellRate'],
          'status': data['status'],
          'createdAt': data['createdAt'],
          ...data,
        };
      }).toList();

      print("✅ Successfully fetched ${transactions.length} transactions");
      print(
          "📊 Transactions Data: $transactions"); // Log danh sách giao dịch đã format

      return transactions;
    } catch (e) {
      print('❌ Error fetching transactions: $e');
      return [];
    }
  }




  Future<List<Map<String, dynamic>>?> fetchBanks() async {
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final CollectionReference banksCollection = firestore.collection("banks");

      QuerySnapshot querySnapshot = await banksCollection.get();

      if (querySnapshot.docs.isEmpty) {
        print("No banks found in Firestore.");
        return null;
      }

      return querySnapshot.docs
          .map((doc) => {"code": doc.id, "name": doc["name"]})
          .toList();
    } catch (e) {
      print("Error fetching banks: $e");
      return null;
    }
  }

  Future<List<Map<String, dynamic>>?> fetchNationalities() async {
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final CollectionReference banksCollection =
          firestore.collection("nationalities");

      QuerySnapshot querySnapshot = await banksCollection.get();

      if (querySnapshot.docs.isEmpty) {
        print("No nationalities found in Firestore.");
        return null;
      }

      return querySnapshot.docs
          .map((doc) => {"code": doc.id, "name": doc["name"]})
          .toList();
    } catch (e) {
      print("Error fetching nationalities: $e");
      return null;
    }
  }

  Future<Uint8List?> downloadImage(String? imageUrl) async {
    if (imageUrl == null) return null;
    try {
      final ref = _storage.refFromURL(imageUrl);
      return await ref.getData();
    } catch (e) {
      print('Error loading image: $e');
      return null;
    }
  }
}
