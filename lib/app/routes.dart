import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/auth/login/login_page.dart';
import 'package:flutter_application_1/features/auth/signUp/signup_page.dart';

import 'package:flutter_application_1/features/home_page/screens/send_money/homepage_send_receiver_details.dart';
import 'package:flutter_application_1/features/home_page/screens/send_money/homepage_send_sender_details.dart';
import 'package:flutter_application_1/features/home_page/screens/send_money/homepage_send_succes.dart';
import 'package:flutter_application_1/features/home_page/screens/send_money/hompage_send_review_details.dart';

import 'package:flutter_application_1/features/home_page/home_page.dart';
import 'package:flutter_application_1/features/auth/foget_password/forget_password_page.dart';


class Routes {
  //auth
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgetpassword = '/forgetpassword';
  //homepage
  static const String homepage = '/homepage';
  static const String bankAccountDetails = '/hompagebankaccountdetails';
  static const String addressDetails = '/hompageaddressdetails';
  static const String userDetails = '/homepageuserdetail';
  static const String successDetails = '/homepagesuccess';







  static Map<String, WidgetBuilder> getRoutes() {
    return {
      //home 
      homepage: (context) => const HomePage(),
      bankAccountDetails: (context) => HomepageBankAccountDetailsPage(),
      addressDetails: (context) => HomepageAddressPage(),
      userDetails: (context) => HomepageUserDetailsPage(),
      successDetails: (context) => HomepageSuccessPage(),
      //auth
      login: (context) => LoginPage(),
      signup: (context) => const SignupPage(),
      forgetpassword: (context) => ForgetPasswordPage(),


      
    };
  }
}
