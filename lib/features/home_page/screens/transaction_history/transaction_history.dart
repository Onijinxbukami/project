import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/home_page/screens/transaction_history/transaction_details.dart';
import 'package:flutter_application_1/shared/services/users_service.dart';
import 'package:intl/intl.dart';

class HistoryForm extends StatefulWidget {
  @override
  _HistoryFormState createState() => _HistoryFormState();
}

class _HistoryFormState extends State<HistoryForm> {
  final UserService userService = UserService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> _transactionList = [];
  bool isLoading = false;
  @override
  void initState() {
    super.initState();
    _fetchTransactionsDetails();
  }

  Future<void> _fetchTransactionsDetails() async {
    setState(() => isLoading = true);
    try {
      final user = _auth.currentUser; // Lấy user hiện tại
      if (user == null) {
        print("❌ No user logged in.");
        setState(() => isLoading = false);
        return;
      }
      print("👤 Current User ID: ${user.uid}");

      final transactions =
          await userService.fetchUserTransactions(); // Fetch từ Firestore

      if (mounted) {
        setState(() {
          _transactionList =
              List.from(transactions); // Đảm bảo lưu toàn bộ dữ liệu
          isLoading = false;
        });
      }

      print("✅ Transactions fetched successfully: ${_transactionList.length}");
      print(
          "📊 Full Transactions Data: $_transactionList"); // Log toàn bộ dữ liệu
    } catch (e) {
      print("⚠️ Error fetching transactions: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _transactionList.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: EdgeInsets.all(12),
              itemCount: _transactionList.length,
              itemBuilder: (context, index) {
                final transaction = _transactionList[index];

                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: Colors.blueAccent,
                      child: Icon(Icons.swap_horiz, color: Colors.white),
                    ),
                    title: Text(
                      "${transaction['sendAmount']} ${transaction['fromCurrency']} → ${transaction['receiveAmount']} ${transaction['toCurrency']}",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 6),
                        Text(
                          "Transaction ID: ${transaction['transactionId']}",
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600]),
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.trending_up,
                                size: 18, color: Colors.green),
                            SizedBox(width: 4),
                            Text(
                              "Rate: ${transaction['sellRate'] != null ? double.parse(transaction['sellRate'].toString()).toStringAsFixed(5) : 'N/A'}",
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              transaction['status'] == 'completed'
                                  ? Icons.check_circle
                                  : Icons.hourglass_empty,
                              size: 18,
                              color: transaction['status'] == 'completed'
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                            SizedBox(width: 4),
                            Text("Status: ${transaction['status']}",
                                style: TextStyle(fontSize: 14)),
                          ],
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.calendar_today,
                                size: 18, color: Colors.blueAccent),
                            SizedBox(width: 4),
                            Text(
                              "Created: ${DateFormat('dd MMM yyyy, HH:mm').format(transaction['createdAt'].toDate())}",
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TransactionDetailsScreen(
                              transaction: transaction),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
