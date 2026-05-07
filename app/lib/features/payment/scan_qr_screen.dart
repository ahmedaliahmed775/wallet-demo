import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({super.key});

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مسح QR Code')),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.black,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primary, width: 3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.qr_code_scanner,
                          size: 80,
                          color: Colors.white54,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'وجه الكاميرا نحو رمز QR',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontFamily: 'NotoSansArabic',
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _simulateScan(),
                      icon: const Icon(Icons.sim_card_download),
                      label: const Text('محاكاة المسح'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.surface,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, color: AppColors.textSecondary, size: 20),
                SizedBox(width: 8),
                Text(
                  'في المحاكاة، اضغط "محاكاة المسح"',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontFamily: 'NotoSansArabic',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _simulateScan() {
    final qrData = '{"posNumber":"POS001","amount":0,"currency":"YER","userId":"merchant-1","timestamp":${DateTime.now().millisecondsSinceEpoch}}';
    Navigator.of(context).pop(qrData);
  }
}
