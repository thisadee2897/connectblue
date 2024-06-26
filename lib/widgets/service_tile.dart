import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import "characteristic_tile.dart";

class ServiceTile extends StatelessWidget {
  final BluetoothService service;
  final List<CharacteristicTile> characteristicTiles;

  const ServiceTile({Key? key, required this.service, required this.characteristicTiles}) : super(key: key);

  Widget buildUuid(BuildContext context) {
    String uuid = service.uuid.str.toUpperCase();
    return Text(uuid, style: const TextStyle(fontSize: 16));
  }

  @override
  Widget build(BuildContext context) {
    return characteristicTiles.isNotEmpty
        ? ExpansionTile(
            title:  buildUuid(context),
            children: characteristicTiles,
          )
        : Container();
  }
}