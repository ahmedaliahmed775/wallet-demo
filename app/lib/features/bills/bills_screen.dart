import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../repositories/bills_repository.dart';
import '../../models/bill_service_model.dart';
import 'pay_bill_screen.dart';

class BillsScreen extends StatefulWidget {
  const BillsScreen({super.key});

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  List<BillServiceModel> _services = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    try {
      final repo = BillsRepository();
      final result = await repo.getBillServices();
      setState(() {
        _services = result
            .map((s) => BillServiceModel.fromJson(s as Map<String, dynamic>))
            .toList();
        if (_services.isEmpty) {
          _services = [
            const BillServiceModel(id: '1', nameAr: 'إنترنت', nameEn: 'Internet', serviceCode: 'INTERNET', category: 'اتصالات'),
            const BillServiceModel(id: '2', nameAr: 'هاتف ثابت', nameEn: 'Landline', serviceCode: 'LANDLINE', category: 'اتصالات'),
            const BillServiceModel(id: '3', nameAr: 'كهرباء', nameEn: 'Electricity', serviceCode: 'ELECTRICITY', category: 'مرافق'),
            const BillServiceModel(id: '4', nameAr: 'ماء', nameEn: 'Water', serviceCode: 'WATER', category: 'مرافق'),
          ];
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _services = [
          const BillServiceModel(id: '1', nameAr: 'إنترنت', nameEn: 'Internet', serviceCode: 'INTERNET', category: 'اتصالات'),
          const BillServiceModel(id: '2', nameAr: 'هاتف ثابت', nameEn: 'Landline', serviceCode: 'LANDLINE', category: 'اتصالات'),
          const BillServiceModel(id: '3', nameAr: 'كهرباء', nameEn: 'Electricity', serviceCode: 'ELECTRICITY', category: 'مرافق'),
          const BillServiceModel(id: '4', nameAr: 'ماء', nameEn: 'Water', serviceCode: 'WATER', category: 'مرافق'),
        ];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('سداد الفواتير')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _services.isEmpty
              ? const Center(child: Text('لا توجد خدمات متاحة'))
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  itemCount: _services.length,
                  itemBuilder: (context, index) {
                    final service = _services[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PayBillScreen(service: service),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.receipt_long, color: AppColors.primary),
                            ),
                            const SizedBox(height: 12),
                            Text(service.nameAr, style: AppTextStyles.titleMedium, textAlign: TextAlign.center),
                            if (service.category != null)
                              Text(service.category!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
