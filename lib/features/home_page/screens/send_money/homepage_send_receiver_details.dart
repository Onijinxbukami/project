import 'dart:convert';
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

class HomepageBankAccountDetailsPage extends StatefulWidget {
  const HomepageBankAccountDetailsPage({super.key});

  @override
  _HomepageBankAccountDetailsPageState createState() =>
      _HomepageBankAccountDetailsPageState();
}

class _HomepageBankAccountDetailsPageState
    extends State<HomepageBankAccountDetailsPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController accountNameController = TextEditingController();
  final TextEditingController accountNumberController = TextEditingController();
  final TextEditingController bankCodeController = TextEditingController();
  final TextEditingController bankSwiftCodeController = TextEditingController();

  final UserService userService = UserService();

  bool _isGmailError = false;
  bool _isFullNameError = false;
  bool _isAccountNameError = false;
  bool _isAccountNumberError = false;
  bool _isBankCodeError = false;
  bool _isBankSwiftCodeError = false;

  bool isLoading = true;
  late TabController _tabController;
  final List<Map<String, String>> bankCodes = [];
  List<Map<String, String>> filteredBankCode = [];
  Uint8List? _idFrontPhoto;
  Uint8List? _idRearPhoto;
  Uint8List? _passportPhoto;
  final ImagePicker _picker = ImagePicker();

  final Map<String, String> _photoUrls = {
    'idFront': 'https://via.placeholder.com/300x200',
    'idRear': 'https://via.placeholder.com/300x200',
    'passport': 'https://via.placeholder.com/300x200',
  };

  final ValueNotifier<int> selectedDay = ValueNotifier<int>(1);
  final ValueNotifier<int> selectedMonth = ValueNotifier<int>(1);
  final ValueNotifier<int> selectedYear =
      ValueNotifier<int>(DateTime.now().year);

  @override
  void initState() {
    super.initState();
    _loadSavedInputs(isSaving: false);
    loadBanks();

    _tabController = TabController(length: 4, vsync: this, initialIndex: 1);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  Future<void> loadDOB() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedDOB = prefs.getString('receiveDob');

    if (savedDOB != null) {
      List<String> parts = savedDOB.split('-'); // Tách năm-tháng-ngày
      if (parts.length == 3) {
        setState(() {
          selectedYear.value = int.parse(parts[0]);
          selectedMonth.value = int.parse(parts[1]);
          selectedDay.value = int.parse(parts[2]);
        });

        print(
            "📌Receive Loaded DOB: $savedDOB"); // Debug kiểm tra giá trị khi lấy ra
      }
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

  Future<void> _pickImage(String photoType) async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final Uint8List imageBytes = await pickedFile.readAsBytes();
      final String base64Image = base64Encode(imageBytes);

      String key = 'receiver_$photoType'; // Định danh đúng ảnh của receiver
      print(
          "📸 [Receiver] Đã chọn ảnh $photoType (Key: $key), ${imageBytes.length} bytes");

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, base64Image);

      setState(() {
        if (photoType == 'idFront') _idFrontPhoto = imageBytes;
        if (photoType == 'idRear') _idRearPhoto = imageBytes;
        if (photoType == 'passport') _passportPhoto = imageBytes;
      });

      print("✅ [Receiver] Ảnh đã lưu với key: $key");
    } else {
      print("❌ Không chọn ảnh nào!");
    }
  }

  Future<void> _loadSavedInputs({bool isSaving = true}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (isSaving) {
      await prefs.setString('receiveName', nameController.text);
      await prefs.setString('receiveDob', dobController.text);
      await prefs.setString('receivePhone', phoneController.text);
      await prefs.setString('receiveEmail', emailController.text);

      await prefs.setString('receiveAccountName', accountNameController.text);
      await prefs.setString(
          'receiveAccountNumber', accountNumberController.text);
      await prefs.setString('receiveBankCode', bankCodeController.text);
      await prefs.setString(
          'receiveBankSwiftCode', bankSwiftCodeController.text);

      print("📥 Đã lưu tất cả thông tin theo receive");
    } else {
      nameController.text = prefs.getString('receiveName') ?? '';
      dobController.text = prefs.getString('receiveDob') ?? '';
      phoneController.text = prefs.getString('receivePhone') ?? '';
      emailController.text = prefs.getString('receiveEmail') ?? '';

      accountNameController.text = prefs.getString('receiveAccountName') ?? '';
      accountNumberController.text =
          prefs.getString('receiveAccountNumber') ?? '';
      bankCodeController.text = prefs.getString('receiveBankCode') ?? '';
      bankSwiftCodeController.text =
          prefs.getString('receiveBankSwiftCode') ?? '';

      setState(() {
        _idFrontPhoto = _loadImageFromPrefs(prefs, 'receiver_idFront');
        _idRearPhoto = _loadImageFromPrefs(prefs, 'receiver_idRear');
        _passportPhoto = _loadImageFromPrefs(prefs, 'receiver_passport');
      });

      print("📥 Đã tải tất cả thông tin theo receive");
    }
  }

  Uint8List? _loadImageFromPrefs(SharedPreferences prefs, String photoType) {
    String? base64String = prefs.getString(photoType); // Dùng đúng key
    if (base64String != null && base64String.isNotEmpty) {
      return base64Decode(base64String);
    }
    return null;
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

  void filterdBankCode(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredBankCode = [];
      } else {
        filteredBankCode = bankCodes
            .where((outlet) =>
                (outlet['code'] != null &&
                    outlet['code']!
                        .toLowerCase()
                        .contains(query.toLowerCase())) ||
                (outlet['name'] != null &&
                    outlet['name']!
                        .toLowerCase()
                        .contains(query.toLowerCase())))
            .toList();
      }
    });
  }

  void _validatePhoneNumber(String value) {
    // Kiểm tra nếu đầu vào có ký tự không phải số
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

    await prefs.setString('receiveDob', dob); // Lưu vào SharedPreferences
    dobController.text = dob;

    print("✅ Receive DOB saved: $dob"); // Debug kiểm tra giá trị được lưu
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
                currentStep: 2,
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
                  Tab(
                      text: tr('history'),
                      icon: const Icon(Icons.history)), // Thêm tab mới
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
                tr('recipient_details'),
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
                RichText(
                  text: TextSpan(
                    text: tr('full_name'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00274D),
                    ),
                    children: [
                      TextSpan(
                        text: '*',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: tr('full_name_hint'),
                    labelStyle: const TextStyle(fontSize: 14),
                    hintStyle:
                        const TextStyle(fontSize: 12, color: Colors.grey),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 12.0, horizontal: 16.0),
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
                  style: const TextStyle(fontSize: 14),
                  onTapOutside: (_) {
                    // Khi ấn ra ngoài mà chưa nhập, hiển thị lỗi
                    if (nameController.text.isEmpty) {
                      setState(() {
                        _isFullNameError = true;
                      });
                    }
                  },
                  onChanged: (value) {
                    // Nếu có nhập thì ẩn lỗi
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
              tr('date_of_birth'),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                        selectedYear, // Giữ nguyên nếu CustomDropdown hỗ trợ ValueNotifier<int>
                    items: List.generate(
                        125,
                        (index) =>
                            DateTime.now().year -
                            index), // Tạo danh sách từ năm hiện tại
                    updateDOB: updateDOB,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),

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
                RichText(
                  text: TextSpan(
                    text: tr('email'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00274D),
                    ),
                    children: [
                      TextSpan(
                        text: '*',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    hintText: tr('enter_email'),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 12.0, horizontal: 16.0),
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
                  style: const TextStyle(fontSize: 14),
                  onTapOutside: (_) {
                    // Khi ấn ra ngoài mà chưa nhập, hiển thị lỗi
                    if (emailController.text.isEmpty) {
                      setState(() {
                        _isGmailError = true;
                      });
                    }
                  },
                  onChanged: (value) {
                    // Nếu có nhập thì ẩn lỗi
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

            const SizedBox(height: 20),

            const Divider(color: Colors.black),

            const SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Account Name
                RichText(
                  text: TextSpan(
                    text: tr('account_name'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00274D),
                    ),
                    children: [
                      TextSpan(
                        text: '*',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: accountNameController,
                  decoration: InputDecoration(
                    hintText: tr('account_name_hint'),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 12.0, horizontal: 16.0),
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
                    errorText: _isAccountNameError
                        ? tr('account_name_required')
                        : null,
                  ),
                  style: const TextStyle(fontSize: 14),
                  onTapOutside: (_) {
                    if (accountNameController.text.isEmpty) {
                      setState(() => _isAccountNameError = true);
                    }
                  },
                  onChanged: (value) {
                    if (value.isNotEmpty && _isAccountNameError) {
                      setState(() => _isAccountNameError = false);
                    }
                  },
                ),

                const SizedBox(height: 10),

                // Account Number
                RichText(
                  text: TextSpan(
                    text: tr('account_number'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00274D),
                    ),
                    children: [
                      TextSpan(
                        text: '*',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: accountNumberController,
                  decoration: InputDecoration(
                    hintText: tr('account_number_hint'),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 12.0, horizontal: 16.0),
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
                    errorText: _isAccountNumberError
                        ? tr('account_name_required')
                        : null,
                  ),
                  style: const TextStyle(fontSize: 14),
                  keyboardType: TextInputType.number,
                  onTapOutside: (_) {
                    if (accountNumberController.text.isEmpty) {
                      setState(() => _isAccountNumberError = true);
                    }
                  },
                  onChanged: (value) {
                    if (value.isNotEmpty && _isAccountNumberError) {
                      setState(() => _isAccountNumberError = false);
                    }
                  },
                ),
                const SizedBox(height: 10),

                Text(
                  tr('bank_swift_code'), // Tiêu đề Bank Swift Code
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00274D),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: bankSwiftCodeController,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    labelText: tr('bank_swift_code_hint'),
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
                    errorText: _isBankSwiftCodeError
                        ? tr('bank_swift_code_required')
                        : null,
                  ),
                  style: TextStyle(fontSize: fontSize),
                  onTapOutside: (_) {
                    if (bankSwiftCodeController.text.isEmpty) {
                      setState(() => _isBankSwiftCodeError = true);
                    }
                  },
                  onChanged: (value) {
                    if (value.isNotEmpty && _isBankSwiftCodeError) {
                      setState(() => _isBankSwiftCodeError = false);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Label với dấu * yêu cầu nhập
                RichText(
                  text: TextSpan(
                    text: tr('bank_name'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00274D),
                    ),
                    children: [
                      TextSpan(
                        text: '*',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // TextField với validation
                TextField(
                  controller: bankCodeController,
                  onChanged: (value) {
                    filterdBankCode(value);
                    if (value.isNotEmpty && _isBankCodeError) {
                      setState(() => _isBankCodeError = false);
                    }
                  },
                  decoration: InputDecoration(
                    hintText: tr('enter_bank_name'),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 12.0, horizontal: 16.0),
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
                        _isBankCodeError ? tr('bank_name_required') : null,
                  ),
                  style: const TextStyle(fontSize: 14),
                  onTapOutside: (_) {
                    if (bankCodeController.text.isEmpty) {
                      setState(() => _isBankCodeError = true);
                    }
                  },
                ),

                const SizedBox(height: 20),

                // Danh sách ngân hàng gợi ý
                SingleChildScrollView(
                  child: Column(
                    children: [
                      ListView.builder(
                        shrinkWrap: true,
                        itemCount: filteredBankCode.length,
                        itemBuilder: (context, index) {
                          var bankCode = filteredBankCode[index];
                          return ListTile(
                            title: Text(bankCode['code'] ?? 'No Code'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(bankCode['name'] ?? 'No Name'),
                                const SizedBox(height: 5),
                              ],
                            ),
                            onTap: () {
                              // Khi chọn ngân hàng, cập nhật ô nhập và ẩn danh sách
                              setState(() {
                                bankCodeController.text =
                                    bankCode['name'] ?? 'No Name';
                                filteredBankCode
                                    .clear(); // Ẩn danh sách sau khi chọn
                                _isBankCodeError = false; // Ẩn lỗi nếu có
                              });
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40), // Khoảng cách giữa ListView và nút
            Container(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 30),
                  Center(
                    child: ElevatedButton(
                      onPressed: () async {
                        // Lưu dữ liệu trước khi chuyển trang
                        await _loadSavedInputs(isSaving: true);

                        // Lấy dữ liệu đã lưu
                        SharedPreferences prefs =
                            await SharedPreferences.getInstance();

                        Map<String, String> savedData = {
                          'Họ tên': prefs.getString('receiveName') ?? '',
                          'Ngày sinh': prefs.getString('receiveDob') ?? '',
                          'Số điện thoại':
                              prefs.getString('receivePhone') ?? '',
                          'Email': prefs.getString('receiveEmail') ?? '',
                          'Tên tài khoản':
                              prefs.getString('receiveAccountName') ?? '',
                          'Số tài khoản':
                              prefs.getString('receiveAccountNumber') ?? '',
                          'Mã ngân hàng':
                              prefs.getString('receiveBankCode') ?? '',
                          'Mã Swift':
                              prefs.getString('sendBankSwiftCode') ?? 'Chưa có',
                        };

                        List<String> missingFields = [];
                        savedData.forEach((key, value) {
                          if (value.isEmpty) {
                            missingFields.add(key);
                          }
                          print('Saved Data: $savedData');
                          print('Missing Fields: $missingFields');
                        });

                        // Kiểm tra ảnh đã lưu chưa
                        List<String> photoTypes = [
                          'idFront',
                          'idRear',
                          'passport'
                        ];
                        List<String> missingPhotos = [];

                        for (String type in photoTypes) {
                          if (!prefs.containsKey('receiver_$type')) {
                            missingPhotos.add(type);
                          }
                        }

                        // Nếu thiếu dữ liệu
                        if (missingFields.isNotEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(tr('fill_in_all_info')),
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

                        // Chuyển trang sau 500ms
                        await Future.delayed(Duration(milliseconds: 500));
                        Navigator.pushNamed(context, Routes.addressDetails);
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
                            tr('submit'),
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
