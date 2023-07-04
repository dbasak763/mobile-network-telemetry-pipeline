#Added method to send JSON Payload to API in Flask app server using POST request
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:cell_info/CellResponse.dart';
import 'package:cell_info/models/common/cell_type.dart';
import 'package:device_info/device_info.dart';
import 'package:flutter/material.dart';
import 'package:cell_info/cell_info.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'gauges.dart';
import 'raw.dart';
import 'package:http/http.dart' as http;

void main() { //entry point of program
  runApp(const MyApp());
}
//MyApp is stateless widget so its properties cannot be changed once set
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Highway9 Mobile App'),
    );
    //creates a MaterialApp Widget which sets theme and layout of app
  }
}
//MyHomePage is stateful widget that represents main page of app
class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}
//need to create a separate class to handle stateful behavior
class _MyHomePageState extends State<MyHomePage> {
  String _cellInfo = "";
  int rsrpDisplayedForServingCell = -140; // Default RSRP value
  int rsrpDisplayedForNeighborCell1 = -140;
  int rsrpDisplayedforNeighborCell2 = -140;
  String Band = "", Fc = "", Earfcn = "", Network = "", Eci = "", Pci = "", Tac = "";
  String Rsrq = "", Rssi = "", Snr = "", Mcc = "", Mnc = "", Cqi = "";
  String Time_adv = "", Lat = "", Long = "";
  Position? _userLocation;
  StreamSubscription<Position>? _locationSubscription;
  String _latitude = '';
  String _longitude = '';
  String _altitude = '';
  String _accuracy = '';
  List<CellType> primaryCellList = [];
  List<CellType> neighboringCellList = [];
  CellsResponse? cellsResponse;

  String _formatLTEParams(CellType cell, {String header = ''}) {
    String lteParams = '';

    if (cell.type == "LTE") {
      int earfcn = cell.lte?.bandLTE?.downlinkEarfcn ?? 0;
      int bandnum = cell.lte?.bandLTE?.number ?? 0;

      String freqStr = '';
      if (bandnum == 48) {
        double freq = (earfcn - 55240) / 10 + 3550;
        freqStr = freq.toStringAsFixed(1);
      }
      int tac = cell.lte?.tac ?? 0;
      if (cell == primaryCellList[0]) Tac = tac.toString();
      int eci = cell.lte?.eci ?? 0;
      if (cell == primaryCellList[0]) Eci = eci.toString();
      int pci = cell.lte?.pci ?? 0;
      if (cell == primaryCellList[0]) Pci = pci.toString();
      String connected = cell.lte?.connectionStatus ?? 'null';
      if (connected.contains("PrimaryConnection()")) {
        connected = header;
      } else {
        connected = "Neighbor Cell:";
      }
      String mcc = cell.lte?.network?.mcc ?? '0';
      if (cell == primaryCellList[0]) Mcc = mcc;
      String mnc = cell.lte?.network?.mnc ?? '0';
      if (cell == primaryCellList[0]) Mnc = mnc;
      int cqi = cell.lte?.signalLTE?.cqi ?? 0;
      if (cell == primaryCellList[0]) Cqi = cqi.toString();
      double? rsrp = cell.lte?.signalLTE?.rsrp;
      double? rsrq = cell.lte?.signalLTE?.rsrq;
      if (cell == primaryCellList[0]) Rsrq = rsrq.toString();
      int? rssi = cell.lte?.signalLTE?.rssi;
      if (cell == primaryCellList[0]) Rssi = rssi.toString();
      double? snr = cell.lte?.signalLTE?.snr;
      if (cell == primaryCellList[0]) Snr = snr.toString();
      int? timeadv = cell.lte?.signalLTE?.timingAdvance;
      if (cell == primaryCellList[0]) Time_adv = timeadv.toString();
      lteParams +=
      '$connected\nBand = $bandnum (Fc $freqStr MHz, EARFCN $earfcn)\nNetwork = $mcc$mnc, ECI = $eci, PCI = $pci, TAC = $tac\nRSRP = $rsrp dBm, RSRQ = $rsrq dB, RSSI = $rssi dB\nSNR = $snr dB, CQI = $cqi, Time Adv = $timeadv\n\n';
      if (cell == primaryCellList[0]) Band = bandnum.toString();
      if (cell == primaryCellList[0]) Fc = freqStr.toString();
      if (cell == primaryCellList[0]) Earfcn = earfcn.toString();
      if (cell == primaryCellList[0]) Network = mcc.toString() + mnc.toString();
    }

    return lteParams;
  }

  void _setUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    // Request location permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) return;
    }

    // Start listening for location updates
    _locationSubscription =
        Geolocator.getPositionStream().listen((Position position) {
          setState(() {
            _latitude = position.latitude.toStringAsFixed(6);
            _longitude = position.longitude.toStringAsFixed(6);
            _altitude = position.altitude.toStringAsFixed(0);
            _accuracy = position.accuracy.toStringAsFixed(0);
          });
        });
  }

  void _setCellsInfo() async {
    final status = await Permission.location.request();
    final phoneStatus = await Permission.phone.request();

    String currentDBM = '';

    String? platformVersion = await CellInfo.getCellInfo;
    final body = json.decode(platformVersion!);

    cellsResponse = CellsResponse.fromJson(body);

    setState(() {
      primaryCellList = cellsResponse?.primaryCellList ?? [];
      neighboringCellList = cellsResponse?.neighboringCellList ?? [];
    });

    if (_latitude.isEmpty || _longitude.isEmpty) {
      //Wait until location values are available
      Timer(const Duration(milliseconds: 500), () {
         _setCellsInfo();
      });
      return;
    }

    for (var i = 0; i < primaryCellList.length; i++) {
      CellType primaryCell = primaryCellList[i];
      currentDBM += _formatLTEParams(primaryCell, header: 'Serving Cell:');
      double? rsrp = primaryCell.lte?.signalLTE?.rsrp;
      if (rsrp != null) {
        rsrpDisplayedForServingCell = rsrp.round();
      }
      if (i == 0) {
        Lat = _latitude;
        Long = _longitude;
      }
      currentDBM += 'Latitude: $_latitude\nLongitude: $_longitude\n\n';
    }

    if (neighboringCellList.isNotEmpty) {
      currentDBM += 'Neighboring Cells:\n';
      for (var i = 0; i < neighboringCellList.length; i++) {
        CellType neighborCell = neighboringCellList[i];
        currentDBM += _formatLTEParams(neighborCell);
        double? rsrp = neighborCell.lte?.signalLTE?.rsrp;
        if (rsrp != null) {
          if (i == 0)
            rsrpDisplayedForNeighborCell1 = rsrp.round();
          else
            rsrpDisplayedforNeighborCell2 = rsrp.round();
        }
        currentDBM += 'Latitude: $_latitude\nLongitude: $_longitude\n\n';
      }
    }

    setState(() {
      _cellInfo = currentDBM;
    });

    await _sendPayloadToAPI();
  }

  @override
  void initState() {
    super.initState();
    _setUserLocation();
    _setCellsInfo();
    Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      _setCellsInfo();
    });
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _sendPayloadToAPI() async {
    // Prepare device information
    String ip_address = '';
    String model = '';
    String android = '';
    String hardware = '';

    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
      );

      for (final interface in interfaces) {
        for (final address in interface.addresses) {
          if (address.type == InternetAddressType.IPv4) {
            ip_address = address.address;
          } else if (address.type == InternetAddressType.IPv6) {
            // Handle IPv6 address if needed
          }
        }
      }
    } catch (e) {
      print('Error getting device IP address: $e');
    }

    try {
      final deviceInfo = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo;

      try {
        androidInfo = await deviceInfo.androidInfo;
        model = androidInfo.model;
        android = androidInfo.version.release;
        hardware = androidInfo.board;
      } catch (e) {
        print('Error getting device information: $e');
      }
    } catch (e) {
      print('Error initializing deviceInfo: $e');
    }

    Map<String, dynamic> deviceInfo = {
      'model': model,
      'android': android,
      'hardware': hardware
    };

    try {
      double? latitude = double.tryParse(_latitude);
      double? longitude = double.tryParse(_longitude);

      if (latitude != null && longitude != null) {
        // The parsing was successful and the values are valid doubles
        // Continue processing with the parsed latitude and longitude
      } else {
        // The latitude or longitude values are not valid doubles
        print('Latitude: $_latitude');
        print('Longitude: $_longitude');
        print('Invalid latitude or longitude values');
      }
    } catch (e) {
      print('Error parsing latitude or longitude: $e');
    }
    // Prepare location information
    Map<String, dynamic> location = {
      'latitude': double.parse(_latitude),
      'longitude': double.parse(_longitude),
      'altitude': double.parse(_altitude),
      'accuracy': double.parse(_accuracy),
    };

    // Prepare LTE parameters
    Map<String, dynamic> lteParams = {
      'mcc': Mcc,
      'mnc': Mnc,
      'band': Band,
      'Fc': double.parse(Fc),
      'EarFcn': int.parse(Earfcn),
      'TimeAdv': int.parse(Time_adv),
      'tac': Tac,
      'eci': Eci,
      'pci': int.parse(Pci),
      'rsrp': rsrpDisplayedForServingCell,
      'rsrq': double.parse(Rsrq),
      'rssi': double.parse(Rssi),
      'snr': double.parse(Snr),
      'cqi': int.parse(Cqi),
    };

    // Prepare the payload
    Map<String, dynamic> payload = {
      'ip-address': ip_address,
      'device_information': {
        'device_info': deviceInfo,
        'location': location,
        'timestamp': DateTime.now().toIso8601String(),
      },
      'lte_params': lteParams,
    };

    // Convert payload to JSON
    String jsonPayload = json.encode(payload);
    print('BEFORE SENDING JSON PAYLOAD TO API!!!');
    try {
      // Send the JSON payload to your API
      final response = await http.post(
        Uri.parse('http://35.232.205.68/data'),
        headers: {'Content-Type': 'application/json'},
        body: jsonPayload,
      );

      if (response.statusCode == 200) {
        print('JSON payload sent successfully');
      } else {
        print('Failed to send JSON payload. Error: ${response.reasonPhrase}');
      }
    } catch (e) {
      //Handle connection error or other exceptions
      print('Error sending payload to API: $e');
    }

  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Raw'),
              Tab(text: 'Gauges'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Page 1
            Raw(
              primaryCellList: primaryCellList,
              neighboringCellList: neighboringCellList,
              latitude: _latitude,
              longitude: _longitude,
              altitude: _altitude,
              accuracy: _accuracy,
            ),
            Gauges(
                rsrpDisplayedForServingCell: rsrpDisplayedForServingCell,
                rsrpDisplayedForNeighborCell1: rsrpDisplayedForNeighborCell1,
                rsrpDisplayedforNeighborCell2: rsrpDisplayedforNeighborCell2,
                cellInfo: _cellInfo,
                latitude: _latitude,
                longitude: _longitude,
                band: Band,
                fc: Fc,
                earfcn: Earfcn,
                network: Network,
                eci: Eci,
                pci: Pci,
                tac: Tac,
                rsrq: Rsrq,
                rssi: Rssi,
                snr: Snr,
                cqi: Cqi,
                timeadv: Time_adv
            ),
          ],
        ),
      ),
    );
  }
}
