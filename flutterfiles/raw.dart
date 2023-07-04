import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cell_info/models/common/cell_type.dart';
import 'package:device_info/device_info.dart';
import 'package:intl/intl.dart';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';

class Raw extends StatefulWidget {
  final List<CellType> primaryCellList;
  final List<CellType> neighboringCellList;
  final String latitude;
  final String longitude;
  final String altitude;
  final String accuracy;

  const Raw({
    Key? key,
    required this.primaryCellList,
    required this.neighboringCellList,
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.accuracy,
  }) : super(key: key);

  @override
  _RawState createState() => _RawState();
}

class _RawState extends State<Raw> {
  String? deviceId;
  String? ipAddress;
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  bool isInAirplaneMode = false;

  Future<bool> isAirplaneModeOn() async {
    final status = await Permission.phone.status;
    if (!status.isGranted) {
      final result = await Permission.phone.request();
      if (result.isDenied || result.isPermanentlyDenied) {
        // Permission denied, handle accordingly
        return false;
      }
    }

    final connectivityResult = await (Connectivity().checkConnectivity());
    return connectivityResult == ConnectivityResult.none;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (deviceId == null) {
      getDeviceId(context).then((value) {
        setState(() {
          deviceId = value;
        });
      });
    }

    if (ipAddress == null) {
      getDeviceIpAddress().then((value) {
        setState(() {
          ipAddress = value;
        });
      });
    }

    checkAirplaneMode();

  }

  void checkAirplaneMode() async {
    final isOn = await isAirplaneModeOn();
    setState(() {
      isInAirplaneMode = isOn;
    });

    if (isOn) {
      Fluttertoast.showToast(msg: 'IN AIRPLANE MODE');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(13.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: widget.primaryCellList.length,
                  itemBuilder: (context, index) {
                    CellType cell = widget.primaryCellList[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 8),
                        _buildLTEParamsTable(
                          context,
                          cell,
                        ),
                      ],
                    );
                  },
                ),
                SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLTEParamsTable(BuildContext context, CellType cell) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Device Info:',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        _buildDeviceInfoTable(context),
        SizedBox(height: 8),
        if (!isInAirplaneMode)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Serving Cell:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (widget.primaryCellList.isEmpty) Text('No serving cell found.'),
              if (widget.primaryCellList.isNotEmpty)
                _buildCellTable(context, widget.primaryCellList),
              Text(
                'Neighboring Cells:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              _buildCellTable(context, widget.neighboringCellList),
            ],
          ),
        if (isInAirplaneMode)
          Text(
            'In Airplane Mode',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
      ],
    );
  }

  Widget _buildDeviceInfoTable(BuildContext context) {
    return FutureBuilder<dynamic>(
      future: getDeviceInfo(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final deviceInfo = snapshot.data!;
          String model = '';
          String operatingSystem = '';
          String operatingSystemVersion = '';
          String hardware = '';

          if (deviceInfo is AndroidDeviceInfo) {
            model = deviceInfo.model;
            operatingSystem = 'Android';
            operatingSystemVersion = deviceInfo.version.release;
            hardware = deviceInfo.hardware;
          } else if (deviceInfo is IosDeviceInfo) {
            model = deviceInfo.model;
            operatingSystem = 'iOS';
            operatingSystemVersion = deviceInfo.systemVersion;
            hardware = deviceInfo.utsname.machine;
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(0),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Model: $model',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '$operatingSystem: $operatingSystemVersion',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Hardware: $hardware',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Lat: ${widget.latitude}',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Long: ${widget.longitude}',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Alt: ${widget.altitude}m',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'IPAddress: ${ipAddress ?? 'Unavailable'}',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Timestamp: ${getCurrentTimestamp()}',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Accuracy: ${widget.accuracy}m',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8),
            ],
          );
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          return CircularProgressIndicator();
        }
      },
    );
  }

  //Use this _buildCellTable version instead that actually displays table
  Widget _buildCellTable(BuildContext context, List<CellType> cellList) {
    bool printEmpty = true;
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: cellList.length,
      itemBuilder: (context, index) {
        CellType cell = cellList[index];
        String band = cell.lte?.bandLTE?.number?.toString() ?? '';
        print('Band: $band');
        String earfcn = cell.lte?.bandLTE?.downlinkEarfcn?.toString() ?? '';
        String tac = cell.lte?.tac?.toString() ?? '';
        String eci = cell.lte?.eci?.toString() ?? '';
        String pci = cell.lte?.pci?.toString() ?? '';
        //String connected = cell.lte?.connectionStatus?.contains('PrimaryConnection()') == true ? 'Serving Cell' : '';
        String mcc = cell.lte?.network?.mcc ?? '';
        String mnc = cell.lte?.network?.mnc ?? '';
        String cqi = cell.lte?.signalLTE?.cqi?.toString() ?? '';
        String rsrp = cell.lte?.signalLTE?.rsrp?.toString() ?? '';
        String rsrq = cell.lte?.signalLTE?.rsrq?.toString() ?? '';
        String rssi = cell.lte?.signalLTE?.rssi?.toString() ?? '';
        String snr = cell.lte?.signalLTE?.snr?.toString() ?? '';
        String timeadv = cell.lte?.signalLTE?.timingAdvance?.toString() ?? '';
        String freqStr = '';
        String fc = '';
        if (band.isNotEmpty) {
          if (int.parse(band) == 48) {
            double freq = (double.parse(earfcn) - 55240) / 10 + 3550;
            freqStr = freq.toStringAsFixed(1);
          }
          fc = freqStr.toString();
        } else {
          return Text('');
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(0),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'MCC: $mcc',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'MNC: $mnc',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Band: $band',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Fc: $fc',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'EARFCN: $earfcn',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'TimeAdv: $timeadv',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'TAC: $tac',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'ECI: $eci',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'PCI: $pci',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'RSRP: $rsrp',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'RSRQ: $rsrq',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'RSSI: $rssi',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'SNR: $snr',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'CQI: $cqi',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      Expanded(
                        child: Text(''),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 8),
          ],
        );
      },
    );
  }

  TableRow _buildTableRow(String title, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(value),
        ),
      ],
    );
  }

  String getIMEI(BuildContext context) {
    if (Theme.of(context).platform == TargetPlatform.android) {
      return 'IMEI: Not supported on Android';
    } else {
      return 'IMEI: Not supported on iOS';
    }
  }

  String getIMSI(BuildContext context) {
    if (Theme.of(context).platform == TargetPlatform.android) {
      return 'IMSI: Not supported on Android';
    } else {
      return 'IMSI: Not supported on iOS';
    }
  }

  String getCurrentTimestamp() {
    // Get the current timestamp
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
    return formattedDate;
  }

  Future<dynamic> getDeviceInfo() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Theme.of(context).platform == TargetPlatform.android) {
      return deviceInfo.androidInfo;
    } else if (Theme.of(context).platform == TargetPlatform.iOS) {
      return deviceInfo.iosInfo;
    }
    return null;
  }

  Future<String?> getDeviceIpAddress() async {
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
      );
      String IPv4Address = "";
      String IPv6Address = "";

      for (final interface in interfaces) {
        for (final address in interface.addresses) {
          print(address);
          if (address.type == InternetAddressType.IPv4) {
            IPv4Address = address.address;
          } else if (address.type == InternetAddressType.IPv6) {
            IPv6Address = address.address;
          }
          //return address.address;
        }
      }
      return '$IPv4Address $IPv6Address';
    } catch (e) {
      print('Error getting device IP address: $e');
    }
    return null;
  }

  Future<String> getDeviceId(BuildContext context) async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Theme.of(context).platform == TargetPlatform.android) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      return androidInfo.androidId;
    } else if (Theme.of(context).platform == TargetPlatform.iOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor;
    }
    return 'Unknown';
  }
}

