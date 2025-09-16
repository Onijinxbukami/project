import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> transaction;

  TransactionDetailsScreen({required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Transaction Details"),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCard("Transaction Info", [
              _buildListTile(Icons.confirmation_number, "Transaction ID",
                  transaction['transactionId']),
              _buildListTile(Icons.timelapse, "Status", transaction['status'],
                  color: transaction['status'] == 'completed'
                      ? Colors.green
                      : Colors.orange),
              _buildListTile(
                  Icons.calendar_today,
                  "Created At",
                  DateFormat('dd MMM yyyy, HH:mm')
                      .format(transaction['createdAt'].toDate())),
              _buildListTile(Icons.money, "Send Amount",
                  "${transaction['sendAmount']} ${transaction['fromCurrency']}"),
              _buildListTile(Icons.attach_money, "Receive Amount",
                  "${transaction['receiveAmount']} ${transaction['toCurrency']}"),
              _buildListTile(Icons.trending_up, "Sell Rate",
                  transaction['sellRate']?.toString() ?? "N/A"),
            ]),
            _buildCard("Sender Info", [
              _buildListTile(
                  Icons.person, "Name", transaction['sender']?['sendName']),
              _buildListTile(
                  Icons.phone, "Phone", transaction['sender']?['sendPhone']),
              _buildListTile(
                  Icons.email, "Email", transaction['sender']?['sendEmail']),
              _buildListTile(Icons.account_balance, "Bank Code",
                  transaction['sender']?['sendBankCode']),
              _buildListTile(Icons.credit_card, "Account Name",
                  transaction['sender']?['sendAccountName']),
              _buildListTile(Icons.numbers, "Account Number",
                  transaction['sender']?['sendAccountNumber']),
            ]),
            _buildCard("Receiver Info", [
              _buildListTile(Icons.person, "Name",
                  transaction['receiver']?['receiveName']),
              _buildListTile(Icons.phone, "Phone",
                  transaction['receiver']?['receivePhone']),
              _buildListTile(Icons.email, "Email",
                  transaction['receiver']?['receiveEmail']),
              _buildListTile(Icons.account_balance, "Bank Code",
                  transaction['receiver']?['receiveBankCode']),
              _buildListTile(Icons.credit_card, "Account Name",
                  transaction['receiver']?['receiveAccountName']),
              _buildListTile(Icons.numbers, "Account Number",
                  transaction['receiver']?['receiveAccountNumber']),
            ]),
            _buildCard("Verification Images", [
              _buildImageTile(
                  context, "Sender ID Front", transaction['senderImages']?['idFront']),
              _buildImageTile(
                  context, "Sender ID Rear", transaction['senderImages']?['idRear']),
              _buildImageTile(
                  context, "Sender Passport", transaction['senderImages']?['passport']),
              _buildImageTile(
                  context, "Receiver ID Front", transaction['receiverImages']?['idFront']),
              _buildImageTile(
                  context, "Receiver ID Rear", transaction['receiverImages']?['idRear']),
              _buildImageTile(
                  context, "Receiver Passport", transaction['receiverImages']?['passport']),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(String title, List<Widget> children) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent),
            ),
            Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildListTile(IconData icon, String label, String? value,
      {Color color = Colors.black}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(value ?? "N/A", style: TextStyle(color: color)),
    );
  }

    Widget _buildImageTile(BuildContext context, String label, String? imageUrl) {
    return imageUrl != null
        ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () {
                      _showFullImage(context, imageUrl);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          double screenWidth = MediaQuery.of(context).size.width;
                          double imageWidth =
                              screenWidth > 600 ? 500 : screenWidth * 0.85; // Điều chỉnh kích thước ảnh

                          return Image.network(
                            imageUrl,
                            height: 200,
                            width: imageWidth, // Giới hạn chiều rộng ảnh
                            fit: BoxFit.cover, // Ảnh sẽ che hết vùng hiển thị nhưng vẫn giữ tỷ lệ
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        : SizedBox.shrink();
  }

  void _showFullImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 0.5,
          maxScale: 2.5,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(imageUrl, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

}
