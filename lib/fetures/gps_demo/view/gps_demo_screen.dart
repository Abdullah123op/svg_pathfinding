import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:svg_pathfinding/utils/logger.dart';

class GpsDemo extends StatefulWidget {
  const GpsDemo({super.key});

  @override
  _GpsDemoState createState() => _GpsDemoState();
}

class _GpsDemoState extends State<GpsDemo> {
  Position? _currentPosition;
  double? tappedLatitude;
  double? tappedLongitude;

  // Define the geographic boundaries of your office
  final double minLatitude = 22.991990;
  final double maxLatitude = 22.992444;
  final double minLongitude = 72.496957;
  final double maxLongitude = 72.497742;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  void _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled, don't continue
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, don't continue
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, don't continue
      return Future.error('Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can get the location
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1, // Set to 1 meter to get more frequent updates
      ),
    ).listen((Position position) {
      setState(() {
        Log.e("Current position: ${position.latitude}, ${position.longitude}");
        _currentPosition = position;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SVG Map with Geolocation'),
      ),
      body: Column(
        children: [
          Stack(
            children: [
              Container(
                color: Colors.red.withOpacity(0.2),
                child: GestureDetector(
                  onTapUp: (TapUpDetails details) {
                    _onSvgTap(details.localPosition);
                  },
                  child: const Image(
                    image: AssetImage('assets/solitaire_connect.png'),
                    height: 300,
                    width: 700,
                  ),
                ),
              ),
              if (_currentPosition != null)
                Positioned(
                  left: _calculateX(_currentPosition!.longitude),
                  top: _calculateY(_currentPosition!.latitude),
                  child: const Icon(Icons.location_on_rounded, color: Color(0xFFFF0F00)),
                ),
              if (tappedLatitude != null && tappedLongitude != null)
                Positioned(
                  left: _calculateX(tappedLongitude!),
                  top: _calculateY(tappedLatitude!),
                  child: const Icon(Icons.circle, color: Colors.blue),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _onSvgTap(Offset localPosition) {
    double officeWidth = 700.0;
    double officeHeight = 300.0;

    double tappedLongitude = minLongitude + (localPosition.dx / officeWidth) * (maxLongitude - minLongitude);
    double tappedLatitude = minLatitude + ((officeHeight - localPosition.dy) / officeHeight) * (maxLatitude - minLatitude);

    setState(() {
      this.tappedLatitude = tappedLatitude;
      this.tappedLongitude = tappedLongitude;
    });

    Log.e("Tapped coordinates: Latitude: $tappedLatitude, Longitude: $tappedLongitude");
  }

  double _calculateX(double longitude) {
    // Office dimensions in pixels
    double officeWidth = 700.0; // Width of your SVG in pixels

    // Clamp the longitude to the defined boundaries
    double clampedLongitude = longitude.clamp(minLongitude, maxLongitude);
    Log.e("Clamped Longitude: $clampedLongitude");

    // Calculate the x-coordinate in the SVG based on the longitude
    double x = ((clampedLongitude - minLongitude) / (maxLongitude - minLongitude)) * officeWidth;
    Log.e("Longitude: $longitude, Calculated X: $x");
    return x;
  }

  double _calculateY(double latitude) {
    // Office dimensions in pixels
    double officeHeight = 300.0; // Height of your SVG in pixels

    // Clamp the latitude to the defined boundaries
    double clampedLatitude = latitude.clamp(minLatitude, maxLatitude);
    Log.e("Clamped Latitude: $clampedLatitude");

    // Calculate the y-coordinate in the SVG based on the latitude
    double y = officeHeight - ((clampedLatitude - minLatitude) / (maxLatitude - minLatitude)) * officeHeight;
    Log.e("Latitude: $latitude, Calculated Y: $y");
    return y;
  }
}
