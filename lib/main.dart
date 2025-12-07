import 'package:flutter/cupertino.dart'
    show CupertinoThemeData, CupertinoTextThemeData;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:led/scan_&_connect/page.dart' show ScanPage;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.interTextTheme(),
        cupertinoOverrideTheme: CupertinoThemeData(
          textTheme: CupertinoTextThemeData(textStyle: GoogleFonts.inter()),
        ),
      ),
      home: const ScanPage(),
    );
  }
}

const double headerFont = 20;
const double bodyFont = 17;
const double secondaryFont = 15;
const double captionsFont = 13;
