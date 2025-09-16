import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/app/constants.dart';
import 'package:flutter_application_1/app/routes.dart';
import 'package:flutter_application_1/shared/widgets/facebook_sign_in_button.dart';
import 'package:flutter_application_1/shared/widgets/google_sign_in_button.dart';
import 'package:flutter_application_1/shared/widgets/password_field.dart';
import 'package:flutter_application_1/shared/widgets/email_field.dart';

import 'package:flutter_application_1/features/auth/signUp/signup_service.dart';
import 'package:flutter_application_1/shared/services/auth_service.dart';
import 'package:flutter_application_1/shared/services/facebook_auth_service.dart';
import 'package:flutter_application_1/shared/services/firebase_auth_service.dart';


class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final ValidationService _validationService = ValidationService();
  final AuthService _authService = AuthService();
  final FacebookAuthService _facebookAuthService = FacebookAuthService();
  final FirebaseAuthService _firebaseAuthService = FirebaseAuthService();
  bool _isLoading = false;
  String? _userNameError;
  String? _phoneNumberError;
  bool _isFacebookSDKReady = false;

  Future<void> _handleRegister() async {
    if (!_validateInputs()) return;

    setState(() => _isLoading = true);
    AuthService authService = AuthService();

    try {
      User? user = await authService.registerWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _userNameController.text.trim(),
        _phoneNumberController.text.trim(),
      );

      if (user != null) {
        print('User registered and data saved successfully');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration Successful'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushReplacementNamed(context, Routes.homepage);
      }
    } catch (e) {
      print('Registration error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _validateInputs() {
    if (_userNameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _phoneNumberController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all the information'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    return true;
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      User? user = await _authService.signInWithGoogle();
      if (user != null) {
        await _authService.saveUserData(user);
        Navigator.pushReplacementNamed(context, '/homepage');
      }
    } catch (e) {
      _showSnackBar("Google Sign-In Failed", Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  void initState() {
    super.initState();
    _initFacebookSDK();
  }

  void _handleFacebookSignIn() {
    if (!_isFacebookSDKReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Facebook SDK chưa sẵn sàng"),
            backgroundColor: Colors.red),
      );
      return;
    }

    _facebookAuthService.handleFacebookLogin(
      (accessToken) async {
        try {
          await _firebaseAuthService.signInWithFacebook(accessToken);
          Navigator.pushReplacementNamed(context, Routes.homepage);
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text("Lỗi đăng nhập Firebase: $e"),
                backgroundColor: Colors.red),
          );
        }
      },
      (errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      },
    );
  }

  Future<void> _initFacebookSDK() async {
    bool sdkReady = await _facebookAuthService.isFacebookSDKReady();
    setState(() {
      _isFacebookSDKReady = sdkReady;
    });
    print("SDK ready status: $_isFacebookSDKReady");
  }

  void _validateUserName() {
    final userName = _userNameController.text;
    setState(() {
      _userNameError = _validationService.validateUsername(userName);
    });
  }

  void _validatePhoneNumber() {
    final phoneNumber = _phoneNumberController.text;
    setState(() {
      _phoneNumberError = _validationService.validatePhoneNumber(phoneNumber);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: lightColor,
        appBar: AppBar(
          backgroundColor: const Color(0xFF6610F2), // Màu nền của app bar
          elevation: 0,
          toolbarHeight: 80,
          title: Row(
            children: [
              const Spacer(), // Đẩy các phần tử còn lại về bên phải

              // Nút chọn ngôn ngữ
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
                          style: const TextStyle(
                              color: Colors.black, fontSize: 16),
                        ),
                        const Icon(CupertinoIcons.chevron_down, size: 16),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Nút login
              GestureDetector(
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
              ),
            ],
          ),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;

            return Row(
              children: [
                // Background Image (Responsive for large screens)
                if (screenWidth >=
                    600) // Chỉ hiển thị background image trên các màn hình lớn
                  Expanded(
                    flex: 1,
                    child: Container(
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/images/login-reg-bg.png'),
                          fit: BoxFit
                              .cover, // Chỉnh sửa lại để ảnh bao phủ toàn bộ
                          alignment: Alignment.centerLeft,
                        ),
                      ),
                    ),
                  ),
                // Main content (Sign up form)
                Expanded(
                  flex: 1,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth *
                          0.05, // Điều chỉnh padding theo tỷ lệ màn hình
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        const SizedBox(height: 16),
                        const Center(
                          child: Text(
                            "Sign Up",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4743C9),
                              letterSpacing: 1.5,
                              height: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const SizedBox(height: verticalSpacing),

                        // Username Input
                        const Text("Username", style: labelStyle),
                        const SizedBox(height: inputSpacing),
                        TextField(
                          controller: _userNameController,
                          obscureText: false,
                          decoration: InputDecoration(
                            hintText: "Enter Your Username",
                            errorText: _userNameError,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16), // Bo góc
                              borderSide: BorderSide(color: Colors.grey),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(16), // Bo góc khi focus
                              borderSide:
                                  BorderSide(color: Colors.blue, width: 2),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(16), // Bo góc mặc định
                              borderSide:
                                  BorderSide(color: Colors.grey.shade400),
                            ),
                          ),
                          onChanged: (value) => _validateUserName(),
                        ),

                        const SizedBox(height: verticalSpacing),

                        // Email Input
                        const Text("Email", style: labelStyle),
                        const SizedBox(height: inputSpacing),
                        EmailField(
                          emailController: _emailController,
                          hintText: "Enter Your Email",
                        ),
                        const SizedBox(height: verticalSpacing),

                        // Phone Number Input
                        const Text("Phone Number", style: labelStyle),
                        const SizedBox(height: inputSpacing),
                        TextField(
                          controller: _phoneNumberController,
                          keyboardType:
                              TextInputType.phone, // Định dạng bàn phím số
                          decoration: InputDecoration(
                            hintText: "Enter Your Phone Number",
                            errorText: _phoneNumberError,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16), // Bo góc
                              borderSide: BorderSide(color: Colors.grey),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(16), // Bo góc khi focus
                              borderSide:
                                  BorderSide(color: Colors.blue, width: 2),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(16), // Bo góc mặc định
                              borderSide:
                                  BorderSide(color: Colors.grey.shade400),
                            ),
                          ),
                          onChanged: (value) => _validatePhoneNumber(),
                        ),

                        const SizedBox(height: verticalSpacing),

                        // Password Input
                        const Text("Password", style: labelStyle),
                        const SizedBox(height: inputSpacing),
                        PasswordField(
                          passwordController: _passwordController,
                          hintText: "Enter Your Password",
                        ),

                        // "Don't have an account?" text with login button
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Don't have an account?",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Color.fromARGB(255, 37, 34, 109),
                                  letterSpacing: 1.5,
                                  height: 1.2,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, Routes.login);
                                },
                                child: const Text(
                                  "Login",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF4743C9),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: verticalSpacing),

                        // Sign Up Button
                        Center(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleRegister,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4743C9),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 80,
                                vertical: 16,
                              ),
                              minimumSize: const Size(double.infinity, 56),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            child: const Text(
                              "Sign Up",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 25),

                        // Social Sign-In Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: GoogleSignInButton(
                                onPressed: _handleGoogleSignIn,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: FacebookSignInButton(onPressed: () async {
                                if (!_isFacebookSDKReady) {
                                  print(
                                      "Facebook SDK chưa sẵn sàng, vui lòng thử lại sau.");
                                  return;
                                }
                                _handleFacebookSignIn();
                              }),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ));
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}
