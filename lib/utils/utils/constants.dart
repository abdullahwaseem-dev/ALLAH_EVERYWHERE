import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

final String baseUrl =
    'https://holla-gorilla-apis-production-567e.up.railway.app';

String mapToString(Map<String, dynamic> x) {
  String e = '';
  var y = x.entries.map((e) => e.value);
  for (String str in y) {
    e = e + ' $str';
  }
  return e;
}

Widget buttonCircularProgressIndicator() {
  return const SizedBox(
    height: 16,
    width: 16,
    child: CircularProgressIndicator(
      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
    ),
  );
}

Future<File> getImageFileFromAssets(String assetPath) async {
  final byteData = await rootBundle.load(assetPath);

  final file = File(
      '${(await getTemporaryDirectory()).path}/${path.basename(assetPath)}');
  await file.writeAsBytes(byteData.buffer
      .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));

  return file;
}
