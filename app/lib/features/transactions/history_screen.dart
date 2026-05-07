import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../blocs/transaction/transaction_bloc.dart';
import '../../blocs/transaction/transaction_event.dart';
import '../../blocs/transaction/transaction_state.dart';
import '../../repositories/transaction_repository.dart';
import '../../widgets/transaction_item.dart';
import 'receipt_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String? _selectedType;
  final List<Map<String, String>> _filterTabs = [
    {'label': 'الكل', 'type': ''},
    {'label': 'دفع', 'type': 'PAYMENT'},
    {'label': 'تحويل', 'type': 'TRANSFER'},
    {'label': 'سحب', 'type': 'CASH_OUT'},
    {'label': 'استرجاع', 'type': 'REFUND'},
  ];

  @override
  void initState() {
    super.initState();
    context.read<TransactionBloc>().add(const TransactionHistoryRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('سجل العمليات')),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _filterTabs.map((tab) {
                final isSelected = (_selectedType ?? '') == tab['type'];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(tab['label']!),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        _selectedType = tab['type']!.isEmpty ? null : tab['type'];
                      });
                      context.read<TransactionBloc>().add(
                            TransactionHistoryRequested(
                              type: _selectedType,
                            ),
                          );
                    },
                    selectedColor: AppColors.primary.withValues(alpha: 0.2),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: BlocBuilder<TransactionBloc, TransactionState>(
              builder: (context, state) {
                if (state is TransactionLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is TransactionError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: AppColors.error),
                        const SizedBox(height: 8),
                        Text(state.message, style: AppTextStyles.bodyMedium),
                      ],
                    ),
                  );
                }
                if (state is TransactionLoaded) {
                  if (state.transactions.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long, size: 48, color: AppColors.textHint),
                          const SizedBox(height: 8),
                          Text(
                            'لا توجد عمليات بعد',
                            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<TransactionBloc>().add(
                            TransactionHistoryRequested(type: _selectedType),
                          );
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: state.transactions.length,
                      itemBuilder: (context, index) {
                        final tx = state.transactions[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: TransactionItem(
                            transaction: tx,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ReceiptScreen(transactionId: tx.id),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}
