// Renders the launcher icon artwork from the brand monogram (Figma 11.01:
// Georgia "É"). Run with:  flutter test tool/icon/render_icon_test.dart
// Outputs assets/icon/app_icon.png (full icon) and
// assets/icon/app_icon_foreground.png (Android adaptive foreground).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _cream = Color(0xFFFAF6F0);
const _rose = Color(0xFFB76E79);
const _roseDeep = Color(0xFF985663);
const _size = 1024.0;

Widget _mark({required double scale}) => Center(
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        'É',
        textDirection: TextDirection.ltr,
        style: TextStyle(
          fontFamily: 'Georgia',
          fontSize: 560 * scale,
          height: 1,
          color: _roseDeep,
        ),
      ),
      SizedBox(height: 18 * scale),
      Container(width: 150 * scale, height: 8 * scale, color: _rose),
    ],
  ),
);

Future<void> _render(WidgetTester tester, Widget child, String path) async {
  final key = GlobalKey();
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: RepaintBoundary(
          key: key,
          child: SizedBox.square(dimension: _size, child: child),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File(path)
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

void main() {
  testWidgets('render launcher icon artwork', (tester) async {
    tester.view.physicalSize = const Size(_size, _size);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final loader = FontLoader('Georgia')
      ..addFont(
        Future.value(
          ByteData.sublistView(
            File('assets/fonts/georgia.ttf').readAsBytesSync(),
          ),
        ),
      );
    await loader.load();

    // Full-bleed icon (iOS, legacy Android, web).
    await _render(
      tester,
      ColoredBox(color: _cream, child: _mark(scale: 1)),
      'assets/icon/app_icon.png',
    );
    // Adaptive foreground: transparent. flutter_launcher_icons adds a 16% inset,
    // which keeps the mark inside the 66% safe zone.
    await _render(
      tester,
      _mark(scale: 0.92),
      'assets/icon/app_icon_foreground.png',
    );
  });
}
