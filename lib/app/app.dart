import 'package:dicom_viewer/app/router.dart';
import 'package:dicom_viewer/app/theme.dart';
import 'package:flutter/material.dart';

class DicomViewerApp extends StatelessWidget {
  const DicomViewerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DICOM Viewer',
      debugShowCheckedModeBanner: false,
      theme: buildDicomViewerTheme(),
      home: const AppRouter(),
    );
  }
}
