// ignore_for_file: avoid_print, prefer_const_constructors
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../utils/extra.dart';

class DeviceScreen extends StatefulWidget {
  final BluetoothDevice device;

  const DeviceScreen({Key? key, required this.device}) : super(key: key);

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  int? _rssi;
  BluetoothConnectionState _connectionState =
      BluetoothConnectionState.disconnected;
  List<BluetoothService> _services = [];
  bool _isDiscoveringServices = false;
  double? _weight;
  double? _lastWeight;
  Timer? _timer;
  Color backgroundColor = Colors.black;
  Color textColor = Colors.white;

  late StreamSubscription<BluetoothConnectionState>
      _connectionStateSubscription;
  late StreamSubscription<bool> _isConnectingSubscription;
  late StreamSubscription<bool> _isDisconnectingSubscription;
  late StreamSubscription<int> _mtuSubscription;
  late BluetoothCharacteristic characteristic;
  @override
  void initState() {
    super.initState();
    _connectionStateSubscription =
        widget.device.connectionState.listen((state) async {
      _connectionState = state;
      if (state == BluetoothConnectionState.connected) {
        _services = [];
      }
      if (state == BluetoothConnectionState.connected && _rssi == null) {
        _rssi = await widget.device.readRssi();
        print('_rssi=$_rssi');
      }
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _connectionStateSubscription.cancel();
    _mtuSubscription.cancel();
    _isConnectingSubscription.cancel();
    _isDisconnectingSubscription.cancel();
    super.dispose();
  }

  bool get isConnected {
    return _connectionState == BluetoothConnectionState.connected;
  }

  Future onConnectPressed() async {
    try {
      await widget.device.connectAndUpdateStream();
    } catch (e) {
      if (e is FlutterBluePlusException &&
          e.code == FbpErrorCode.connectionCanceled.index) {
        // ignore connections canceled by the user
      } else {}
    }
  }

  Future onCancelPressed() async {
    try {
      await widget.device.disconnectAndUpdateStream(queue: false);
    } catch (e) {
      print(e);
    }
  }

  Future onDisconnectPressed() async {
    try {
      await widget.device.disconnectAndUpdateStream();
    } catch (e) {
      print(e);
    }
  }

  Future onDiscoverServicesPressed() async {
    //ฟังก์ชั่นเริ่มทำงาน
    if (mounted) {
      setState(() {
        _isDiscoveringServices = true;
      });
    }
    try {
      _services = await widget.device.discoverServices();
      if (_services.isNotEmpty) {
        characteristic = _services.last.characteristics[0];
        _services.last.characteristics[0].lastValueStream.listen((value) {
          Uint8List dataX = Uint8List(0);
          dataX = Uint8List.fromList([...dataX, ...value]);
          var text = String.fromCharCodes(dataX);
          var currentWeight = double.tryParse(text.trim()) ?? 0.0;

          if (_lastWeight == currentWeight) {
            _timer?.cancel();
            _timer = Timer(const Duration(seconds: 1), () {
              setState(() {
                textColor = Colors.green;
                backgroundColor = Colors.white;
              });
            });
          } else {
            _timer?.cancel();
            _lastWeight = currentWeight;
            setState(() {
              textColor = Colors.white;
              backgroundColor = Colors.black;
            });
          }
          setState(() {
            _weight = currentWeight;
          });
          print(_lastWeight == currentWeight);
          print("weight =${text.trim()}");
        });
        onSubscribePressed();
      }
    } catch (e) {
      print(e);
    }
    if (mounted) {
      setState(() {
        _isDiscoveringServices = false;
      });
    }
  }

  Future onRequestMtuPressed() async {
    try {
      await widget.device.requestMtu(223, predelay: 0);
    } catch (e) {
      print(e);
    }
  }

  Widget buildSpinner(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(14.0),
      child: AspectRatio(
        aspectRatio: 1.0,
        child: CircularProgressIndicator(
          backgroundColor: Colors.black12,
          color: Colors.black26,
        ),
      ),
    );
  }

  Widget buildRemoteId(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text('${widget.device.remoteId}'),
    );
  }

  Widget buildGetServices(BuildContext context) {
    return IndexedStack(
      index: (_isDiscoveringServices) ? 1 : 0,
      children: <Widget>[
        TextButton(
          onPressed: onDiscoverServicesPressed,
          child: const Text("Get Services"),
        ),
        const IconButton(
          icon: SizedBox(
            width: 18.0,
            height: 18.0,
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Colors.grey),
              ),
            ),
          ),
          onPressed: null,
        )
      ],
    );
  }

  Future onSubscribePressed() async {
    try {
      await characteristic.setNotifyValue(characteristic.isNotifying == false);
      if (characteristic.properties.read) {
        await characteristic.read();
      }
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.device.platformName),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Container(
                height: 200,
                width: double.infinity,
                color: backgroundColor,
                child: Center(
                  child: Text(
                    "$_weight",
                    style: TextStyle(color: textColor, fontSize: 60),
                  ),
                ),
              ),
              buildGetServices(context),
            ],
          ),
        ),
      ),
    );
  }
}
