// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class _StreamViewState extends StatefulWidget {
  final BluetoothCharacteristic characteristic;
  const _StreamViewState({key, required this.characteristic}) : super(key: key);

  @override
  State<_StreamViewState> createState() => _StreamViewStateState();
}

class _StreamViewStateState extends State<_StreamViewState> {
  List<int> values = [];

  late StreamSubscription<List<int>> lastValueSubscription;
  @override
  void initState() {
    super.initState();
    lastValueSubscription = widget.characteristic.lastValueStream.listen((v) {
      values = v;
      if (mounted) {
        setState(() {});
      }
    });
  }

  BluetoothCharacteristic get c => widget.characteristic;
  Future onReadPressed() async {
    var data = values;
    Uint8List dataX = Uint8List(0);
    dataX = Uint8List.fromList([...dataX, ...data]);
    var text = String.fromCharCodes(dataX);
    try {
      await c.read();
      print('e==$text');
    } catch (e) {
      print('e onReadPresse ===$e');
    }
  }

  Future onSubscribePressed() async {
    try {
      await c.setNotifyValue(c.isNotifying == false);
      if (c.properties.read) {
        await c.read();
      }
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('e onSubscribePressed===$e');
    }
  }

  Widget buildReadButton(BuildContext context) {
    return TextButton(
        child: const Text("Read"),
        onPressed: () async {
          await onReadPressed();
          if (mounted) {
            setState(() {});
          }
        });
  }

  @override
  void dispose() {
    lastValueSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('data'),
    );
  }
}
