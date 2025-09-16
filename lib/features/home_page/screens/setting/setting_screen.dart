import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/app/routes.dart';
import 'package:flutter_application_1/shared/services/auth_service.dart';
import 'package:flutter_application_1/shared/services/users_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingForm extends StatefulWidget {
  const SettingForm({super.key});

  @override
  State<SettingForm> createState() => _SettingFormState();
}

class _SettingFormState extends State<SettingForm> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nationalityController = TextEditingController();
  final TextEditingController _identificationNumberController =
      TextEditingController();
  final TextEditingController _passportNumberController =
      TextEditingController();
  final TextEditingController _bankCodeController = TextEditingController();
  final TextEditingController _bankSwiftCodeController =
      TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _bankNumberController = TextEditingController();

  final TextEditingController _addressController = TextEditingController();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  Uint8List? _idFrontPhoto;
  Uint8List? _idRearPhoto;
  Uint8List? _passportPhoto;
  final UserService userService = UserService();
  final ImagePicker _picker = ImagePicker();
  bool isLoading = true;
  bool _showIdentificationField = false;
  bool _showPassportField = false;
  bool _isBankCodeError = false;
  bool _isLoading = false;

  List<Map<String, String>> nationalities = [];
  List<Map<String, String>> filteredNationalities = [];
  List<Map<String, String>> bankCodes = [];
  List<Map<String, String>> filteredBankCode = [];
  final UserService _userService = UserService();
  Timer? _debounce;
  Map<String, String?> _photoUrls = {}; // Cho phép giá trị null

  String appVersion = "1.0.1";

  @override
  void dispose() {
    _userNameController.dispose();
    _lastNameController.dispose();
    _firstNameController.dispose();
    _phoneNumberController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nationalityController.dispose();
    _identificationNumberController.dispose();
    _passportNumberController.dispose();
    _bankCodeController.dispose();
    _bankSwiftCodeController.dispose();
    _bankNameController.dispose();
    _bankNumberController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _loadAppVersion();
    loadBanks();
  }

  void _loadAppVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    appVersion = packageInfo.version;
    setState(() {}); // Cập nhật UI
  }

  void _loadUserData(Map<String, dynamic> userData) {
    print('📝 Dữ liệu người dùng nhận được: $userData');

    setState(() {
      _photoUrls = {
        'idFront': userData['idFrontPhoto'] ?? '',
        'idRear': userData['idRearPhoto'] ?? '',
        'passport': userData['passportPhoto'] ?? '',
      };
    });

    print('📂 URL ảnh sau khi tải dữ liệu: $_photoUrls');
  }

  Future<void> _pickImage(String photoType) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showLoginRequiredDialog();
      return;
    }

    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final Uint8List imageBytes = await pickedFile.readAsBytes();

      setState(() {
        if (photoType == 'idFront') {
          _idFrontPhoto = imageBytes;
        } else if (photoType == 'idRear') {
          _idRearPhoto = imageBytes;
        } else if (photoType == 'passport') {
          _passportPhoto = imageBytes;
        }
      });
    }
  }

  Future<void> deleteImage(String photoType) async {
    try {
      String? imageUrl = _photoUrls[photoType];

      if (imageUrl == null || imageUrl.isEmpty) {
        print('⚠️ Không tìm thấy ảnh để xóa.');
        return;
      }

      // Tạo reference đến file trên Firebase Storage
      Reference ref = FirebaseStorage.instance.refFromURL(imageUrl);

      // Xóa file
      await ref.delete();

      // Cập nhật UI sau khi xóa ảnh
      setState(() {
        _photoUrls[photoType] = ''; // Xóa URL khỏi Map
        if (photoType == 'idFront') _idFrontPhoto = null;
        if (photoType == 'idRear') _idRearPhoto = null;
        if (photoType == 'passport') _passportPhoto = null;
      });

      print('✅ Ảnh đã được xóa thành công: $imageUrl');
    } catch (e) {
      print('❌ Lỗi khi xóa ảnh: $e');
    }
  }

  Future<Uint8List?> downloadImageOptimized(String url) async {
    return compute(_downloadImageWithCache, url);
  }

  Future<Uint8List?> _downloadImageWithCache(String url) async {
    try {
      final file = await DefaultCacheManager().getSingleFile(url);
      return await file.readAsBytes();
    } catch (e) {
      print('❌ Lỗi tải ảnh từ cache: $e');
    }
    return null;
  }

  Future<void> _fetchUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('⚠️ Người dùng chưa đăng nhập. Ẩn ảnh.');
        setState(() {
          _idFrontPhoto = null;
          _idRearPhoto = null;
          _passportPhoto = null;
        });
        return;
      }

      // Gọi song song hai hàm fetch
      final userDataFuture = _userService.fetchUserData();
      final nationalitiesFuture = userService.fetchNationalities();

      final results = await Future.wait([userDataFuture, nationalitiesFuture]);

      final userData = results[0] as Map<String, dynamic>?;
      final fetchedNationalities = results[1] as List<Map<String, dynamic>>?;

      if (userData != null) {
        setState(() {
          _userNameController.text = userData['userName'] ?? '';
          _phoneNumberController.text = userData['phoneNumber'] ?? '';
          _emailController.text = userData['email'] ?? '';
          _firstNameController.text = userData['firstName'] ?? '';
          _lastNameController.text = userData['lastName'] ?? '';
          _addressController.text = userData['address'] ?? '';
          _nationalityController.text = userData['nationality'] ?? '';
          _bankCodeController.text = userData['bankCode'] ?? '';
          _bankSwiftCodeController.text = userData['bankSwiftCode'] ?? '';
          _bankNameController.text = userData['bankName'] ?? '';
          _bankNumberController.text = userData['bankNumber'] ?? '';
          _identificationNumberController.text =
              userData['identificationNumber'] ?? '';
          _passportNumberController.text = userData['passportNumber'] ?? '';
        });

        // Chỉ tải ảnh khi có dữ liệu user
        await _loadImages(userData);
        _loadUserData(userData);
      } else {
        // Nếu không có dữ liệu user, ẩn ảnh
        setState(() {
          _idFrontPhoto = null;
          _idRearPhoto = null;
          _passportPhoto = null;
        });
      }

      // Xử lý danh sách quốc tịch
      if (fetchedNationalities != null && mounted) {
        setState(() {
          nationalities.clear();
          nationalities.addAll(fetchedNationalities.map((nation) => {
                "code": nation["code"] as String? ?? "",
                "name": nation["name"] as String? ?? "",
              }));
          isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Lỗi tải dữ liệu người dùng hoặc quốc tịch: $e');
    }
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

  Future<void> _loadImages(Map<String, dynamic> userData) async {
    try {
      List<Future<Uint8List?>> imageFutures = [
        downloadImageOptimized(userData['idFrontPhoto']),
        downloadImageOptimized(userData['idRearPhoto']),
        downloadImageOptimized(userData['passportPhoto']),
      ];

      List<Uint8List?> images = await Future.wait(imageFutures);

      setState(() {
        _idFrontPhoto = images[0];
        _idRearPhoto = images[1];
        _passportPhoto = images[2];
      });

      print('✅ Tải ảnh hoàn tất!');
    } catch (e) {
      print('❌ Lỗi tải ảnh: $e');
    }
  }

  Future<void> _handleChangePassword({
    required BuildContext context,
    required String oldPassword,
    required String newPassword,
  }) async {
    if (oldPassword.isEmpty || newPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    AuthService authService = AuthService();

    try {
      await authService.changePassword(oldPassword, newPassword);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password updated successfully'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    setState(() => _isLoading = true);
    AuthService authService = AuthService();

    try {
      await authService.logout();
      Navigator.pushReplacementNamed(context, Routes.login);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logout successful'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void filterNationalities(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredNationalities = [];
      } else {
        filteredNationalities = nationalities
            .where((nationality) => nationality['name']!
                .toLowerCase()
                .contains(query.toLowerCase()))
            .toList();
      }
    });
    if (filteredNationalities.isNotEmpty) {
      _showNationalityDialog();
    }
  }

  void _showNationalityDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Nationality'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: filteredNationalities.map((nationality) {
              return ListTile(
                title: Text(nationality['name']!),
                onTap: () {
                  setState(() {
                    _nationalityController.text = nationality['name']!;
                    filteredNationalities = [];
                  });
                  Navigator.of(context).pop(); // Close dialog
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Yêu cầu đăng nhập'),
        content: Text('Bạn cần đăng nhập để thêm hoặc chỉnh sửa ảnh.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Đóng'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Điều hướng đến trang đăng nhập (nếu có)
              Navigator.pushNamed(context, '/login');
            },
            child: Text('Đăng nhập'),
          ),
        ],
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Length of tabs
      child: Scaffold(
        backgroundColor: Colors.white, // Set background color to white
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: AppBar(
            backgroundColor: Colors.white, // AppBar background color to white
            elevation: 0, // Remove shadow from AppBar

            bottom: TabBar(
              tabs: [
                Tab(text: tr('account_details')),
                Tab(text: tr('bank_details')),
              ],
              indicatorColor: Colors.blue, // Indicator color for active tab
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              // TabBarView should take up all available space, use Expanded
              Expanded(
                child: TabBarView(
                  children: [
                    // Wrap content with SingleChildScrollView to handle overflow
                    SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: _buildAccountSettings(), // Your content here
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: _buildBankSetting(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBankSetting() {
    double screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 600;
    final double padding = isSmallScreen ? 12.0 : 24.0;
    final double fontSize = isSmallScreen ? 14.0 : 18.0;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // Chỉ chiếm không gian cần thiết
        children: [
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildTextField(
                tr('bank_name'),
                tr('enter_bank_name'),
                controller: _bankNameController,
              ),
              _buildTextField(
                tr('bank_number'),
                tr('enter_bank_number'),
                controller: _bankNumberController,
              ),
              _buildTextField(
                tr('bank_swift_code'),
                tr('bank_swift_code_hint'),
                controller: _bankSwiftCodeController,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('bank_code'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00274D),
                    ),
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: _bankCodeController,

                    onChanged:
                        _onBankNameChanged, // Dùng debounce để giảm load UI
                    decoration: InputDecoration(
                      fillColor: Colors.white,
                      filled: true,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 6, horizontal: 12),
                    ),
                    style: TextStyle(fontSize: fontSize),
                  ),

                  const SizedBox(height: 10),

                  // Danh sách gợi ý ngân hàng có thể cuộn
                  if (filteredBankCode.isNotEmpty)
                    SizedBox(
                      height: 200, // Giới hạn chiều cao để có thể cuộn
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: ListView.builder(
                          itemCount: filteredBankCode.length,
                          itemBuilder: (context, index) {
                            var bankCode = filteredBankCode[index];
                            return ListTile(
                              title: Text(bankCode['code'] ?? 'No Code'),
                              subtitle: Text(bankCode['name'] ?? 'No Name'),
                              onTap: () {
                                setState(() {
                                  _bankCodeController.text =
                                      bankCode['name'] ?? 'No Name';
                                  filteredBankCode.clear();
                                  _isBankCodeError = false;
                                });
                              },
                            );
                          },
                        ),
                      ),
                    ),

                  ElevatedButton(
                    onPressed: () async {
                      String userId =
                          FirebaseAuth.instance.currentUser?.uid ?? '';

                      if (userId.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("User is not logged in"),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      String userName = _userNameController.text.trim();
                      String firstName = _firstNameController.text.trim();
                      String lastName = _lastNameController.text.trim();
                      String address = _addressController.text.trim();
                      String nationality = _nationalityController.text.trim();
                      String bankCode = _bankCodeController.text.trim();
                      String bankSwiftCode =
                          _bankSwiftCodeController.text.trim();
                      String bankName = _bankNameController.text.trim();
                      String bankNumber = _bankNumberController.text.trim();
                      String identificationNumber =
                          _identificationNumberController.text.trim();
                      String passportNumber =
                          _passportNumberController.text.trim();

                      // Hiển thị popup loading
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                            content: Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
                      );

                      try {
                        await _userService.updateUserInformation(
                          userId: userId,
                          userName: userName,
                          firstName: firstName,
                          lastName: lastName,
                          address: address,
                          nationality: nationality,
                          bankCode: bankCode,
                          bankSwiftCode: bankSwiftCode,
                          bankName: bankName,
                          bankNumber: bankNumber,
                          identificationNumber:
                              identificationNumber, // Thêm số CMND/CCCD
                          passportNumber: passportNumber, // Thêm số hộ chiếu
                          idFrontPhoto: _idFrontPhoto,
                          idRearPhoto: _idRearPhoto,
                          passportPhoto: _passportPhoto,
                        );

                        // Đóng popup loading
                        Navigator.of(context).pop();

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              tr('update_success'),
                              style: TextStyle(color: Colors.white),
                            ),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 3),
                          ),
                        );
                      } catch (e) {
                        // Đóng popup loading nếu có lỗi
                        Navigator.of(context).pop();

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              tr('update_failed'),
                              style: TextStyle(color: Colors.white),
                            ),
                            backgroundColor: Colors.red,
                            duration: Duration(seconds: 3),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4743C9),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 80, vertical: 16),
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: Text(
                      tr('update'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildAccountSettings() {
    return Column(
      // Removed the extra SingleChildScrollView
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _buildTextField(
              tr('user_name'),
              tr('enter_username'),
              controller: _userNameController,
            ),
            _buildTextField(
              tr('last_name'),
              tr('enter_last_name'),
              controller: _lastNameController,
            ),
            _buildTextField(
              tr('first_name'),
              tr('enter_first_name'),
              controller: _firstNameController,
            ),
            _buildConditionalTextField(
              label: tr('identification_number'),
              hint: tr('enter_identification_number'),
              isVisible: _showIdentificationField,
              onCheckboxChanged: (bool? value) {
                setState(() {
                  _showIdentificationField = value ?? false;
                });
              },
              controller: _identificationNumberController,
            ),
            _buildConditionalTextField(
              label: tr('passport_number'),
              hint: tr('enter_passport_number'),
              isVisible: _showPassportField,
              onCheckboxChanged: (bool? value) {
                setState(() {
                  _showPassportField = value ?? false;
                });
              },
              controller: _passportNumberController,
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
            Text(tr('nationality'),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: _nationalityController,
              onChanged: (value) {
                filterNationalities(value); // Gọi hàm lọc
              },
              decoration: InputDecoration(
                hintText: tr('enter_nationality'),
                fillColor: Colors.white,
                filled: true,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              ),
              style: const TextStyle(fontSize: 14),
            ),
            _buildTextField(
              tr('address'),
              tr('enter_address'),
              controller: _addressController,
            ),
            _buildTextField(
              tr('phone_number'),
              tr('enter_phone_number'),
              controller: _phoneNumberController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return tr('phone_number_required');
                }
                if (!RegExp(r'^\d+$').hasMatch(value)) {
                  return tr('phone_number_invalid');
                }
                return null;
              },
            ),
            _buildTextField(
              tr('email'),
              tr('enter_email'),
              controller: _emailController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return tr('email_required');
                }
                final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                if (!emailRegex.hasMatch(value)) {
                  return tr('email_invalid');
                }
                return null;
              },
            ),
          ],
        ),
        const SizedBox(height: 20),

        const SizedBox(height: 10),

        ElevatedButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text(tr('change_password')),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Old Password TextField
                      TextField(
                        controller: _oldPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: tr('old_password'),
                          hintText: tr('enter_old_password'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // New Password TextField
                      TextField(
                        controller: _newPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: tr('new_password'),
                          hintText: tr('enter_new_password'),
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    // Cancel button
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close the dialog
                      },
                      child: Text(tr('cancel')),
                    ),
                    // Submit button
                    ElevatedButton(
                      onPressed: () async {
                        final oldPassword = _oldPasswordController.text.trim();
                        final newPassword = _newPasswordController.text.trim();

                        // Call changePassword function
                        await _handleChangePassword(
                          context: context,
                          oldPassword: oldPassword,
                          newPassword: newPassword,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4743C9),
                      ),
                      child: Text(
                        tr('change_password'),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4743C9),
            padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 16),
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
          child: Text(
            tr('change_password'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () async {
            String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

            if (userId.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("User is not logged in"),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            String userName = _userNameController.text.trim();
            String firstName = _firstNameController.text.trim();
            String lastName = _lastNameController.text.trim();
            String address = _addressController.text.trim();
            String nationality = _nationalityController.text.trim();
            String bankCode = _bankCodeController.text.trim();
            String bankSwiftCode = _bankSwiftCodeController.text.trim();
            String bankName = _bankNameController.text.trim();
            String bankNumber = _bankNumberController.text.trim();
            String identificationNumber =
                _identificationNumberController.text.trim();
            String passportNumber = _passportNumberController.text.trim();

            // Hiển thị popup loading
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return AlertDialog(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  content: Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  ),
                );
              },
            );

            try {
              await _userService.updateUserInformation(
                userId: userId,
                userName: userName,
                firstName: firstName,
                lastName: lastName,
                address: address,
                nationality: nationality,
                bankCode: bankCode,
                bankSwiftCode: bankSwiftCode,
                bankName: bankName,
                bankNumber: bankNumber,
                identificationNumber: identificationNumber, // Thêm số CMND/CCCD
                passportNumber: passportNumber, // Thêm số hộ chiếu
                idFrontPhoto: _idFrontPhoto,
                idRearPhoto: _idRearPhoto,
                passportPhoto: _passportPhoto,
              );

              // Đóng popup loading
              Navigator.of(context).pop();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    tr('update_success'),
                    style: TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 3),
                ),
              );
            } catch (e) {
              // Đóng popup loading nếu có lỗi
              Navigator.of(context).pop();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    tr('update_failed'),
                    style: TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 3),
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4743C9),
            padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 16),
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
          child: Text(
            tr('update'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () {
            _handleLogout();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 16),
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
          child: Text(
            tr('logout'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8), // Khoảng cách giữa nút và text version
        Align(
          alignment: Alignment.centerRight, // 🔹 Căn phải
          child: Text(
            "Version: $appVersion",
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConditionalTextField({
    required String label,
    required String hint,
    required bool isVisible,
    required ValueChanged<bool?> onCheckboxChanged,
    TextEditingController? controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Switch(
              value: isVisible,
              onChanged: (value) {
                onCheckboxChanged(value);
              },
              activeColor: Colors.blueAccent,
            ),
          ],
        ),
        if (isVisible) ...[
          const SizedBox(height: 10),
          TextFormField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              fillColor: Colors.white,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.blueAccent),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: Colors.blueAccent, width: 2),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            ),
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 20),
        ],
      ],
    );
  }

  Widget _buildTextField(
    String label,
    String hint, {
    bool obscureText = false,
    TextEditingController? controller,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: hint,
            fillColor: Colors.white,
            filled: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildPhotoUploader({
    required String title,
    required Uint8List? photoBytes,
    required String photoType,
  }) {
    final user = FirebaseAuth.instance.currentUser;
    final String? imageUrl = _photoUrls[photoType];

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
            if (user != null)
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'Edit') {
                    _pickImage(photoType);
                  } else if (value == 'Remove') {
                    deleteImage(
                        photoType); // Xoá ảnh trên Firebase Storage & UI
                  }
                },
                icon: Icon(
                  photoBytes == null ? Icons.upload_file : Icons.more_vert,
                  color: photoBytes == null ? Colors.blue : Colors.green,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                color: Colors.white,
                elevation: 4,
                itemBuilder: (context) => [
                  if (photoBytes != null)
                    PopupMenuItem(
                      value: 'Edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(tr('edit_photo')),
                        ],
                      ),
                    ),
                  if (photoBytes != null || imageUrl != null)
                    PopupMenuItem(
                      value: 'Remove',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text(tr('remove_photo')),
                        ],
                      ),
                    ),
                  if (photoBytes == null)
                    PopupMenuItem(
                      value: 'Edit',
                      child: Row(
                        children: [
                          Icon(Icons.upload_file, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(tr('upload_photo')),
                        ],
                      ),
                    ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 6),

        // Kích thước linh hoạt cho cả Mobile & PC
        LayoutBuilder(
          builder: (context, constraints) {
            double imageHeight = constraints.maxWidth > 600
                ? 250
                : 180; // PC: 250px, Mobile: 180px
            return ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: user != null
                  ? (photoBytes != null
                      ? Image.memory(
                          photoBytes,
                          width: double.infinity,
                          height: imageHeight,
                          fit: BoxFit.contain, // Thay đổi từ cover → contain
                          errorBuilder: (context, error, stackTrace) {
                            print('⚠️ Lỗi khi tải ảnh từ bộ nhớ: $error');
                            return _buildErrorPlaceholder(
                                photoType, imageHeight);
                          },
                        )
                      : (imageUrl != null
                          ? Image.network(
                              imageUrl,
                              width: double.infinity,
                              height: imageHeight,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return Center(
                                    child: CircularProgressIndicator());
                              },
                              errorBuilder: (context, error, stackTrace) {
                                print('⚠️ Lỗi khi tải ảnh từ mạng: $error');
                                return _buildErrorPlaceholder(
                                    photoType, imageHeight);
                              },
                            )
                          : _buildUploadPlaceholder(photoType, imageHeight)))
                  : _buildUploadPlaceholder(photoType, imageHeight),
            );
          },
        ),
      ],
    );
  }

  Widget _buildErrorPlaceholder(String photoType, double height) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image, color: Colors.red, size: 40),
          const SizedBox(height: 8),
          Text(
            tr('error_loading_photo'),
            style: TextStyle(color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadPlaceholder(String photoType, double height) {
    return GestureDetector(
      onTap: () => _pickImage(photoType),
      child: Container(
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.upload_file, color: Colors.blue, size: 40),
            const SizedBox(height: 8),
            Text(
              tr('upload_photo'),
              style: TextStyle(color: Colors.blue),
            ),
          ],
        ),
      ),
    );
  }

  
}
