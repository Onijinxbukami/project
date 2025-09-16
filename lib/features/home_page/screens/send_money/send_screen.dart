import 'dart:async';

import 'package:circle_flags/circle_flags.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/app/routes.dart';
import 'package:flutter_application_1/shared/services/outlets_service.dart';
import 'package:flutter_application_1/shared/widgets/progressbar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SendMoneyForm extends StatefulWidget {
  const SendMoneyForm({super.key});

  @override
  State<SendMoneyForm> createState() => _SendMoneyFormState();
}

class _SendMoneyFormState extends State<SendMoneyForm> {
  Timer? _debounceTimer;
  String fromCurrency = "";
  String toCurrency = "";
  String exchangeRate = "";
  String? outletId;
  String? selectedOutlet;

  String? selectedOutletName;
  String? localCurrency;
  String? foreignCurrency;
  String? selectedCurrency;
  double? sendRate, buyRate, sellRate;
  String searchKeyword = '';

  final TextEditingController _sendController = TextEditingController();
  final TextEditingController _receiveController = TextEditingController();

  String? _currencyError;
  List<String> currencyCodes = [];
  List<Map<String, String>> _originalOutletList = [];
  List<Map<String, String>> _outletDisplayList = [];
  List<Map<String, String>> filteredOutletList = [];

  List<Map<String, String>> _currencyDisplayList = [];

  TextEditingController searchOutletController = TextEditingController();

  final TextEditingController locationController = TextEditingController();
  final Map<String, String> _currencyToCountryCode = {
    'USD': 'us',
    'EUR': 'eu',
    'JPY': 'jp',
    'GBP': 'gb',
    'AUD': 'au',
    'CAD': 'ca',
    'CHF': 'ch',
    'CNY': 'cn',
    'SEK': 'se',
    'NZD': 'nz',
    'VND': 'vn',
    'THB': 'th',
    'SGD': 'sg',
    'MXN': 'mx',
    'BRL': 'br',
    'ZAR': 'za',
    'RUB': 'ru',
    'INR': 'in',
    'KRW': 'kr',
    'HKD': 'hk',
    'MYR': 'my',
    'PHP': 'ph',
    'IDR': 'id',
    'TRY': 'tr',
    'PLN': 'pl',
    'HUF': 'hu',
    'CZK': 'cz',
    'DKK': 'dk',
    'NOK': 'no',
    'ILS': 'il',
    'SAR': 'sa',
    'AED': 'ae',
    'EGP': 'eg',
    'ARS': 'ar',
    'CLP': 'cl',
    'COP': 'co',
    'PEN': 'pe',
    'PKR': 'pk',
    'BDT': 'bd',
    'LKR': 'lk',
    'KWD': 'kw',
    'BHD': 'bh',
    'OMR': 'om',
    'QAR': 'qa',
    'JOD': 'jo',
    'XOF': 'bj',
    'XAF': 'cm',
    'XCD': 'ag',
    'XPF': 'pf',
    'MAD': 'ma',
    'DZD': 'dz',
    'TND': 'tn',
    'LBP': 'lb',
    'JMD': 'jm',
    'TTD': 'tt',
    'NGN': 'ng',
    'GHS': 'gh',
    'KES': 'ke',
    'UGX': 'ug',
    'TZS': 'tz',
    'ETB': 'et',
    'ZMW': 'zm',
    'MZN': 'mz',
    'BWP': 'bw',
    'NAD': 'na',
    'SCR': 'sc',
    'MUR': 'mu',
    'BBD': 'bb',
    'BSD': 'bs',
    'FJD': 'fj',
    'SBD': 'sb',
    'PGK': 'pg',
    'TOP': 'to',
    'WST': 'ws',
    'KZT': 'kz',
    'UZS': 'uz',
    'TJS': 'tj',
    'KGS': 'kg',
    'MMK': 'mm',
    'LAK': 'la',
    'KHR': 'kh',
    'MNT': 'mn',
    'NPR': 'np',
    'BND': 'bn',
    'XAU': 'xau',
    'XAG': 'xag',
    'XPT': 'xpt',
    'XPD': 'xpd',
    'HTG': 'ht',
    'LRD': 'lr',
    'BIF': 'bi',
    'IQD': 'iq',
    'MGA': 'mg',
    'LSL': 'ls',
    'AFN': 'af',
    'CVE': 'cv',
    'BGN': 'bg',
    'LYD': 'ly',
    'AWG': 'aw',
    'HRK': 'hr',
    'BZD': 'bz',
    'HNL': 'hn',
    'MVR': 'mv',
    'GYD': 'gy',
    'SVC': 'sv',
    'ISK': 'is',
    'GNF': 'gn',
    'IRR': 'ir',
    'KYD': 'ky',
    'DJF': 'dj',
    'MWK': 'mw',
    'BOB': 'bo',
    'LTL': 'lt',
    'AMD': 'am',
    'CRC': 'cr',
    'KMF': 'km',
    'AOA': 'ao',
    'ALL': 'al',
    'ERN': 'er',
    'EEK': 'ee',
    'GMD': 'gm',
    'GIP': 'gi',
    'CUP': 'cu',
    'BMD': 'bm',
    'FKP': 'fk',
    'CDF': 'cd',
    'LVL': 'lv',
    'MKD': 'mk',
    'GTQ': 'gt',
    'AZN': 'az',
    'DOP': 'do',
    'BYN': 'by',
    'GEL': 'ge',
    'BTN': 'bt',
    'MOP': 'mo',
    'ANG': 'ai',
    'BYR': 'by'
  };
  bool _fetchingRates = false;
  bool isSenderActive = true;
  bool isRecipientActive = true;
  String? _numericError;
  List<Map<String, dynamic>> supportedCurrencyPairs = [];

  bool isLoading = true;
  final OutletsService _outletsService = OutletsService();

  @override
  void initState() {
    super.initState();
    _fetchOutlets();
    fetchCurrencyCodes();
    _setupTextFieldCurrencyListeners();
    _loadSavedInputs();
    loadCurrencyPairs();
  }

  void loadCurrencyPairs() async {
    List<Map<String, dynamic>> pairs =
        await fetchCurrencyPairsFromOutletRates();
    setState(() {
      supportedCurrencyPairs = pairs;
    });
  }

  Future<List<Map<String, dynamic>>> fetchCurrencyPairsFromOutletRates() async {
    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('outletRates').get();

      if (querySnapshot.docs.isEmpty) {
        print("❌ No outlet rates found.");
        return [];
      }

      List<Map<String, dynamic>> currencyPairs = [];

      for (var doc in querySnapshot.docs) {
        final Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;

        if (data == null) {
          print("⚠️ Skipping document with null data.");
          continue;
        }

        //print("📜 Firestore Raw Data: $data");

        String? localCurrency = data['localCurrency'];
        String? foreignCurrency = data['foreignCurrency'];
        String? outletId =
            data.containsKey('outletId') ? data['outletId'] : null;

        if (localCurrency == null ||
            foreignCurrency == null ||
            outletId == null) {
          print("⚠️ Skipping invalid data: $data");
          continue;
        }

        currencyPairs.add({
          'localCurrency': localCurrency,
          'foreignCurrency': foreignCurrency,
          'outletId': outletId,
        });
      }

      print("✅ Found ${currencyPairs.length} currency pairs.");
      return currencyPairs;
    } catch (e) {
      print("⚠️ Error fetching currency pairs: $e");
      return [];
    }
  }

  Future<void> _fetchOutletRates(
      String outletId, String fromCurrency, String toCurrency) async {
    if (outletId.isEmpty || fromCurrency.isEmpty || toCurrency.isEmpty) {
      setState(() {
        _currencyError = "⚠️ Missing required parameters";
      });
      return;
    }

    setState(() {
      _fetchingRates = true;
      _currencyError = null;
    });

    try {
      // 🔄 Thử lấy dữ liệu theo cặp từCurrency -> toCurrency
      var ratesData = await _outletsService.fetchOutletRates(
        outletId: outletId,
        fromCurrency: fromCurrency,
        toCurrency: toCurrency,
      );

      // 🔄 Nếu không có dữ liệu, thử với cặp đảo ngược
      bool isReversed = false;
      if (ratesData == null) {
        ratesData = await _outletsService.fetchOutletRates(
          outletId: outletId,
          fromCurrency: toCurrency,
          toCurrency: fromCurrency,
        );
        isReversed = true;
      }

      //print("📥 API Response: $ratesData");

      if (mounted) {
        setState(() {
          _fetchingRates = false;

          if (ratesData == null) {
            sendRate = 0.0;
            buyRate = 0.0;
            sellRate = 0.0;
            _currencyError =
                "❌ No outlet rates found for $fromCurrency ➡️ $toCurrency";
          } else {
            // ✅ Nếu là cặp đảo, giữ nguyên tỷ giá nhưng đổi chiều
            if (isReversed) {
              sendRate = ratesData['sendRate'] ?? 0.0;
              buyRate = ratesData['buyRate'] ?? 0.0;
              sellRate = ratesData['sellRate'] ?? 0.0;
            } else {
              sendRate = ratesData['sendRate'] ?? 0.0;
              buyRate = ratesData['buyRate'] ?? 0.0;
              sellRate = ratesData['sellRate'] ?? 0.0;
            }

            localCurrency = fromCurrency;
            foreignCurrency = toCurrency;
            _currencyError = null;
          }
        });
      }
    } catch (e) {
      print("⚠️ Error fetching outlet rates: $e");
      setState(() {
        _fetchingRates = false;
        _currencyError = "⚠️ Error loading rates, please try again.";
      });
    }
  }

  Future<void> _fetchOutletRatesAndCurrencies(
      String outletId, String fromCurrency, String toCurrency) async {
    await _fetchOutletRates(outletId, fromCurrency, toCurrency);
    await _fetchOutletCurrencies(outletId);
  }

  Future<void> _fetchOutletCurrencies(String outletId) async {
    print("🔄 Fetching supported currencies for outlet: $outletId");
    setState(() {
      _fetchingRates = true;
      _currencyError = null;
    });

    try {
      final ratesData = await _outletsService.fetchOutletCurrencies(outletId);

      if (mounted) {
        setState(() {
          _fetchingRates = false;

          if (ratesData == null || ratesData.isEmpty) {
            _currencyError = "⚠️ No currency pairs available for this outlet.";
          } else {
            _currencyError = null;

            // Tạo danh sách cặp tiền tệ, bao gồm cả cặp đảo ngược nhưng giữ nguyên tỷ giá
            final newPairs = ratesData.expand((rate) {
              return [
                {
                  'localCurrency': rate['localCurrency'] ?? '',
                  'foreignCurrency': rate['foreignCurrency'] ?? '',
                  'sendRate': rate['sendRate'] ?? 0.0,
                  'buyRate': rate['buyRate'] ?? 0.0,
                  'sellRate': rate['sellRate'] ?? 0.0,
                  'outletId': outletId,
                },
                {
                  'localCurrency': rate['foreignCurrency'] ?? '',
                  'foreignCurrency': rate['localCurrency'] ?? '',
                  'sendRate': rate['sendRate'] ?? 0.0, // ✅ Giữ nguyên sendRate
                  'buyRate': rate['buyRate'] ?? 0.0, // ✅ Giữ nguyên buyRate
                  'sellRate': rate['sellRate'] ?? 0.0, // ✅ Giữ nguyên sellRate
                  'outletId': outletId,
                }
              ];
            }).toList();

            // Loại bỏ các cặp cũ của outletId này (nếu có) và thêm cặp mới
            supportedCurrencyPairs
                .removeWhere((pair) => pair['outletId'] == outletId);
            supportedCurrencyPairs.addAll(newPairs);
            //print("✅ Updated supportedCurrencyPairs: $supportedCurrencyPairs");
          }
        });

        _updateOutletList(); // Cập nhật danh sách outlet sau khi có dữ liệu
      }
    } catch (e) {
      print("⚠️ Error fetching outlet currencies: $e");
      setState(() {
        _fetchingRates = false;
        _currencyError = "⚠️ Error loading currency pairs, please try again.";
      });
    }
  }

  Future<void> _fetchOutlets() async {
    setState(() => isLoading = true);
    try {
      final outlets = await _outletsService.fetchOutlets();
      if (mounted) {
        setState(() {
          _originalOutletList = List.from(outlets);
          _outletDisplayList = List.from(outlets);
          filteredOutletList = _outletDisplayList.take(5).toList();
          isLoading = false;
          supportedCurrencyPairs = [];
        });
      }
    } catch (e) {
      print("⚠️ Error fetching outlets: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchCurrencyCodes() async {
    final currencyList = await _outletsService.fetchCurrencyCodes();
    setState(() {
      _currencyDisplayList = currencyList;
    });
  }

  Future<void> _loadSavedInputs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      fromCurrency = prefs.getString('fromCurrency') ?? "";
      toCurrency = prefs.getString('toCurrency') ?? "";
      selectedOutlet = prefs.getString('selectedOutlet') ?? '';
    });

    // Kiểm tra & tìm outlet name từ danh sách outlets
    String? selectedOutletId = selectedOutlet;
    String outletName = _outletDisplayList.firstWhere(
          (item) => item['outletId'] == selectedOutletId,
          orElse: () => {'outletName': 'No outlet selected'},
        )['outletName'] ??
        'No outlet selected';

    // Cập nhật UI và SharedPreferences
    setState(() {
      searchOutletController.text = outletName;
    });
    await prefs.setString('selectedOutletName', outletName);

    // Cập nhật danh sách lọc outlet
    setState(() {
      filteredOutletList = _outletDisplayList.where((item) {
        final outletNameLower = item['outletName']!.toLowerCase();
        return outletNameLower.contains(outletName.toLowerCase());
      }).toList();
    });

    // Tính totalPay
    double sendAmount = double.tryParse(_sendController.text) ?? 0.0;
    double totalPay = sendAmount + (sendRate ?? 0.0);
    await prefs.setString('totalPay', totalPay.toStringAsFixed(2));

    // Debug log để kiểm tra giá trị đã khôi phục
    print("📥 Khôi phục fromCurrency: $fromCurrency");
    print("📥 Khôi phục toCurrency: $toCurrency");
    print("📥 Khôi phục sendAmount: ${_sendController.text}");
    print("📥 Khôi phục receiveAmount: ${_receiveController.text}");
    print("📥 Khôi phục selectedOutlet: $selectedOutlet");
    print("📥 Khôi phục outletName: $outletName");
    print("📥 Khôi phục sellRate: $sellRate");
    print("📥 Khôi phục sendRate: $sendRate");
    print("📥 Khôi phục totalPay: $totalPay");
  }

  String _calculateTotalPay() {
    double sendAmount = double.tryParse(_sendController.text) ?? 0.0;
    double totalPay = (sendAmount > 0) ? sendAmount + (sendRate ?? 0.0) : 0.0;
    return totalPay.toStringAsFixed(2);
  }

  bool _validateNumeric(TextEditingController controller) {
    final input = controller.text;
    if (input.isNotEmpty && !RegExp(r'^[0-9]*\.?[0-9]*$').hasMatch(input)) {
      setState(() {
        _numericError = "❌ Only numbers are allowed!";
      });
      return false;
    } else {
      setState(() {
        _numericError = null;
      });
      return true;
    }
  }

  void _setupTextFieldCurrencyListeners() {
    _sendController.addListener(() {
      if (isSenderActive) {
        String inputText = _sendController.text.trim();
        if (inputText.isEmpty || !_validateNumeric(_sendController)) {
          isRecipientActive = false;
          _receiveController.text = "";
          isRecipientActive = true;
          return;
        }

        double sendAmount = double.tryParse(inputText) ?? 0.0;

        if (sellRate != null && sellRate! > 0) {
          double receiveAmount = sendAmount / sellRate!;
          String receiveText = receiveAmount.toStringAsFixed(2);

          if (_receiveController.text != receiveText) {
            isRecipientActive = false;
            _receiveController.text = receiveText;
            isRecipientActive = true;
          }
        }
      }
    });

    _receiveController.addListener(() {
      if (isRecipientActive) {
        String inputText = _receiveController.text.trim();
        if (inputText.isEmpty || !_validateNumeric(_receiveController)) {
          isSenderActive = false;
          _sendController.text = "";
          isSenderActive = true;
          return;
        }

        double receiveAmount = double.tryParse(inputText) ?? 0.0;

        if (sellRate != null && sellRate! > 0) {
          double sendAmount = receiveAmount * sellRate!;
          String sendText = sendAmount.toStringAsFixed(2);

          if (_sendController.text != sendText) {
            isSenderActive = false;
            _sendController.text = sendText;
            isSenderActive = true;
          }
        }
      }
    });
  }

  void _recalculateReceiveAmount() {
    if (sellRate != null && sellRate! > 0) {
      String sendText = _sendController.text.trim();
      if (sendText.isNotEmpty && _validateNumeric(_sendController)) {
        double sendAmount = double.tryParse(sendText) ?? 0.0;
        double receiveAmount = sendAmount / sellRate!;
        receiveAmount = double.parse(receiveAmount.toStringAsFixed(2));

        if (_receiveController.text != receiveAmount.toStringAsFixed(2)) {
          isRecipientActive = false;
          _receiveController.text = receiveAmount.toStringAsFixed(2);
          isRecipientActive = true;
        }
      }
    }
  }

  void _updateOutletList({bool forceUpdate = false}) {
    if (fromCurrency.isNotEmpty && toCurrency.isNotEmpty) {
      setState(() {
        print("🔄 Filtering outlets for $fromCurrency ➡️ $toCurrency");
        print(
            "🔍 Original Outlet List: ${_originalOutletList.length} outlets available.");

        List<Map<String, String>> newFilteredList = filterOutletsByCurrency(
            List.from(_originalOutletList),
            supportedCurrencyPairs,
            fromCurrency,
            toCurrency);

        // Không giữ danh sách cũ nếu không có cặp tiền tệ hợp lệ
        _outletDisplayList = newFilteredList;

        if (_outletDisplayList.isEmpty) {
          _currencyError =
              "❌ Currency pair $fromCurrency ➡️ $toCurrency is not supported.";
        } else {
          _currencyError = null; // Xóa lỗi nếu có outlet
        }

        print(
            "📌 After updating, display list has: ${_outletDisplayList.length} outlets");
      });
    }
  }

  List<Map<String, String>> filterOutletsByCurrency(
      List<Map<String, String>> originalOutletList,
      List<Map<String, dynamic>> supportedCurrencyPairs,
      String fromCurrency,
      String toCurrency) {
    if (supportedCurrencyPairs.isEmpty) {
      print("❌ Error: No supported currency pairs available.");
      return [];
    }

    // 🌟 Mở rộng danh sách để bao gồm cả chiều đảo ngược 🌟
    List<Map<String, dynamic>> expandedPairs = [];
    for (var pair in supportedCurrencyPairs) {
      expandedPairs.add(pair); // Cặp gốc
      expandedPairs.add({
        'localCurrency': pair['foreignCurrency'],
        'foreignCurrency': pair['localCurrency'],
        'sellRate': pair['sellRate'], // Đảo ngược sellRate thành buyRate
        'buyRate': pair['buyRate'], // Đảo ngược buyRate thành sellRate
        'outletId': pair['outletId']
      }); // Cặp đảo ngược
    }

    // 🔍 Lọc outlets theo cặp tiền tệ hợp lệ
    List<Map<String, String>> filteredOutlets =
        originalOutletList.where((outlet) {
      String outletId = outlet['outletId'] ?? '';
      if (outletId.isEmpty) {
        print("⚠️ Outlet with no outletId: $outlet");
        return false;
      }

      return expandedPairs.any((pair) =>
          pair['localCurrency'] == fromCurrency &&
          pair['foreignCurrency'] == toCurrency &&
          pair['outletId'].toString() == outletId);
    }).map((outlet) {
      // 🔍 Tìm `sellRate` & `buyRate` từ danh sách mở rộng
      var matchingPair = expandedPairs.firstWhere(
        (pair) =>
            pair['localCurrency'] == fromCurrency &&
            pair['foreignCurrency'] == toCurrency &&
            pair['outletId'].toString() == outlet['outletId'],
        orElse: () => {},
      );

      String sellRate = matchingPair.isNotEmpty
          ? (matchingPair['sellRate']?.toString() ?? 'N/A')
          : 'N/A';

      String buyRate = matchingPair.isNotEmpty
          ? (matchingPair['buyRate']?.toString() ?? 'N/A')
          : 'N/A';

      return {
        ...outlet,
        'sellRate': sellRate, // Thêm sellRate
        'buyRate': buyRate, // Thêm buyRate
      };
    }).toList();

    print(
        "✅ Final Filtered Outlet List (with Sell & Buy Rate): $filteredOutlets");
    return filteredOutlets;
  }

  void _showOutletPicker(BuildContext context) {
    List<Map<String, String>> filteredList = filterOutletsByCurrency(
      List.from(_originalOutletList),
      supportedCurrencyPairs,
      fromCurrency,
      toCurrency,
    );

    print("Filtered Outlet List (before fetch): $filteredList");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setStateModal) {
          // 🔄 Fetch dữ liệu song song để tăng tốc
          Future.microtask(() async {
            bool hasNA =
                filteredList.any((outlet) => outlet['sellRate'] == 'N/A');
            if (hasNA) {
              print("⚠️ Fetching missing sell rates...");

              await Future.wait(filteredList.map((outlet) async {
                if (outlet['sellRate'] == 'N/A') {
                  await _fetchOutletRatesAndCurrencies(
                    outlet['outletId']!,
                    fromCurrency,
                    toCurrency,
                  );
                }
              }));

              // ✅ Cập nhật danh sách outlets sau khi fetch
              setStateModal(() {
                filteredList = filterOutletsByCurrency(
                  List.from(_originalOutletList),
                  supportedCurrencyPairs,
                  fromCurrency,
                  toCurrency,
                );

                // 🛠 Nếu chưa chọn outlet, mặc định chọn outlet đầu tiên
                if (selectedOutlet == null && filteredList.isNotEmpty) {
                  final firstOutlet = filteredList.first;
                  selectedOutlet = firstOutlet['outletId']!;
                  selectedOutletName =
                      firstOutlet['outletName'] ?? 'Unknown Outlet';
                  sellRate = firstOutlet['sellRate'] != null
                      ? double.tryParse(firstOutlet['sellRate']!)
                      : null;
                  sendRate = firstOutlet['buyRate'] != null
                      ? double.tryParse(firstOutlet['buyRate']!)
                      : null;

                  print(
                      "✅ Auto-selected First Outlet: $selectedOutlet - $selectedOutletName, Sell: $sellRate, Buy: $sendRate");
                }
              });
            }
          });

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Container(
              height: 500,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  SizedBox(height: 10),
                  Expanded(
                    child: filteredList.isNotEmpty
                        ? ListView.builder(
                            itemCount: filteredList.length,
                            itemBuilder: (context, index) {
                              final item = filteredList[index];

                              return ListTile(
                                title: Text(
                                  item['outletName']!,
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['outletAddress']?.isNotEmpty == true
                                          ? item['outletAddress']!
                                          : "Unknown Address",
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      "${fromCurrency}/${toCurrency}  Sell: ${(item['sellRate'] != null && item['sellRate'] != 'N/A') ? double.parse(item['sellRate']!).toStringAsFixed(5) : 'N/A'}  Buy: ${(item['buyRate'] != null && item['buyRate'] != 'N/A') ? double.parse(item['buyRate']!).toStringAsFixed(5) : 'N/A'}",
                                      style: TextStyle(
                                          color: Colors.green, fontSize: 14),
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  setStateModal(() {
                                    selectedOutlet = item['outletId']!;
                                    selectedOutletName =
                                        item['outletName'] ?? 'Unknown Outlet';
                                    sellRate = item['sellRate'] != null
                                        ? double.tryParse(item['sellRate']!)
                                        : null;
                                    sendRate = item['buyRate'] != null
                                        ? double.tryParse(item['buyRate']!)
                                        : null;
                                  });

                                  print(
                                      "🛠 Selected Outlet: $selectedOutlet - $selectedOutletName, Sell: $sellRate, Buy: $sendRate");

                                  Navigator.pop(context);

                                  // 🛠 Cập nhật lại UI chính
                                  Future.delayed(Duration(milliseconds: 100),
                                      () {
                                    setState(() {});
                                  });

                                  _recalculateReceiveAmount();
                                },
                                tileColor: selectedOutlet == item['outletId']
                                    ? Colors.blue.withOpacity(
                                        0.2) // Highlight nếu đã chọn
                                    : null,
                              );
                            },
                          )
                        : Center(
                            child: Text("No matching outlets.",
                                style: TextStyle(color: Colors.grey)),
                          ),
                  ),
                  SizedBox(height: 10),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel', style: TextStyle(fontSize: 18)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showCurrencyPicker(BuildContext context, bool isSender) {
    TextEditingController searchCurrencyController = TextEditingController();
    List<Map<String, String>> filteredCurrencyList =
        List.from(_currencyDisplayList);

    String currentCurrency = isSender ? fromCurrency : toCurrency;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setStateModal) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Container(
              height: 400,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Select Currency',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: TextField(
                      controller: searchCurrencyController,
                      decoration: const InputDecoration(
                        hintText: 'Search currency...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                      ),
                      onChanged: (value) {
                        _debounceTimer?.cancel();
                        _debounceTimer = Timer(Duration(milliseconds: 300), () {
                          setStateModal(() {
                            String searchKeyword = value.toLowerCase();
                            filteredCurrencyList =
                                _currencyDisplayList.where((item) {
                              return item['currencyCode']!
                                  .toLowerCase()
                                  .contains(searchKeyword);
                            }).toList();
                          });
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredCurrencyList.length,
                      itemBuilder: (context, index) {
                        final item = filteredCurrencyList[index];

                        return ListTile(
                          leading: CircleFlag(
                            (_currencyToCountryCode[item['currencyCode']!] ??
                                    'UN')
                                .toLowerCase(),
                            size: 32,
                          ),
                          title: Text(
                            "${item['currencyCode']} - ${item['description']}",
                            style: const TextStyle(fontSize: 16),
                          ),
                          onTap: () {
                            if (isSender) {
                              fromCurrency = item['currencyCode']!;
                            } else {
                              toCurrency = item['currencyCode']!;
                            }
                            Navigator.pop(context);

                            Future.microtask(() {
                              _updateOutletList(forceUpdate: true);
                              if (selectedOutlet != null) {
                                _fetchOutletRatesAndCurrencies(
                                    selectedOutlet!, fromCurrency, toCurrency);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel', style: TextStyle(fontSize: 18)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _selectFirstAvailableOutlet() {
    if (_outletDisplayList.isNotEmpty) {
      final firstOutlet = _outletDisplayList.first;
      selectedOutlet = firstOutlet['outletId']?.toString() ?? '';
      selectedOutletName =
          firstOutlet['outletName']?.toString() ?? 'Unknown Outlet';

      sellRate = firstOutlet['sellRate'] != null
          ? double.tryParse(firstOutlet['sellRate']!)
          : null;
      sendRate = firstOutlet['buyRate'] != null
          ? double.tryParse(firstOutlet['buyRate']!)
          : null;

      print(
          "✅ Auto-selected Outlet: $selectedOutlet - $selectedOutletName, Sell: $sellRate, Buy: $sendRate");

      setState(() {}); // Cập nhật lại UI
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 600;
    final double padding = isSmallScreen ? 12.0 : 24.0;
    final double fontSize = isSmallScreen ? 14.0 : 18.0;

    return Padding(
      padding: EdgeInsets.all(padding),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
              currentStep: 0,
              backgroundColor: Colors.grey[300]!,
              progressColor: Colors.blue,
              height: 8,
            ),
            // Input Field: You Send
            SizedBox(height: isSmallScreen ? 16 : 24),
            _buildCurrencyInputField(
              tr('you_send'),
              fromCurrency,
              (value) {
                if (value != null) {
                  setState(() => fromCurrency = value);
                  print("🔄 Updated fromCurrency: $fromCurrency");

                  // Lưu song song vào SharedPreferences
                  Future.wait([
                    SharedPreferences.getInstance().then((prefs) =>
                        prefs.setString('fromCurrency', fromCurrency)),
                  ]);
                }
              },
              isSmallScreen,
              _sendController,
              isSender: true,
            ),

            SizedBox(height: isSmallScreen ? 16 : 24),

            _buildCurrencyInputField(
              tr('recipient_gets'),
              toCurrency,
              (value) {
                if (value != null) {
                  setState(() => toCurrency = value);
                  print("🔄 Updated toCurrency: $toCurrency");

                  // Lưu song song vào SharedPreferences
                  Future.wait([
                    SharedPreferences.getInstance().then(
                        (prefs) => prefs.setString('toCurrency', toCurrency)),
                  ]);
                }
              },
              isSmallScreen,
              _receiveController,
              isSender: false,
            ),

            SizedBox(height: isSmallScreen ? 16 : 24),

            Text("Select Outlet"),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                if (selectedOutlet == null || selectedOutlet!.isEmpty) {
                  _selectFirstAvailableOutlet(); // 🛠 Nếu chưa chọn, tự động chọn outlet đầu tiên
                }

                _showOutletPicker(context); // Mở picker

                setState(() {}); // Cập nhật UI
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      (selectedOutletName != null &&
                              selectedOutletName!.isNotEmpty)
                          ? selectedOutletName!
                          : "Select Outlet",
                      style: TextStyle(fontSize: 16),
                    ),
                    Icon(Icons.arrow_drop_down, color: Colors.black54),
                  ],
                ),
              ),
            ),

            // Send Info
            SizedBox(height: isSmallScreen ? 16 : 24),
            _buildSendInfo(isSmallScreen, fontSize),

            // Continue Button
            SizedBox(height: isSmallScreen ? 16 : 24),
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();

                  // selectedOutlet là kiểu String, không cần sử dụng .text
                  String outletId = selectedOutlet ??
                      ''; // Nếu selectedOutlet là null, sử dụng giá trị mặc định ''

                  // Lưu outletId vào SharedPreferences (searchKeyword)
                  await prefs.setString('searchKeyword', outletId);

                  await prefs.setString('fromCurrency', fromCurrency);
                  await prefs.setString('toCurrency', toCurrency);

                  // Lấy các giá trị tiền từ SharedPreferences
                  String sendAmount = prefs.getString('sendAmount') ?? '0.00';
                  String receiveAmount =
                      prefs.getString('receiveAmount') ?? '0.00';

                  // Tìm outletName từ outletId
                  String? outletName = _outletDisplayList.firstWhere(
                      (item) => item['outletId'] == outletId,
                      orElse: () =>
                          {'outletName': 'No outlet selected'})['outletName'];

                  // Lưu outletName vào SharedPreferences
                  await prefs.setString('selectedOutletName', outletName!);

                  await prefs.setString(
                      'sellRate', sellRate?.toString() ?? '0.0');
                  await prefs.setString(
                      'sendRate', sendRate?.toString() ?? '0.0');

                  // In ra console để kiểm tra
                  print("📤 Số tiền gửi: $sendAmount");
                  print("📥 Số tiền nhận: $receiveAmount");
                  print("💱 From Currency: $fromCurrency");
                  print("💱 To Currency: $toCurrency");
                  print("📥 Outlet: $outletName");
                  print("📥 SendRate: $sendRate");
                  print("📥 SellRate: $sellRate");

                  Navigator.pushNamed(context, Routes.userDetails);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6200EE),
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
    );
  }

  Widget _buildCurrencyInputField(
      String label,
      String selectedValue,
      ValueChanged<String?> onChanged,
      bool isSmallScreen,
      TextEditingController controller,
      {bool isSender = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 1),
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
          ),
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              InkWell(
                onTap: () {
                  _showCurrencyPicker(context, isSender);
                },
                child: Row(
                  children: [
                    if (selectedValue.isNotEmpty)
                      CircleFlag(
                        (_currencyToCountryCode[selectedValue] ?? 'UN')
                            .toLowerCase(),
                        size: 24,
                      ),
                    SizedBox(width: 4),
                    Text(
                      selectedValue.isNotEmpty ? selectedValue : 'Select',
                      style: TextStyle(fontSize: 16),
                    ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    if (isSender) {
                      print("🔢 You Send: ${_sendController.text}");
                    } else {
                      print("🔢 Recipient Gets: ${_receiveController.text}");
                    }
                  },
                  decoration: InputDecoration(
                    hintText: tr('enter_amount'),
                    errorText: _numericError,
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Hiển thị thông báo lỗi nếu có
        if (_currencyError != null) ...[
          SizedBox(height: 4),
          Text(
            _currencyError!,
            style: TextStyle(color: Colors.red, fontSize: 14),
          ),
        ]
      ],
    );
  }

  Widget _buildSendInfo(bool isSmallScreen, double fontSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow(
          tr('exchange_rate'),
          (sellRate != null)
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      sellRate!.toStringAsFixed(4),
                      style: TextStyle(fontSize: fontSize),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      fromCurrency,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  ],
                )
              : const Text("Loading..."),
          fontSize: fontSize,
        ),
        _buildInfoRow(
          tr('fees'),
          (fromCurrency.isNotEmpty)
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      sendRate != null
                          ? sendRate!.toStringAsFixed(4)
                          : "0.0000",
                      style: TextStyle(fontSize: fontSize),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      fromCurrency,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  ],
                )
              : const Text("Loading..."),
          fontSize: fontSize,
          leading: CircleFlag(
            // Lá cờ xuất hiện ngay sau chữ "fees"
            (_currencyToCountryCode[fromCurrency] ?? 'UN').toLowerCase(),
            size: 24,
          ),
        ),
        _buildInfoRow(
          tr('total_pay'),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _calculateTotalPay(),
                style: TextStyle(
                  fontSize: fontSize * 1.6,
                  fontWeight: FontWeight.w500, // Làm đậm chữ
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                fromCurrency,
                style: TextStyle(
                  fontSize: fontSize * 1.6,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          isRecipient: true,
          fontSize: fontSize,
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    String title,
    dynamic value, {
    // Chấp nhận cả String và Widget
    Widget? leading, // Thêm leading để hiển thị icon, flag,...
    String? tooltip,
    bool isRecipient = false,
    required double fontSize,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: isRecipient ? FontWeight.bold : FontWeight.normal,
                  fontSize: fontSize,
                ),
              ),
              if (leading != null) ...[
                // Hiển thị flag ngay sau title
                const SizedBox(width: 8),
                leading,
              ],
              if (tooltip != null) ...[
                const SizedBox(width: 4),
                Tooltip(
                  message: tooltip,
                  child: const Icon(Icons.info_outline, size: 16),
                ),
              ],
            ],
          ),
          value is Widget // Kiểm tra nếu value là Widget
              ? value
              : Text(value.toString(),
                  style: TextStyle(
                      fontSize: fontSize)), // Chuyển đổi String thành Text
        ],
      ),
    );
  }
}
