import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:maps/model/location_addrees.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  LocationAddrees? pickedLocation;
  getCurrentLocation() async {
    Location location = Location();

    bool serviceEnabled;
    PermissionStatus permissionGranted;
    LocationData locationData;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    setState(() {
      isGettingLocation = true;
    });

    locationData = await location.getLocation();

    setState(() {
      lat = locationData.latitude;
      long = locationData.longitude;
    });

    final url = Uri.parse(
        "https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=$lat&longitude=$long");

    final respone = await http.get(url);
    final data = json.decode(respone.body);
    pickedLocation = LocationAddrees(
      city: data["city"],
      continent: data["continent"],
      countryName: data["countryName"],
    );

    log(pickedLocation!.city);
    setState(() {
      isGettingLocation = false;
      showMap = true;
    });
  }

  double? long;
  double? lat;
  bool isGettingLocation = false;
  bool showMap = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
            "Map App",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          actions: [
            IconButton(
                onPressed: getCurrentLocation, icon: const Icon(Icons.map))
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                alignment: Alignment.center,
                width: double.infinity,
                height: 600,
                child: showMap
                    ? FlutterMap(
                        options: MapOptions(
                          center: LatLng(lat!, long!),
                          zoom: 9.2,
                        ),
                        nonRotatedChildren: [
                          RichAttributionWidget(
                            attributions: [
                              TextSourceAttribution(
                                'OpenStreetMap contributors',
                                onTap: () => launchUrl(Uri.parse(
                                    'https://openstreetmap.org/copyright')),
                              ),
                            ],
                          ),
                        ],
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.flutter_map_app.app',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: LatLng(lat!, long!),
                                builder: (context) => const Icon(
                                  Icons.location_on,
                                  color: Colors.red,
                                  size: 40,
                                ),
                              ),
                            ],
                          ),
                          CircleLayer(
                            circles: [
                              CircleMarker(
                                  point: LatLng(lat!, long!),
                                  radius: 10000,
                                  useRadiusInMeter: true,
                                  color: Colors.green.withOpacity(0.6),
                                  borderColor: Colors.black.withOpacity(0.6),
                                  borderStrokeWidth: 5),
                            ],
                          ),
                          RichAttributionWidget(
                            animationConfig:
                                const ScaleRAWA(), // Or `FadeRAWA` as is default
                            attributions: [
                              TextSourceAttribution(
                                'My Parntenrs Open Street contributors',
                                onTap: () => launchUrl(Uri.parse(
                                    'https://openstreetmap.org/copyright')),
                              ),
                            ],
                          ),
                        ],
                      )
                    : Text(
                        "Try to Select Location",
                        style:
                            Theme.of(context).textTheme.titleMedium!.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                      ),
              ),
            ],
          ),
        ));
  }
}
