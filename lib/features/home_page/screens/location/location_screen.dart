import 'package:flutter/cupertino.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/shared/services/outlets_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationForm extends StatefulWidget {
  const LocationForm({super.key});

  @override
  State<LocationForm> createState() => _LocationFormState();
}

class _LocationFormState extends State<LocationForm> {
  final TextEditingController locationController = TextEditingController();
  final OutletsService _outletsService = OutletsService();
  late GoogleMapController mapController;
  TextEditingController searchOutletController = TextEditingController();
  String? outletId;
  String? selectedOutlet;
  List<Map<String, String>> _outletDisplayList = [];
  List<Map<String, String>> filteredOutlets = [];
  bool isLoading = true;
  bool mapLoadFailed = false;
  bool _locationPermissionGranted = false;
  double? _latitude;
  double? _longitude;
  Set<Circle> _circles = {};

  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
    _fetchOutlets();
  }

Future<void> _checkLocationPermission() async {
  LocationPermission permission = await Geolocator.checkPermission();

  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }

  if (permission == LocationPermission.whileInUse ||
      permission == LocationPermission.always) {
    // ✅ Lấy vị trí sau khi được cấp quyền
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() {
      _locationPermissionGranted = true;
      _latitude = position.latitude;
      _longitude = position.longitude;
    });

    // ✅ Log vị trí thực tế
    print("📍 Current Location:");
    print("Latitude: $_latitude");
    print("Longitude: $_longitude");
  } else {

    setState(() {
      _locationPermissionGranted = false;
      _latitude = 1.2834; 
      _longitude = 103.8607;
    });

    print("⚠️ Người dùng từ chối quyền vị trí. Sử dụng vị trí mặc định.");
  }

  _updateMarkers();
}


  void _updateMarkers() {
    _markers.clear();

    // 📍 Thêm marker cho các outlet
    for (var outlet in _outletDisplayList) {
      if (outlet['lat'] != null && outlet['lng'] != null) {
        try {
          _markers.add(
            Marker(
              markerId: MarkerId(outlet['outletId'] ?? ""),
              position: LatLng(
                double.parse(outlet['lat']!),
                double.parse(outlet['lng']!),
              ),
              infoWindow: InfoWindow(
                title: outlet['outletName'],
                snippet:
                    "${outlet['outletAddress']}, ${outlet['city']}, ${outlet['country']}",
              ),
            ),
          );
        } catch (e) {
          print('❌ Lỗi khi tạo Marker: $e');
        }
      }
    }

    // 📍 Thêm marker cho vị trí của người dùng
    if (_latitude != null && _longitude != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId("user_location"),
          position: LatLng(_latitude!, _longitude!),
          icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueBlue), // 🔵 Marker màu xanh cho người dùng
          infoWindow: const InfoWindow(title: "Your Location"),
        ),
      );

      // 🔵 Thêm hình tròn thể hiện vùng người dùng
      _circles.add(
        Circle(
          circleId: const CircleId("user_circle"),
          center: LatLng(_latitude!, _longitude!),
          radius: 500, // 🎯 Bán kính 500m
          strokeWidth: 2,
          strokeColor: Colors.blue.withOpacity(0.7),
          fillColor: Colors.blue.withOpacity(0.3),
        ),
      );
    }

    setState(() {});
  }

  Future<void> _fetchOutlets() async {
    final outlets = await _outletsService.fetchOutlets();
    if (mounted) {
      setState(() {
        _outletDisplayList = outlets;
        filteredOutlets = _outletDisplayList.take(5).toList();
        isLoading = false;
      });
    }
  }

//  Future<void> _fetchOutlets() async {
//   final outlets = await _outletsService.fetchOutlets();

//   // Chỉ lấy outlets có country là "Singapore"
//   // final singaporeOutlets = outlets.where((outlet) =>
//   //   outlet['country'].toString().toLowerCase() == "singapore"
//   // ).toList();

//   List<Map<String, String>> updatedOutlets = [];

//   for (var outlet in outlets) {
//     try {
//       String fullAddress =
//           "${outlet['outletAddress']}, ${outlet['city']}, ${outlet['country']}";
//       print("📍 Đang tìm tọa độ cho: $fullAddress");

//       // Gọi API Geocoding để lấy tọa độ
//       final response = await _outletsService.getGeocode(fullAddress);

//       if (response != null && response['status'] == "OK") {
//         var location = response['results'][0]['geometry']['location'];
//         double lat = location['lat'];
//         double lng = location['lng'];

//         print("✅ Tìm thấy tọa độ: ($lat, $lng)");

//         updatedOutlets.add({
//           ...outlet,
//           'lat': lat.toString(),
//           'lng': lng.toString(),
//         });
//       } else {
//         print("⚠️ Không tìm thấy tọa độ cho: $fullAddress");
//       }
//     } catch (e) {
//       print("❌ Lỗi khi lấy tọa độ cho địa chỉ: ${outlet['outletName']} - $e");
//     }
//   }

//   if (mounted) {
//     setState(() {
//       _outletDisplayList = updatedOutlets;
//       filteredOutlets = _outletDisplayList;
//       _updateMarkers();
//       isLoading = false;
//     });
//   }
// }

  void _onMapCreated(GoogleMapController controller) {
    debugPrint("✅ Google Map đã được khởi tạo!");
    try {
      mapController = controller;
      setState(() {
        mapLoadFailed = false;
      });
    } catch (e, stackTrace) {
      debugPrint("❌ Lỗi khi khởi tạo Google Map: $e");
      debugPrint(stackTrace.toString());
      setState(() {
        mapLoadFailed = true;
      });
    }
  }

  void _showOutletPicker(BuildContext context) {
    List<Map<String, String>> filteredOutletList =
        List.from(_outletDisplayList);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setStateModal) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Container(
              height: 450,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Tiêu đề "Select Outlet"
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Select Outlet',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),

                  // Ô tìm kiếm outlet
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: TextField(
                      controller: searchOutletController,
                      decoration: InputDecoration(
                        hintText: 'Search outlet...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (value) {
                        setStateModal(() {
                          String searchKeyword = value.toLowerCase();
                          filteredOutletList = _outletDisplayList.where((item) {
                            final outletName =
                                item['outletName']!.toLowerCase();
                            return outletName.contains(searchKeyword);
                          }).toList();
                        });
                      },
                    ),
                  ),

                  SizedBox(height: 10),

                  // Danh sách outlets
                  Expanded(
                    child: filteredOutletList.isNotEmpty
                        ? ListView.builder(
                            itemCount: filteredOutletList.length,
                            itemBuilder: (context, index) {
                              final item = filteredOutletList[index];
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    outletId = item['outletId']!;
                                    selectedOutlet = outletId!;
                                  });
                                  print("🔄 Selected Outlet: $selectedOutlet");
                                  Navigator.pop(context);
                                },
                                child: _buildOutletItem(
                                    item), // Dùng widget tùy chỉnh
                              );
                            },
                          )
                        : Center(
                            child: Text(
                              "No matching outlets.",
                              style:
                                  TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          ),
                  ),

                  // Nút hủy
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

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          children: [
            _buildLabel(),
            const SizedBox(height: 16),
            _buildOutletList(),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        tr('discover_outlets'),
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: CupertinoColors.systemGrey,
        ),
      ),
    );
  }

  Widget _buildOutletList() {
    return Expanded(
      child: Column(
        children: [
          // 🔹 Nút chọn outlet
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: GestureDetector(
              onTap: () => _showOutletPicker(context),
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
                      selectedOutlet != null && selectedOutlet!.isNotEmpty
                          ? _outletDisplayList.firstWhere(
                                  (item) => item['outletId'] == selectedOutlet,
                                  orElse: () => {
                                        'outletName': 'Select Outlet'
                                      })['outletName'] ??
                              "Select Outlet"
                          : "Select Outlet",
                      style: TextStyle(fontSize: 16),
                    ),
                    Icon(Icons.arrow_drop_down, color: Colors.black54),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 8), // Khoảng cách

          // 🔹 Hiển thị Google Map trước
          Expanded(
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: const CameraPosition(
                target: LatLng(10.762622, 106.660172), // TP.HCM
                zoom: 10,
              ),
              markers: _markers,
              circles: _circles,
            ),
          ),

          // 🔹 Hiển thị loading chỉ cho danh sách outlets
          if (isLoading) const CupertinoActivityIndicator(),
        ],
      ),
    );
  }

  Widget _buildOutletItem(Map<String, String> outlet) {
    return CupertinoListTile(
      leading: Icon(
        CupertinoIcons.location_solid,
        color: CupertinoColors.activeBlue,
      ),
      title: Text(
        outlet['outletName'] ?? "Unknown Name",
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: CupertinoColors.label,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 5),
          Text(
            outlet['outletAddress'] ?? "No Address",
            style: const TextStyle(
              fontSize: 14,
              color: CupertinoColors.secondaryLabel,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _buildInfoChip(
                icon: CupertinoIcons.money_dollar_circle,
                label: outlet['localCurrencyCode'] ?? "N/A",
              ),
              _buildInfoChip(
                icon: CupertinoIcons.globe,
                label: outlet['countryCode'] ?? "N/A",
              ),
              _buildInfoChip(
                icon: CupertinoIcons.placemark,
                label: outlet['country'] ?? "N/A",
              ),
              _buildInfoChip(
                icon: CupertinoIcons.building_2_fill,
                label: outlet['city'] ?? "N/A",
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: CupertinoColors.activeBlue,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: CupertinoColors.secondaryLabel,
          ),
        ),
      ],
    );
  }
}
