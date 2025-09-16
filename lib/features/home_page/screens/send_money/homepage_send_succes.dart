import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_application_1/app/routes.dart';
import 'package:flutter_application_1/features/home_page/screens/location/location_screen.dart';
import 'package:flutter_application_1/features/home_page/screens/setting/setting_screen.dart';

class HomepageSuccessPage extends StatelessWidget {
  const HomepageSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: 1,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color(0xFF6610F2),
          title: const Text('Transaction Success',
              style:
                  TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
        ),
        body: Column(
          children: [
            const SizedBox(height: 20),
            Expanded(
              child: TabBarView(
                children: [
                  LocationForm(),
                  _buildSuccessContent(context),
                  SettingForm(),
                ],
              ),
            ),
            Container(
              color: const Color(0xFF5732C6),
              child: TabBar(
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey,
                tabs: [
                  Tab(text: tr('near_me'), icon: const Icon(Icons.map)),
                  Tab(text: tr('send'), icon: const Icon(Icons.send)),
                  Tab(text: tr('setting'), icon: const Icon(Icons.settings)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(),
          Icon(
            CupertinoIcons.checkmark_circle_fill,
            size: 80,
            color: CupertinoColors.activeGreen,
          ),
          const SizedBox(height: 20),
          Text(
            tr('transaction_approved'),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: CupertinoColors.label,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            tr('transaction_success'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: CupertinoColors.secondaryLabel,
            ),
          ),

          const SizedBox(height: 10),

          // Displaying the formatted current time
          Text(
            '${tr('received_at')} ${DateTime.now().toLocal().toString().substring(0, 19)}',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '${tr('ticket_id')} a18929830203',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 30),
          CupertinoButton.filled(
            onPressed: () {
              Navigator.pushNamed(context, Routes.homepage);
            },
            child: Text(tr('done')),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
