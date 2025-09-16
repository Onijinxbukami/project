import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_application_1/features/home_page/screens/transaction_history/transaction_history.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/app/routes.dart';
import 'package:flutter_application_1/features/home_page/screens/location/location_screen.dart';
import 'package:flutter_application_1/shared/services/outlets_service.dart';
import 'package:flutter_application_1/shared/widgets/progressbar.dart';
import 'package:flutter_application_1/features/home_page/screens/setting/setting_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:circle_flags/circle_flags.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

class HomepageAddressPage extends StatefulWidget {
  const HomepageAddressPage({super.key});

  @override
  _HomepageAddressPageState createState() => _HomepageAddressPageState();
}

class DeviceIdManager {
  static const _storage = FlutterSecureStorage();
  static const _keyDeviceId = "device_id";

  static Future<String> getDeviceId() async {
    String? deviceId = await _storage.read(key: _keyDeviceId);
    if (deviceId == null) {
      deviceId = const Uuid().v4(); // Tạo UUID mới nếu chưa có
      await _storage.write(key: _keyDeviceId, value: deviceId);
    }
    return deviceId;
  }
}

class _HomepageAddressPageState extends State<HomepageAddressPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController locationController = TextEditingController();
  String? currentUserId;

  String fromCurrency = "";
  String toCurrency = "";

  String sendMoneyValue = '0.00';
  String receiveMoneyValue = '0.00';
  String outletName = "Select Outlet";
  double sellRate = 0.0;
  double sendRate = 0.0;

  String sendName = '';
  String sendDob = '';
  String sendPhone = '';
  String sendEmail = '';

  String sendAccountName = '';
  String sendAccountNumber = '';
  String sendBankCode = '';
  String sendBankSwiftCode = '';

  String receiveName = '';
  String receiveDob = '';
  String receivePhone = '';
  String receiveEmail = '';

  String receiveAccountName = '';
  String receiveAccountNumber = '';
  String receiveBankCode = '';
  String receiveBankSwiftCode = '';

  Uint8List? _idFrontPhoto;
  Uint8List? _idRearPhoto;
  Uint8List? _passportPhoto;

  Uint8List? _idFrontPhotoReceiver;
  Uint8List? _idRearPhotoReceiver;
  Uint8List? _passportPhotoReceiver;

  final Map<String, String> _currencyToCountryCode = {
    'USD': 'us',
    'EUR': 'eu',
    'JPY': 'jp',
    'GBP': 'gb',
    'AUD': 'au',
    'CAD': 'ca',
    'CHF': 'ch',
    'CNY': 'cn',
    'SEK': 'se',
    'NZD': 'nz',
    'VND': 'vn',
    'THB': 'th',
    'SGD': 'sg',
    'MXN': 'mx',
    'BRL': 'br',
    'ZAR': 'za',
    'RUB': 'ru',
    'INR': 'in',
    'KRW': 'kr',
    'HKD': 'hk',
    'MYR': 'my',
    'PHP': 'ph',
    'IDR': 'id',
    'TRY': 'tr',
    'PLN': 'pl',
    'HUF': 'hu',
    'CZK': 'cz',
    'DKK': 'dk',
    'NOK': 'no',
    'ILS': 'il',
    'SAR': 'sa',
    'AED': 'ae',
    'EGP': 'eg',
    'ARS': 'ar',
    'CLP': 'cl',
    'COP': 'co',
    'PEN': 'pe',
    'PKR': 'pk',
    'BDT': 'bd',
    'LKR': 'lk',
    'KWD': 'kw',
    'BHD': 'bh',
    'OMR': 'om',
    'QAR': 'qa',
    'JOD': 'jo',
    'XOF': 'bj',
    'XAF': 'cm',
    'XCD': 'ag',
    'XPF': 'pf',
    'MAD': 'ma',
    'DZD': 'dz',
    'TND': 'tn',
    'LBP': 'lb',
    'JMD': 'jm',
    'TTD': 'tt',
    'NGN': 'ng',
    'GHS': 'gh',
    'KES': 'ke',
    'UGX': 'ug',
    'TZS': 'tz',
    'ETB': 'et',
    'ZMW': 'zm',
    'MZN': 'mz',
    'BWP': 'bw',
    'NAD': 'na',
    'SCR': 'sc',
    'MUR': 'mu',
    'BBD': 'bb',
    'BSD': 'bs',
    'FJD': 'fj',
    'SBD': 'sb',
    'PGK': 'pg',
    'TOP': 'to',
    'WST': 'ws',
    'KZT': 'kz',
    'UZS': 'uz',
    'TJS': 'tj',
    'KGS': 'kg',
    'MMK': 'mm',
    'LAK': 'la',
    'KHR': 'kh',
    'MNT': 'mn',
    'NPR': 'np',
    'BND': 'bn',
    'XAU': 'xau',
    'XAG': 'xag',
    'XPT': 'xpt',
    'XPD': 'xpd',
    'HTG': 'ht',
    'LRD': 'lr',
    'BIF': 'bi',
    'IQD': 'iq',
    'MGA': 'mg',
    'LSL': 'ls',
    'AFN': 'af',
    'CVE': 'cv',
    'BGN': 'bg',
    'LYD': 'ly',
    'AWG': 'aw',
    'HRK': 'hr',
    'BZD': 'bz',
    'HNL': 'hn',
    'MVR': 'mv',
    'GYD': 'gy',
    'SVC': 'sv',
    'ISK': 'is',
    'GNF': 'gn',
    'IRR': 'ir',
    'KYD': 'ky',
    'DJF': 'dj',
    'MWK': 'mw',
    'BOB': 'bo',
    'LTL': 'lt',
    'AMD': 'am',
    'CRC': 'cr',
    'KMF': 'km',
    'AOA': 'ao',
    'ALL': 'al',
    'ERN': 'er',
    'EEK': 'ee',
    'GMD': 'gm',
    'GIP': 'gi',
    'CUP': 'cu',
    'BMD': 'bm',
    'FKP': 'fk',
    'CDF': 'cd',
    'LVL': 'lv',
    'MKD': 'mk',
    'GTQ': 'gt',
    'AZN': 'az',
    'DOP': 'do',
    'BYN': 'by',
    'GEL': 'ge',
    'BTN': 'bt',
    'MOP': 'mo',
    'ANG': 'ai',
    'BYR': 'by'
  };
  List<Map<String, String>> _currencyDisplayList = [];
  final OutletsService _outletsService = OutletsService();

  late TabController _tabController;

  @override
  void initState() {
    super.initState();

    fetchCurrencyCodes();
    _loadSavedInputs();

    // Khởi tạo TabController
    _tabController = TabController(length: 4, vsync: this, initialIndex: 1);
    _tabController.addListener(() {
      setState(() {}); // Cập nhật UI khi chuyển tab
    });

    // Lấy userId từ Firebase
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (mounted) {
        setState(() {
          currentUserId = user?.uid;
          print("🔥 User ID: $currentUserId");
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedInputs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    outletName = prefs.getString('selectedOutletName') ?? 'No outlet selected';
    sellRate = double.tryParse(prefs.getString('sellRate') ?? '0.0') ?? 0.0;
    sendRate = double.tryParse(prefs.getString('sendRate') ?? '0.0') ?? 0.0;

    // Sender
    sendName = prefs.getString('sendName') ?? 'Chưa có';
    sendDob = prefs.getString('sendDob') ?? 'Chưa có';
    sendPhone = prefs.getString('sendPhone') ?? 'Chưa có';
    sendEmail = prefs.getString('sendEmail') ?? 'Chưa có';
    sendAccountName = prefs.getString('sendAccountName') ?? 'Chưa có';
    sendAccountNumber = prefs.getString('sendAccountNumber') ?? 'Chưa có';
    sendBankCode = prefs.getString('sendBankCode') ?? 'Chưa có';
    sendBankSwiftCode = prefs.getString('sendBankSwiftCode') ?? 'Chưa có';

    // Receiver
    receiveName = prefs.getString('receiveName') ?? 'Chưa có';
    receiveDob = prefs.getString('receiveDob') ?? 'Chưa có';
    receivePhone = prefs.getString('receivePhone') ?? 'Chưa có';
    receiveEmail = prefs.getString('receiveEmail') ?? 'Chưa có';
    receiveAccountName = prefs.getString('receiveAccountName') ?? 'Chưa có';
    receiveAccountNumber = prefs.getString('receiveAccountNumber') ?? 'Chưa có';
    receiveBankCode = prefs.getString('receiveBankCode') ?? 'Chưa có';
    receiveBankSwiftCode = prefs.getString('receiveBankSwiftCode') ?? 'Chưa có';

    fromCurrency = prefs.getString('fromCurrency') ?? "";
    toCurrency = prefs.getString('toCurrency') ?? "";

    // // Debug logs
    print("📥 Đã tải tất cả thông tin & hình ảnh từ SharedPreferences");
    print("Outlet Name: $outletName");
    print("Sell Rate: $sellRate");
    print("Send Rate: $sendRate");

    print("\n--- Sender Info ---");
    print("Name: $sendName");
    print("DOB: $sendDob");
    print("Phone: $sendPhone");
    print("Email: $sendEmail");
    print("Account Name: $sendAccountName");
    print("Account Number: $sendAccountNumber");
    print("Bank Code: $sendBankCode");
    print("Bank Swift Code: $sendBankSwiftCode");

    print("\n--- Receiver Info ---");
    print("Name: $receiveName");
    print("DOB: $receiveDob");
    print("Phone: $receivePhone");
    print("Email: $receiveEmail");
    print("Account Name: $receiveAccountName");
    print("Account Number: $receiveAccountNumber");
    print("Bank Code: $receiveBankCode");
    print("Bank Swift Code: $receiveBankSwiftCode");

    print("\n--- Currency Info ---");
    print("From Currency: $fromCurrency");
    print("To Currency: $toCurrency");

    setState(() {
      sendMoneyValue = prefs.getString('sendAmount') ?? '0.00';
      receiveMoneyValue = prefs.getString('receiveAmount') ?? '0.00';

      // Tải hình ảnh của sender
      _idFrontPhoto = _loadImageFromPrefs(prefs, 'sender_idFront');
      _idRearPhoto = _loadImageFromPrefs(prefs, 'sender_idRear');
      _passportPhoto = _loadImageFromPrefs(prefs, 'sender_passport');

      // Tải hình ảnh của receiver
      _idFrontPhotoReceiver = _loadImageFromPrefs(prefs, 'receiver_idFront');
      _idRearPhotoReceiver = _loadImageFromPrefs(prefs, 'receiver_idRear');
      _passportPhotoReceiver = _loadImageFromPrefs(prefs, 'receiver_passport');
    });
  }

  Uint8List? _loadImageFromPrefs(SharedPreferences prefs, String key) {
    String? base64String = prefs.getString(key);
    if (base64String != null && base64String.isNotEmpty) {
      return base64Decode(base64String);
    }
    return null;
  }

  Future<void> saveTransaction(BuildContext context) async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final FirebaseStorage _storage = FirebaseStorage.instance;
    final String apiUrl =
        "https://biz4x-remittace-gateway-dcc1ds07.uc.gateway.dev/saveTransaction";

    try {
      print("🔹 Bắt đầu lấy SharedPreferences...");
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      print("✅ SharedPreferences lấy thành công!");

      print("🔹 Đang lấy Device ID...");
      String deviceId = await DeviceIdManager.getDeviceId();
      print("✅ Device ID: $deviceId");

      String? userId = FirebaseAuth.instance.currentUser?.uid;
      print("👤 User ID: ${userId ?? 'Không có'}");

      DocumentReference transactionRef =
          await _firestore.collection("transactions").add({
        "deviceId": deviceId,
        "createdAt": FieldValue.serverTimestamp(),
        "status": "pending",
        if (userId != null) "userId": userId,
      });

      String transactionId = transactionRef.id;
      print("📌 Firestore Transaction ID: $transactionId");

      // 2️⃣ **Tải ảnh của Sender lên Firebase Storage**
      print("📤 Uploading sender's images...");
      String? senderIdFrontUrl = await uploadImageToStorage(
          _idFrontPhoto, "transactions/$transactionId/sender_idFront.jpg");
      String? senderIdRearUrl = await uploadImageToStorage(
          _idRearPhoto, "transactions/$transactionId/sender_idRear.jpg");
      String? senderPassportUrl = await uploadImageToStorage(
          _passportPhoto, "transactions/$transactionId/sender_passport.jpg");

      // 3️⃣ **Tải ảnh của Receiver lên Firebase Storage**
      print("📤 Uploading receiver's images...");
      String? receiverIdFrontUrl = await uploadImageToStorage(
          _idFrontPhotoReceiver,
          "transactions/$transactionId/receiver_idFront.jpg");
      String? receiverIdRearUrl = await uploadImageToStorage(
          _idRearPhotoReceiver,
          "transactions/$transactionId/receiver_idRear.jpg");
      String? receiverPassportUrl = await uploadImageToStorage(
          _passportPhotoReceiver,
          "transactions/$transactionId/receiver_passport.jpg");

      // 4️⃣ **Tạo JSON chứa transaction + link ảnh**
      final Map<String, dynamic> requestBody = {
        "transactionId": transactionId,
        "selectedOutletName":
            prefs.getString('selectedOutletName') ?? 'No outlet selected',
        "sellRate":
            double.tryParse(prefs.getString('sellRate') ?? '0.0') ?? 0.0,
        "sendRate":
            double.tryParse(prefs.getString('sendRate') ?? '0.0') ?? 0.0,
        "sendName": prefs.getString('sendName') ?? 'Chưa có',
        "sendDob": prefs.getString('sendDob') ?? 'Chưa có',
        "sendPhone": prefs.getString('sendPhone') ?? 'Chưa có',
        "sendEmail": prefs.getString('sendEmail') ?? 'Chưa có',
        "sendAccountName": prefs.getString('sendAccountName') ?? 'Chưa có',
        "sendAccountNumber": prefs.getString('sendAccountNumber') ?? 'Chưa có',
        "sendBankCode": prefs.getString('sendBankCode') ?? 'Chưa có',
        "sendBankSwiftCode": prefs.getString('sendBankSwiftCode') ?? 'Chưa có',
        "receiveName": prefs.getString('receiveName') ?? 'Chưa có',
        "receiveDob": prefs.getString('receiveDob') ?? 'Chưa có',
        "receivePhone": prefs.getString('receivePhone') ?? 'Chưa có',
        "receiveEmail": prefs.getString('receiveEmail') ?? 'Chưa có',
        "receiveAccountNumber":
            prefs.getString('receiveAccountNumber') ?? 'Chưa có',
        "receiveAccountName":
            prefs.getString('receiveAccountName') ?? 'Chưa có',
        "receiveBankCode": prefs.getString('receiveBankCode') ?? 'Chưa có',
        "receiveBankSwiftCode":
            prefs.getString('receiveBankSwiftCode') ?? 'Chưa có',
        "fromCurrency": prefs.getString('fromCurrency') ?? "",
        "toCurrency": prefs.getString('toCurrency') ?? "",
        "sendAmount": prefs.getString('sendAmount') ?? '0.00',
        "receiveAmount": prefs.getString('receiveAmount') ?? '0.00',
        "deviceId": deviceId,
        if (userId != null) "userId": userId,
        "senderImages": {
          "idFront": senderIdFrontUrl,
          "idRear": senderIdRearUrl,
          "passport": senderPassportUrl,
        },
        "receiverImages": {
          "idFront": receiverIdFrontUrl,
          "idRear": receiverIdRearUrl,
          "passport": receiverPassportUrl,
        },
      };

      print("🔹 Dữ liệu transaction được tạo:");
      print(jsonEncode(requestBody));

      // 5️⃣ **Gửi dữ liệu đến API**
      print("🔹 Bắt đầu gửi transaction đến API...");
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        print("✅ API Response: ${response.body}");
      } else {
        print("❌ API Error: ${response.statusCode} - ${response.body}");
      }

      // 6️⃣ **Lưu JSON transaction vào Firebase Storage**
      print("🔹 Đang lưu transaction JSON vào Firebase Storage...");

      // Chuyển dữ liệu thành chuỗi JSON và sau đó thành Uint8List
      String jsonString = jsonEncode(requestBody);
      Uint8List jsonBytes = Uint8List.fromList(utf8.encode(jsonString));

      // Lưu JSON vào transactions/{transactionId}/transaction.json
      String jsonFilePath = "transactions/$transactionId/transaction.json";
      print("📂 Đường dẫn lưu JSON: $jsonFilePath");

      Reference ref = _storage.ref().child(jsonFilePath);
      UploadTask uploadTask = ref.putData(
          jsonBytes, SettableMetadata(contentType: "application/json"));
      TaskSnapshot snapshot = await uploadTask;

      // Lấy URL của file JSON
      String jsonDownloadUrl = await snapshot.ref.getDownloadURL();
      print("✅ Transaction JSON saved successfully!");
      print("🌍 JSON Firebase Storage URL: $jsonDownloadUrl");

      // 7️⃣ **Cập nhật Firestore với đường dẫn ảnh & JSON**
      await transactionRef.update({
        "transactionJsonUrl": jsonDownloadUrl,
        "senderImages": {
          "idFront": senderIdFrontUrl,
          "idRear": senderIdRearUrl,
          "passport": senderPassportUrl,
        },
        "receiverImages": {
          "idFront": receiverIdFrontUrl,
          "idRear": receiverIdRearUrl,
          "passport": receiverPassportUrl,
        },
        "status": "completed",
        if (userId != null) "userId": userId,
      });

      print("✅ Firestore transaction updated successfully!");
    } catch (e) {
      print("❌ Lỗi xảy ra: $e");
    }
  }

  Future<String?> uploadImageToStorage(
      Uint8List? imageBytes, String path) async {
    if (imageBytes == null) return null;
    final FirebaseStorage _storage = FirebaseStorage.instance;

    try {
      Reference ref = _storage.ref().child(path);
      UploadTask uploadTask =
          ref.putData(imageBytes, SettableMetadata(contentType: "image/jpeg"));
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("⚠️ Error uploading image: $e");
      return null;
    }
  }

  Future<void> fetchCurrencyCodes() async {
    final currencyList = await _outletsService.fetchCurrencyCodes();
    setState(() {
      _currencyDisplayList = currencyList;
    });
  }

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // Không cho phép tắt popup khi bấm ra ngoài
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text("Processing...", style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
        );
      },
    );
  }

  String _calculateTotalPay() {
    double sendAmount = double.tryParse(sendMoneyValue) ?? 0.0;
    double totalPay = sendAmount + sendRate;
    return totalPay.toStringAsFixed(2); // Format to 2 decimal places
  }

  @override
 Widget build(BuildContext context) {
  double screenWidth = MediaQuery.of(context).size.width;
  final bool isSmallScreen = screenWidth < 600;
  final double padding = isSmallScreen ? 12.0 : 16.0;
  final double fontSize = isSmallScreen ? 14.0 : 18.0;

  bool showProgress = _tabController.index == 1; // Chỉ hiện khi ở tab "Send"

  return DefaultTabController(
    length: 4, // Đổi từ 3 → 4 để thêm tab mới
    initialIndex: 1,
    child: Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Container(
          color: const Color(0xFF6610F2), // Màu nền AppBar
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: _buildHeader()), // Tiêu đề AppBar
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 10), // Giảm khoảng cách phía trên

          // Hiển thị ProgressStepper khi ở tab "Send"
          if (_tabController.index == 1) ...[
            ProgressStepper(
              steps: [
                tr('amount'),
                tr('sender'),
                tr('recipient'),
                tr('review'),
                tr('success'),
              ],
              stepIcons: [
                Icons.attach_money,
                Icons.person,
                Icons.people,
                Icons.checklist,
                Icons.verified
              ],
              currentStep: 3,
              backgroundColor: Colors.grey[300]!,
              progressColor: Colors.blue,
              height: 8,
            ),
            const SizedBox(
                height: 16), // Chỉ thêm khoảng cách khi hiển thị progress
          ],

          // Nội dung chính
          Expanded(
            child: TabBarView(
              controller: _tabController, 
              children: [
                LocationForm(),
                _buildContent(fontSize, padding),
                SettingForm(),
                HistoryForm(), // Thêm form mới vào đây
              ],
            ),
          ),

          // TabBar phía dưới
          Container(
            color: const Color(0xFF5732C6),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey,
              tabs: [
                Tab(text: tr('near_me'), icon: const Icon(Icons.map)),
                Tab(text: tr('send'), icon: const Icon(Icons.send)),
                Tab(text: tr('setting'), icon: const Icon(Icons.settings)),
                Tab(text: tr('history'), icon: const Icon(Icons.history)), // Thêm tab mới
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildHeader() {
    return Container(
      color: const Color(0xFF6610F2),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Language Dropdown với Cupertino Style
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 6,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  showCupertinoModalPopup(
                    context: context,
                    builder: (BuildContext context) {
                      return CupertinoActionSheet(
                        title: Text(tr("select_language")),
                        actions: [
                          CupertinoActionSheetAction(
                            onPressed: () {
                              context.setLocale(const Locale('en'));
                              Navigator.pop(context);
                            },
                            child: const Text("English"),
                          ),
                          CupertinoActionSheetAction(
                            onPressed: () {
                              context.setLocale(const Locale('vi'));
                              Navigator.pop(context);
                            },
                            child: const Text("Tiếng Việt"),
                          ),
                        ],
                        cancelButton: CupertinoActionSheetAction(
                          onPressed: () => Navigator.pop(context),
                          child: Text(tr("cancel")),
                        ),
                      );
                    },
                  );
                },
                child: Row(
                  children: [
                    Text(
                      context.locale.languageCode.toUpperCase(),
                      style: const TextStyle(color: Colors.black, fontSize: 16),
                    ),
                    const Icon(CupertinoIcons.chevron_down, size: 16),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CupertinoActivityIndicator(color: Colors.white);
              }

              if (snapshot.hasData) {
                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(snapshot.data!.uid)
                      .get(),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const CupertinoActivityIndicator(
                          color: Colors.white);
                    }

                    if (userSnapshot.hasData && userSnapshot.data!.exists) {
                      final userData =
                          userSnapshot.data!.data() as Map<String, dynamic>? ??
                              {}; // Safely handle null
                      return Row(
                        children: [
                          const Icon(CupertinoIcons.person_circle_fill,
                              color: Colors.white, size: 28),
                          const SizedBox(width: 8),
                          Text(
                            userData['userName'] ?? 'User',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16),
                            overflow:
                                TextOverflow.ellipsis, // Prevents overflow
                          ),
                        ],
                      );
                    }

                    return const Text('Error',
                        style: TextStyle(color: Colors.white));
                  },
                );
              }

              //return Text(tr('login'), style: const TextStyle(color: Colors.white));
              return GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, Routes.login);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tr('login'),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget midHeader(double fontSize, double padding) {
    double screenWidth = MediaQuery.of(context).size.width;

    final bool isSmallScreen = screenWidth < 600;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        // Thêm SingleChildScrollView để cuộn dọc
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('transaction_details'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF00274D),
              ),
            ),
            const Divider(color: Colors.black),
            const SizedBox(height: 20),
// Outlet Field
            Row(
              children: [
                Text(
                  tr('outlet'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00274D),
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    const SizedBox(width: 6),
                    Text(
                      outletName, // Hiển thị outletName
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20),

// Send Money Field

            Row(
              children: [
                // Sử dụng CircleFlag thay vì Image.network
                CircleFlag(
                  (_currencyToCountryCode[fromCurrency] ?? 'UN').toLowerCase(),
                  size: 24, // Kích thước lá cờ
                ),
                const SizedBox(width: 8),

                // Nhãn tiền tệ (USD, GBP, ...)
                Text(
                  fromCurrency,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),

                const Spacer(),

                // Số tiền gửi (căn phải)
                Text(
                  sendMoneyValue, // ✅ Hiển thị giá trị đã lưu
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

// Receiver Money Field
            Row(
              children: [
                CircleFlag(
                  (_currencyToCountryCode[toCurrency] ?? 'UN').toLowerCase(),
                  size: 24, // Kích thước lá cờ
                ),
                const SizedBox(width: 8),

                // Nhãn tiền tệ
                Text(
                  toCurrency,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),

                const Spacer(),

                // Số tiền nhận (căn phải)
                Text(
                  receiveMoneyValue, // ✅ Hiển thị giá trị đã lưu
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              ],
            ),

            SizedBox(height: isSmallScreen ? 16 : 24),

// Rate Field
            Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start, // Canh trái phần tiêu đề
              children: [
                // Rate
                Row(
                  children: [
                    Text(
                      tr('rate'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00274D),
                      ),
                    ),
                    const Spacer(), // Đẩy 'rateValue' về bên phải
                    Text(
                      sellRate
                          .toStringAsFixed(2), // Thay thế bằng giá trị thực tế
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Fees
                Row(
                  children: [
                    Text(
                      tr('fees'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00274D),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      "${sendRate.toString()} $fromCurrency",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Receive Money
                Row(
                  children: [
                    Text(
                      tr('total_pay'),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00274D),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      "${_calculateTotalPay()} $fromCurrency", // Thêm đơn vị tiền tệ vào sau số tiền
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 40),

            Text(
              tr('user_infor'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF00274D),
              ),
            ),
            const Divider(color: Colors.black),
            const SizedBox(height: 10),
// Full Name Field
            Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start, // Canh trái phần tiêu đề
              children: [
                // Full Name
                Row(
                  children: [
                    Text(
                      tr('full_name'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00274D),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        const SizedBox(width: 6),
                        Text(
                          sendName, // Giá trị từ state hoặc API
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Date of Birth
                Row(
                  children: [
                    Text(
                      tr('date_of_birth'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00274D),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        const SizedBox(width: 6),
                        Text(
                          sendDob, // Giá trị ngày sinh
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Phone Number
                Row(
                  children: [
                    Text(
                      tr('phone_number'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00274D),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        const SizedBox(width: 6),
                        Text(
                          sendPhone, // Giá trị số điện thoại
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Email Address
                Row(
                  children: [
                    Text(
                      tr('email'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00274D),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        const SizedBox(width: 6),
                        Text(
                          sendEmail, // Giá trị email
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

// Account Name
                Row(
                  children: [
                    Text(
                      tr('account_name'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00274D),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        const SizedBox(width: 6),
                        Text(
                          sendAccountName, // Giá trị tên tài khoản
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

// Account Number
                Row(
                  children: [
                    Text(
                      tr('account_number'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00274D),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        const SizedBox(width: 6),
                        Text(
                          sendAccountNumber, // Giá trị số tài khoản
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

// Bank Code
                Row(
                  children: [
                    Text(
                      tr('bank_code'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00274D),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        const SizedBox(width: 6),
                        Text(
                          sendBankCode, // Giá trị mã ngân hàng
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),

// Bank Swift Code
                Row(
                  children: [
                    Text(
                      tr('bank_swift_code'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00274D),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        const SizedBox(width: 6),
                        Text(
                          sendBankSwiftCode, // Giá trị mã ngân hàng
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                if (_idFrontPhoto != null ||
                    _idRearPhoto != null ||
                    _passportPhoto != null) // Kiểm tra có ảnh của sender không
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        tr('sender_uploaded_photos'), // Tiêu đề cho ảnh sender
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00274D),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Ảnh CMND/CCCD mặt trước (Sender)
                      if (_idFrontPhoto != null)
                        _buildImageDisplay(_idFrontPhoto!, tr('id_front_photo')),

                      // Ảnh CMND/CCCD mặt sau (Sender)
                      if (_idRearPhoto != null)
                        _buildImageDisplay(_idRearPhoto!, tr('id_rear_photo')),

                      // Ảnh hộ chiếu (Sender)
                      if (_passportPhoto != null)
                        _buildImageDisplay(_passportPhoto!, tr('passport_photo')),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 20),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tiêu đề
                Text(
                  tr('recipient_details'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF00274D),
                  ),
                ),
                const Divider(color: Colors.black),
                const SizedBox(height: 20),

                // Recipient Name
                Row(
                  children: [
                    Text(
                      tr('full_name'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00274D),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      receiveName, // Giá trị tên người nhận
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Date of Birth
                Row(
                  children: [
                    Text(
                      tr('date_of_birth'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00274D),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      receiveDob, // Giá trị ngày sinh
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Phone Number
                Row(
                  children: [
                    Text(
                      tr('phone_number'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00274D),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      receivePhone, // Giá trị số điện thoại
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Email Address
                Row(
                  children: [
                    Text(
                      tr('email'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00274D),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      receiveEmail, // Giá trị email
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Bank Number
                Row(
                  children: [
                    Text(
                      tr('account_number'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00274D),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      receiveAccountNumber, // Giá trị số tài khoản ngân hàng
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Bank Name
                Row(
                  children: [
                    Text(
                      tr('bank_name'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00274D),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      receiveAccountName, // Giá trị tên ngân hàng
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Bank Code
                Row(
                  children: [
                    Text(
                      tr('bank_code'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00274D),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      receiveBankCode,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Bank Swift Code
                Row(
                  children: [
                    Text(
                      tr('bank_swift_code'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00274D),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      receiveBankSwiftCode,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Ảnh của Receiver nếu có
                if (_idFrontPhotoReceiver != null ||
                    _idRearPhotoReceiver != null ||
                    _passportPhotoReceiver != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        tr('receiver_uploaded_photos'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00274D),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Ảnh CMND/CCCD mặt trước (Receiver)
                      if (_idFrontPhotoReceiver != null)
                        _buildImageDisplay(
                            _idFrontPhotoReceiver!, tr('id_front_photo')),

                      // Ảnh CMND/CCCD mặt sau (Receiver)
                      if (_idRearPhotoReceiver != null)
                        _buildImageDisplay(
                            _idRearPhotoReceiver!, tr('id_rear_photo')),

                      // Ảnh hộ chiếu (Receiver)
                      if (_passportPhotoReceiver != null)
                        _buildImageDisplay(
                            _passportPhotoReceiver!, tr('passport_photo')),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 40),
            // Khoảng cách giữa ListView và nút
            Container(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 30),
                  Center(
                    child: ElevatedButton(
                      onPressed: () async {
                        _showLoadingDialog(context); // Hiển thị popup loading

                        await saveTransaction(context); // Chờ xử lý giao dịch

                        Navigator.pop(context); // Đóng popup loading
                        Navigator.pushNamed(
                            context, Routes.successDetails); // Chuyển trang
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF007AFF),
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth < 600 ? 40 : 80,
                          vertical: screenWidth < 600 ? 12 : 16,
                        ),
                        minimumSize:
                            Size(double.infinity, screenWidth < 600 ? 48 : 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        elevation: 3,
                        shadowColor: Colors.grey.withOpacity(0.3),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.arrow_forward,
                              color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            tr('approve'),
                            style: TextStyle(
                              fontSize: screenWidth < 600 ? 16 : 20,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(double fontSize, double padding) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          midHeader(fontSize, padding),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildImageDisplay(Uint8List imageBytes, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            imageBytes,
            width: double.infinity,
            height: 180, // Đặt kích thước phù hợp
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: double.infinity,
                height: 180,
                color: Colors.grey[300],
                child: Icon(Icons.broken_image, color: Colors.red, size: 40),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
