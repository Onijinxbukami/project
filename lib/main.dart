import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_application_1/app/routes.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_application_1/features/auth/login/login_page.dart';
import 'firebase_options.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Khởi tạo EasyLocalization
  await EasyLocalization.ensureInitialized();
if (kIsWeb) {
  GoogleMapsFlutterPlatform.instance = GoogleMapsFlutterPlatform.instance;
}

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('vi')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter App',
      initialRoute: Routes.signup, // Trang mặc định là Login
      routes: Routes.getRoutes(), // 🔹 Sử dụng getRoutes() thay vì getRoute()
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
    );
  }

  
}

class CounterPage extends StatefulWidget {
  const CounterPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _CounterPageState createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Counter Test')),
      body: Center(
        child: Text('$_counter', style: TextStyle(fontSize: 24)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        child: Icon(Icons.add),
      ),
    );
  }
}
