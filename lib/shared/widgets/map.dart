import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationMap extends StatefulWidget {
  const LocationMap({super.key});

  @override
  State<LocationMap> createState() => _LocationMapState();
}

class _LocationMapState extends State<LocationMap> {
  late GoogleMapController mapController;

  final LatLng _initialPosition = LatLng(10.762622, 106.660172); // TP.HCM

  final Set<Marker> _markers = {
    Marker(
      markerId: MarkerId("1"),
      position: LatLng(10.762622, 106.660172),
      infoWindow: InfoWindow(title: "TP. Hồ Chí Minh"),
    ),
  };

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Google Maps Location")),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: _initialPosition,
          zoom: 12,
        ),
        markers: _markers,
      ),
    );
  }
}
