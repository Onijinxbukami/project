import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/app/constants.dart';
import 'package:flutter_application_1/shared/widgets/facebook_sign_in_button.dart';
import 'package:flutter_application_1/shared/widgets/google_sign_in_button.dart';
import 'package:flutter_application_1/app/routes.dart';
import 'package:flutter_application_1/shared/widgets/password_field.dart';
import 'package:flutter_application_1/shared/widgets/email_field.dart';
import 'package:flutter_application_1/shared/services/auth_service.dart';
import 'package:flutter_application_1/shared/services/facebook_auth_service.dart';
import 'package:flutter_application_1/shared/services/firebase_auth_service.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  final FacebookAuthService _facebookAuthService = FacebookAuthService();
  final FirebaseAuthService _firebaseAuthService = FirebaseAuthService();
  bool _isLoading = false;
  bool _isFacebookSDKReady = false;

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar('Please fill in all the information', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      User? user = await _authService.signInWithEmail(
        _emailController.text,
        _passwordController.text,
      );

      if (user != null) {
        await _authService.saveUserData(user);
        _showSnackBar('Login successful', Colors.green);
        Navigator.pushReplacementNamed(context, '/homepage');
      }
    } catch (e) {
      _showSnackBar('Login failed: ${e.toString()}', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
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
                  Navigator.pushNamed(context, Routes.signup);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tr('sign_up'),
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
                // Background Image
                if (screenWidth >=
                    600) // Chỉ hiển thị background image trên các màn hình lớn
                  Expanded(
                    flex: 1,
                    child: Container(
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/images/login-reg-bg.png'),
                          fit: BoxFit.cover,
                          alignment: Alignment.centerLeft,
                        ),
                      ),
                    ),
                  ),
                // Form Content
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
                            "LOGIN",
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

                        // Email Input
                        const Text("Email", style: labelStyle),
                        const SizedBox(height: 8),
                        EmailField(
                          emailController: _emailController,
                          hintText: "Enter Your Email",
                        ),
                        const SizedBox(height: 16),

                        // Password Input
                        const Text("Password", style: labelStyle),
                        const SizedBox(height: 8),
                        PasswordField(
                          passwordController: _passwordController,
                          hintText: "Enter Your Password",
                        ),
                        const SizedBox(height: 16),

                        // Login Button
                        Center(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
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
                              "LOGIN",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Forgot your password?",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Color.fromARGB(255, 37, 34, 109),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(
                                      context, Routes.forgetpassword);
                                },
                                child: const Text(
                                  "Click here",
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

                        // Sign Up Section
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Don't have an account?",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Color.fromARGB(255, 37, 34, 109),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, Routes.signup);
                                },
                                child: const Text(
                                  "Sign up",
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

                        // Social Media Sign-In Buttons
                        const SizedBox(height: 25),
                        Row(
                          children: [
                            Expanded(
                              child: GoogleSignInButton(
                                onPressed:
                                    _handleGoogleSignIn, // Chỉ tham chiếu hàm
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
                        const SizedBox(height: 25),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ));
  }
}
