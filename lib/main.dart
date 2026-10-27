import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ar');
  if (kReleaseMode) {
    // A widget that fails to build degrades to a small notice instead of a
    // grey block; the rest of the screen keeps working.
    ErrorWidget.builder = (_) => const Padding(
      padding: EdgeInsets.all(12),
      child: Text(
        'تعذّر عرض هذا الجزء',
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
        style: TextStyle(color: Color(0xFF7D716A), fontSize: 12),
      ),
    );
  }
  runApp(const EloraApp());
}
