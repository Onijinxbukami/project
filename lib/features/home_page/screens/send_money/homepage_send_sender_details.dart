import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/app/routes.dart';
import 'package:flutter_application_1/features/home_page/screens/location/location_screen.dart';
import 'package:flutter_application_1/features/home_page/screens/transaction_history/transaction_history.dart';
import 'package:flutter_application_1/shared/services/users_service.dart';
import 'package:flutter_application_1/shared/widgets/dobDropdown.dart';
import 'package:flutter_application_1/shared/widgets/progressbar.dart';
import 'package:flutter_application_1/features/home_page/screens/setting/setting_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';

class HomepageUserDetailsPage extends StatefulWidget {
  const HomepageUserDetailsPage({super.key});

  @override
  _HomepageUserDetailsPageState createState() =>
      _HomepageUserDetailsPageState();
}

class _HomepageUserDetailsPageState extends State<HomepageUserDetailsPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  bool isLoading = true;

  final TextEditingController accountNameController = TextEditingController();
  final TextEditingController accountNumberController = TextEditingController();
  final TextEditingController bankCodeController = TextEditingController();
  final TextEditingController bankSwiftCodeController = TextEditingController();

  bool _isGmailError = false;
  bool _isFullNameError = false;
  bool _isAccountNameError = false;
  bool _isAccountNumberError = false;
  bool _isBankCodeError = false;
  bool _isBankSwiftCodeError = false;

  final UserService userService = UserService();

  List<Map<String, String>> bankCodes = [];
  Timer? _debounce;
  List<Map<String, String>> filteredBankCode = [];
  Uint8List? _idFrontPhoto;
  Uint8List? _idRearPhoto;
  Uint8List? _passportPhoto;
  final ImagePicker _picker = ImagePicker();
  late TabController _tabController;
  final Map<String, String> _photoUrls = {
    'idFront': 'https://via.placeholder.com/300x200',
    'idRear': 'https://via.placeholder.com/300x200',
    'passport': 'https://via.placeholder.com/300x200',
  };

  final ValueNotifier<int> selectedDay = ValueNotifier<int>(1);
  final ValueNotifier<int> selectedMonth = ValueNotifier<int>(1);
  final ValueNotifier<int> selectedYear = ValueNotifier<int>(2024);
  @override
  void initState() {
    super.initState();
    _loadSavedInputs(isSaving: false);
    loadBanks();
    loadDOB();

    _tabController = TabController(length: 4, vsync: this, initialIndex: 1);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  Future<void> loadBanks() async {
    final fetchedBanks = await userService.fetchBanks();
    if (fetchedBanks != null && mounted) {
      setState(() {
        bankCodes.clear();
        bankCodes.addAll(fetchedBanks.map((bank) => {
              "code": bank["code"] as String,
              "name": bank["name"] as String,
            }));
        isLoading = false;
      });
    }
  }

  Future<void> _loadSavedInputs({bool isSaving = true}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (isSaving) {
      // Lưu dữ liệu văn bản
      await prefs.setString('sendName', nameController.text);
      await prefs.setString('sendDob', dobController.text);
      await prefs.setString('sendPhone', phoneController.text);
      await prefs.setString('sendEmail', emailController.text);

      // await prefs.setString('sendAccountName', accountNameController.text);
      // await prefs.setString('sendAccountNumber', accountNumberController.text);
      // await prefs.setString('sendBankCode', bankCodeController.text);
      // await prefs.setString('sendBankSwiftCode', bankSwiftCodeController.text);

      print("📥 Đã lưu tất cả thông tin văn bản");
    } else {
      // Tải dữ liệu văn bản
      nameController.text = prefs.getString('sendName') ?? '';
      dobController.text = prefs.getString('sendDob') ?? '';
      phoneController.text = prefs.getString('sendPhone') ?? '';
      emailController.text = prefs.getString('sendEmail') ?? '';
      // accountNameController.text = prefs.getString('sendAccountName') ?? '';
      // accountNumberController.text = prefs.getString('sendAccountNumber') ?? '';
      // bankCodeController.text = prefs.getString('sendBankCode') ?? '';
      // bankSwiftCodeController.text = prefs.getString('sendBankSwiftCode') ?? '';

      setState(() {
        _idFrontPhoto = _loadImageFromPrefs(prefs, 'idFront');
        _idRearPhoto = _loadImageFromPrefs(prefs, 'idRear');
        _passportPhoto = _loadImageFromPrefs(prefs, 'passport');
      });

      print("📥 Đã tải ảnh của Sender từ SharedPreferences");
    }
  }

  Uint8List? _loadImageFromPrefs(SharedPreferences prefs, String photoType) {
    String? base64String =
        prefs.getString('sender_$photoType'); // Đảm bảo đúng key
    if (base64String != null && base64String.isNotEmpty) {
      return base64Decode(base64String); // Giải mã base64 về Uint8List
    }
    return null;
  }

  Future<void> _pickImage(String photoType) async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final Uint8List imageBytes = await pickedFile.readAsBytes();
      final String base64Image = base64Encode(imageBytes);

      String key = 'sender_$photoType'; // Định danh đúng ảnh của sender
      print(
          "📸 [Sender] Đã chọn ảnh $photoType (Key: $key), ${imageBytes.length} bytes");

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, base64Image);

      setState(() {
        if (photoType == 'idFront') _idFrontPhoto = imageBytes;
        if (photoType == 'idRear') _idRearPhoto = imageBytes;
        if (photoType == 'passport') _passportPhoto = imageBytes;
      });

      print("✅ [Sender] Ảnh đã lưu với key: $key");
    } else {
      print("❌ Không chọn ảnh nào!");
    }
  }

  Future<void> _removeImage(String photoType) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('sender_$photoType'); // Xóa ảnh

    setState(() {
      if (photoType == 'idFront') _idFrontPhoto = null;
      if (photoType == 'idRear') _idRearPhoto = null;
      if (photoType == 'passport') _passportPhoto = null;
    });

    debugPrint("❌ Đã xóa ảnh: sender_$photoType");
  }

  Future<void> loadDOB() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedDOB = prefs.getString('sendDob');

    if (savedDOB != null) {
      List<String> parts = savedDOB.split('-'); 
      if (parts.length == 3) {
        setState(() {
          selectedYear.value = int.parse(parts[0]);
          selectedMonth.value = int.parse(parts[1]);
          selectedDay.value = int.parse(parts[2]);
        });

        print("📌 Send Loaded DOB: $savedDOB"); 
      }
    }
  }

  void _onBankNameChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        List<Map<String, String>> newFilteredBankCode = bankCodes
            .where((outlet) =>
                (outlet['code'] != null &&
                    outlet['code']!
                        .toLowerCase()
                        .contains(value.toLowerCase())) ||
                (outlet['name'] != null &&
                    outlet['name']!
                        .toLowerCase()
                        .contains(value.toLowerCase())))
            .toList()
            .cast<Map<String, String>>();

        setState(() {
          filteredBankCode = newFilteredBankCode;
          _isBankCodeError = value.isEmpty;
        });
      }
    });
  }

  void filterdBankCode(String query) {
    List<dynamic> filterdBankCode(String query) {
      if (query.isEmpty) {
        return [];
      }
      return bankCodes
          .where((outlet) =>
              (outlet['code'] != null &&
                  outlet['code']!
                      .toLowerCase()
                      .contains(query.toLowerCase())) ||
              (outlet['name'] != null &&
                  outlet['name']!.toLowerCase().contains(query.toLowerCase())))
          .toList();
    }
  }

  void _validatePhoneNumber(String value) {
    if (value.isNotEmpty && !RegExp(r'^[0-9]+$').hasMatch(value)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('phone_number_invalid'))),
      );
    }
  }

  void updateDOB() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String dob =
        "${selectedYear.value}-${selectedMonth.value.toString().padLeft(2, '0')}-${selectedDay.value.toString().padLeft(2, '0')}";

    await prefs.setString('sendDob', dob); // Lưu vào SharedPreferences
    dobController.text = dob;

    print("✅ Send DOB saved: $dob"); // Debug kiểm tra giá trị được lưu
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
              currentStep: 1,
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
                            userData['userName'] ??
                                'User', // Default value if userName is null
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
    final double padding = isSmallScreen ? 12.0 : 24.0;
    final double fontSize = isSmallScreen ? 14.0 : 18.0;
    return Padding(
      padding: EdgeInsets.all(padding),
      child: SingleChildScrollView(
        // Thêm SingleChildScrollView để cuộn dọc
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                tr('user_infor'),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00274D),
                ),
              ),
            ),
            const Divider(color: Colors.black),

            const SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('full_name'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00274D),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: tr('full_name_hint'),
                    labelStyle: TextStyle(fontSize: fontSize),
                    hintStyle:
                        TextStyle(fontSize: fontSize * 0.9, color: Colors.grey),
                    contentPadding: EdgeInsets.symmetric(
                        vertical: padding, horizontal: padding),
                    enabledBorder: OutlineInputBorder(
                      borderSide:
                          const BorderSide(color: Colors.grey, width: 1.5),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          const BorderSide(color: Colors.blue, width: 2.0),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderSide:
                          const BorderSide(color: Colors.red, width: 1.5),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderSide:
                          const BorderSide(color: Colors.red, width: 2.0),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    errorText:
                        _isFullNameError ? tr('full_name_required') : null,
                  ),
                  style: TextStyle(fontSize: fontSize),
                  onTapOutside: (_) {
                    if (nameController.text.isEmpty) {
                      setState(() {
                        _isFullNameError = true;
                      });
                    }
                  },
                  onChanged: (value) {
                    if (value.isNotEmpty && _isFullNameError) {
                      setState(() {
                        _isFullNameError = false;
                      });
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 10),

            Text(
              'Date of Birth',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00274D),
              ),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: CustomDropdown(
                    selectedValue:
                        selectedDay, // ✅ Truyền cả ValueNotifier<int>
                    items: List.generate(31, (index) => index + 1),
                    updateDOB: updateDOB,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: CustomDropdown(
                    selectedValue:
                        selectedMonth, // ✅ Truyền cả ValueNotifier<int>
                    items: List.generate(12, (index) => index + 1),
                    updateDOB: updateDOB,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: CustomDropdown(
                    selectedValue:
                        selectedYear, // ✅ Truyền cả ValueNotifier<int>
                    items: List.generate(125, (index) => 2024 - index),
                    updateDOB: updateDOB,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),

            const SizedBox(height: 20),

            Text(
              tr('phone_number'),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00274D),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              onChanged: (value) {
                _validatePhoneNumber(
                    value); // Truyền trực tiếp giá trị của input
              },
              decoration: InputDecoration(
                labelText: tr('enter_phone_number'),
                labelStyle: TextStyle(fontSize: fontSize),
                hintStyle:
                    TextStyle(fontSize: fontSize * 0.9, color: Colors.grey),
                contentPadding: EdgeInsets.symmetric(
                    vertical: padding, horizontal: padding),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.grey, width: 1.5),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.blue, width: 2.0),
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              style: TextStyle(fontSize: fontSize),
            ),
            const SizedBox(height: 10),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('email'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00274D),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: tr('enter_email'),
                    labelStyle: TextStyle(fontSize: fontSize),
                    hintStyle:
                        TextStyle(fontSize: fontSize * 0.9, color: Colors.grey),
                    contentPadding: EdgeInsets.symmetric(
                        vertical: padding, horizontal: padding),
                    enabledBorder: OutlineInputBorder(
                      borderSide:
                          const BorderSide(color: Colors.grey, width: 1.5),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          const BorderSide(color: Colors.blue, width: 2.0),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderSide:
                          const BorderSide(color: Colors.red, width: 1.5),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderSide:
                          const BorderSide(color: Colors.red, width: 2.0),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    errorText: _isGmailError ? tr('email_required') : null,
                  ),
                  style: TextStyle(fontSize: fontSize),
                  onTapOutside: (_) {
                    if (emailController.text.isEmpty) {
                      setState(() {
                        _isGmailError = true;
                      });
                    }
                  },
                  onChanged: (value) {
                    if (value.isNotEmpty && _isGmailError) {
                      setState(() {
                        _isGmailError = false;
                      });
                    }
                  },
                ),
              ],
            ),

            _buildPhotoUploader(
              title: tr('id_front_photo'),
              photoBytes: _idFrontPhoto,
              photoType: 'idFront',
            ),
            _buildPhotoUploader(
              title: tr('id_rear_photo'),
              photoBytes: _idRearPhoto,
              photoType: 'idRear',
            ),
            _buildPhotoUploader(
              title: tr('passport_photo'),
              photoBytes: _passportPhoto,
              photoType: 'passport',
            ),
            const SizedBox(height: 20), // Khoảng cách giữa ListView và nút

            const Divider(color: Colors.black),
            

            SizedBox(height: isSmallScreen ? 16 : 24),

            Container(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 30),
                  Center(
                    child: ElevatedButton(
                      onPressed: () async {
                        // Lưu thông tin trước khi chuyển trang
                        await _loadSavedInputs(isSaving: true);

                        // Lấy dữ liệu đã lưu từ SharedPreferences
                        SharedPreferences prefs =
                            await SharedPreferences.getInstance();

                        Map<String, String> savedData = {
                          'Họ tên': prefs.getString('sendName') ?? 'Chưa có',
                          'Ngày sinh': prefs.getString('sendDob') ?? 'Chưa có',
                          'Số điện thoại':
                              prefs.getString('sendPhone') ?? 'Chưa có',
                          'Email': prefs.getString('sendEmail') ?? 'Chưa có',
                          // 'Tên tài khoản':
                          //     prefs.getString('sendAccountName') ?? 'Chưa có',
                          // 'Số tài khoản':
                          //     prefs.getString('sendAccountNumber') ?? 'Chưa có',
                          // 'Mã ngân hàng':
                          //     prefs.getString('sendBankCode') ?? 'Chưa có',
                          // 'Mã Swift':
                          //     prefs.getString('sendBankSwiftCode') ?? 'Chưa có',
                        };

                        // Kiểm tra nếu thiếu dữ liệu quan trọng
                        if (savedData['Họ tên'] == 'Chưa có' ||
                            savedData['Số điện thoại'] == 'Chưa có' ||
                            savedData['Email'] == 'Chưa có') {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                tr('fill_in_all_info'),
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(tr('info_saved')),
                            backgroundColor: Colors.green,
                          ),
                        );

                        // Chuyển trang sau 500ms để người dùng thấy thông báo
                        await Future.delayed(Duration(milliseconds: 500));
                        Navigator.pushNamed(context, Routes.bankAccountDetails);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF007AFF),
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth < 600 ? 40 : 80,
                          vertical: screenWidth < 600 ? 12 : 16,
                        ),
                        minimumSize: Size(
                          double.infinity,
                          screenWidth < 600 ? 48 : 56,
                        ),
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
                            tr('continue'),
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

  Widget _buildPhotoUploader({
    required String title,
    required Uint8List? photoBytes,
    required String photoType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            if (photoBytes == null)
              IconButton(
                icon: Icon(Icons.upload_file, color: Colors.blue),
                onPressed: () => _pickImage(photoType),
                tooltip: "Tải ảnh lên",
              )
            else
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'Edit') _pickImage(photoType);
                  if (value == 'Remove') _removeImage(photoType);
                },
                icon: Icon(Icons.more_vert, color: Colors.green),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'Edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, color: Colors.blue),
                        SizedBox(width: 8),
                        Text("Chỉnh sửa ảnh"),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'Remove',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text("Xóa ảnh"),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 6),
        if (photoBytes != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              photoBytes,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
            ),
          ),
      ],
    );
  }
}
