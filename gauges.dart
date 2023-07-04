import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class Gauges extends StatelessWidget {
  final int rsrpDisplayedForServingCell;
  final int rsrpDisplayedForNeighborCell1;
  final int rsrpDisplayedforNeighborCell2;
  final String cellInfo;
  final String latitude;
  final String longitude;
  final String band;
  final String fc;
  final String earfcn;
  final String network;
  final String eci;
  final String pci;
  final String tac;
  final String rsrq;
  final String rssi;
  final String snr;
  final String cqi;
  final String timeadv;

  const Gauges({
    Key? key,
    required this.rsrpDisplayedForServingCell,
    required this.rsrpDisplayedForNeighborCell1,
    required this.rsrpDisplayedforNeighborCell2,
    required this.cellInfo,
    required this.latitude,
    required this.longitude,
    required this.band,
    required this.fc,
    required this.earfcn,
    required this.network,
    required this.eci,
    required this.pci,
    required this.tac,
    required this.rsrq,
    required this.rssi,
    required this.snr,
    required this.cqi,
    required this.timeadv,

  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        // Rest of the code for Page 1
        Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Column(
              children: <Widget>[
                const SizedBox(height: 64),
                Transform.translate(
                  offset: Offset(0, -15),
                  child: Transform.scale(
                      scale: 0.4,
                      child: Text(
                        'RSRP:',
                        style: TextStyle(fontSize: 50),
                      ),
                  ),
                ),
              ],
            ),
            Positioned(
              left: 50,
              right: 50,
              child: Container(
                height: 150,
                child: SfRadialGauge(
                  axes: <RadialAxis>[
                    RadialAxis(
                      minimum: -140,
                      maximum: -40,
                      ranges: <GaugeRange>[
                        GaugeRange(
                          startValue: -140,
                          endValue: -110,
                          color: Colors.red,
                        ),
                        GaugeRange(
                          startValue: -110,
                          endValue: -80,
                          color: Colors.orange,
                        ),
                        GaugeRange(
                          startValue: -80,
                          endValue: -40,
                          color: Colors.green,
                        ),
                      ],
                      pointers: <GaugePointer>[
                        NeedlePointer(
                            value: rsrpDisplayedForServingCell.toDouble()),
                      ],
                      annotations: <GaugeAnnotation>[
                        GaugeAnnotation(
                          widget: Container(
                            alignment: Alignment.center,
                            child: Transform.translate(
                              offset: Offset(0, 10),
                              child: Text(
                                rsrpDisplayedForServingCell.toDouble().toString(),
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold
                                ),
                              ),
                            ),

                          ),
                          angle: 90,
                          positionFactor: 0.5,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 30, // Adjust the top value as needed
              left: 16,
              child: Column(
                children: [
                  SizedBox(height: 8),
                  Container(
                    width: 110,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Band: $band, Fc: $fc\nEarfcn: $earfcn, Network: $network\nEci: $eci, Pci: $pci, Tac: $tac',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 30, // Adjust the top value as needed
              right: 7,
              child: Column(
                children: [
                  SizedBox(height: 8),
                  Container(
                    width: 110,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                        child: Text(
                          'Rsrq: $rsrq, Rssi: $rssi, Snr: $snr, Cqi: $cqi\nTime Adv: $timeadv, Latitude: $latitude\nLongitude: $longitude',
                          style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                // Widget to display content on the left side
                SizedBox(
                  width: 150,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Add your content here
                      Text(
                        '',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                // Widget to display content on the right side
                SizedBox(
                  width: 150,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Add your content here
                      Text(
                        '',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Text(
                  'LTE Params:',
                  style: TextStyle(fontSize: 15),
                ),
                SizedBox(height: 8),
                Text(
                  cellInfo,
                  style: TextStyle(fontSize: 10),
                ),
                Divider(
                  color: Colors.black,
                  thickness: 1.0,
                  height: 16.0,
                  indent: 16.0,
                  endIndent: 16.0,
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        Text(
                          'Neighbor #1',
                          style: TextStyle(fontSize: 12),
                        ),
                        SizedBox(height: 8),
                        Container(
                          width: 150,
                          height: 150,
                          child: SfRadialGauge(
                            axes: <RadialAxis>[
                              RadialAxis(
                                minimum: -140,
                                maximum: -40,
                                ranges: <GaugeRange>[
                                  GaugeRange(
                                    startValue: -140,
                                    endValue: -110,
                                    color: Colors.red,
                                  ),
                                  GaugeRange(
                                    startValue: -110,
                                    endValue: -80,
                                    color: Colors.orange,
                                  ),
                                  GaugeRange(
                                    startValue: -80,
                                    endValue: -40,
                                    color: Colors.green,
                                  ),
                                ],
                                pointers: <GaugePointer>[
                                  NeedlePointer(
                                      value: rsrpDisplayedForNeighborCell1
                                          .toDouble()),
                                ],
                                annotations: <GaugeAnnotation>[
                                  GaugeAnnotation(
                                    widget: Container(
                                      alignment: Alignment.center,
                                      child: Text(
                                        rsrpDisplayedForNeighborCell1
                                            .toDouble()
                                            .toString(),
                                        style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    angle: 90,
                                    positionFactor: 0.5,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: 16),
                    Column(
                      children: [
                        Text(
                          'Neighbor #2',
                          style: TextStyle(fontSize: 12),
                        ),
                        SizedBox(height: 8),
                        Container(
                          width: 150,
                          height: 150,
                          child: SfRadialGauge(
                            axes: <RadialAxis>[
                              RadialAxis(
                                minimum: -140,
                                maximum: -40,
                                ranges: <GaugeRange>[
                                  GaugeRange(
                                    startValue: -140,
                                    endValue: -110,
                                    color: Colors.red,
                                  ),
                                  GaugeRange(
                                    startValue: -110,
                                    endValue: -80,
                                    color: Colors.orange,
                                  ),
                                  GaugeRange(
                                    startValue: -80,
                                    endValue: -40,
                                    color: Colors.green,
                                  ),
                                ],
                                pointers: <GaugePointer>[
                                  NeedlePointer(
                                      value: rsrpDisplayedforNeighborCell2
                                          .toDouble()),
                                ],
                                annotations: <GaugeAnnotation>[
                                  GaugeAnnotation(
                                    widget: Container(
                                      alignment: Alignment.center,
                                      child: Text(
                                        rsrpDisplayedforNeighborCell2
                                            .toDouble()
                                            .toString(),
                                        style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    angle: 90,
                                    positionFactor: 0.5,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
