import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_travel_app/utils/import_tour_packages.dart';

/// Screen để import tour packages vào Firestore (dùng cho testing/admin)
class ImportTourPackagesScreen extends StatefulWidget {
  const ImportTourPackagesScreen({super.key});

  @override
  State<ImportTourPackagesScreen> createState() =>
      _ImportTourPackagesScreenState();
}

class _ImportTourPackagesScreenState extends State<ImportTourPackagesScreen> {
  bool _isImporting = false;
  String? _importResult;
  int _successCount = 0;
  int _errorCount = 0;

  Future<void> _importTourPackages() async {
    setState(() {
      _isImporting = true;
      _importResult = null;
      _successCount = 0;
      _errorCount = 0;
    });

    try {
      // Đọc file JSON
      final jsonString =
          await rootBundle.loadString('assets/data/tour_packages.json');
      final List<dynamic> jsonList = json.decode(jsonString);

      int success = 0;
      int error = 0;

      for (final jsonData in jsonList) {
        try {
          await TourPackageImporter.importSingleTour(
            jsonData as Map<String, dynamic>,
          );
          success++;
        } catch (e) {
          error++;
          print('❌ Lỗi import tour: ${jsonData['title'] ?? 'Unknown'}: $e');
        }
      }

      setState(() {
        _isImporting = false;
        _successCount = success;
        _errorCount = error;
        _importResult = '✅ Import hoàn tất!\n'
            'Thành công: $success\n'
            'Lỗi: $error';
      });
    } catch (e) {
      setState(() {
        _isImporting = false;
        _importResult = '❌ Lỗi import: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Tour Packages'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Import Tour Packages',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Import tour packages từ file JSON vào Firestore',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isImporting ? null : _importTourPackages,
              icon: _isImporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_file),
              label: Text(_isImporting ? 'Đang import...' : 'Import Tour Packages'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
            if (_importResult != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _errorCount > 0 ? Colors.red[50] : Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _errorCount > 0 ? Colors.red : Colors.green,
                  ),
                ),
                child: Text(
                  _importResult!,
                  style: TextStyle(
                    color: _errorCount > 0 ? Colors.red[900] : Colors.green[900],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

