import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../repositories/transaction_repository.dart';
import '../../models/transaction_model.dart';

// ─── Events ───────────────────────────────────────────────────────────────────

abstract class TransactionEvent extends Equatable {
  const TransactionEvent();
  @override
  List<Object?> get props => [];
}

class LoadTransactions extends TransactionEvent {
  final int page;
  final int limit;
  final String? type;
  final String? status;

  const LoadTransactions({
    this.page = 1,
    this.limit = 20,
    this.type,
    this.status,
  });

  @override
  List<Object?> get props => [page, limit, type, status];
}

class TransactionHistoryRequested extends TransactionEvent {
  final int page;
  final int limit;
  final String? type;
  final String? status;

  const TransactionHistoryRequested({
    this.page = 1,
    this.limit = 20,
    this.type,
    this.status,
  });

  @override
  List<Object?> get props => [page, limit, type, status];
}

class RefreshTransactions extends TransactionEvent {
  final String? type;
  final String? status;

  const RefreshTransactions({this.type, this.status});

  @override
  List<Object?> get props => [type, status];
}

class FilterTransactions extends TransactionEvent {
  final String? type;
  final String? status;

  const FilterTransactions({this.type, this.status});

  @override
  List<Object?> get props => [type, status];
}

// ─── States ───────────────────────────────────────────────────────────────────

abstract class TransactionState extends Equatable {
  const TransactionState();
  @override
  List<Object?> get props => [];
}

class TransactionInitial extends TransactionState {}

class TransactionLoading extends TransactionState {}

class TransactionLoaded extends TransactionState {
  final List<TransactionModel> transactions;
  final int page;
  final int totalPages;
  final int total;

  const TransactionLoaded({
    required this.transactions,
    this.page = 1,
    this.totalPages = 1,
    this.total = 0,
  });

  @override
  List<Object?> get props => [transactions, page, totalPages, total];
}

/// Alias for TransactionLoaded so screens can use either name.
typedef TransactionHistoryLoaded = TransactionLoaded;

class TransactionError extends TransactionState {
  final String message;
  const TransactionError({required this.message});

  @override
  List<Object?> get props => [message];
}

// ─── Bloc ─────────────────────────────────────────────────────────────────────

class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final TransactionRepository _transactionRepository;

  TransactionBloc({required TransactionRepository transactionRepository})
      : _transactionRepository = transactionRepository,
        super(TransactionInitial()) {
    on<LoadTransactions>(_onLoadTransactions);
    on<TransactionHistoryRequested>(_onLoadTransactions);
    on<RefreshTransactions>(_onRefreshTransactions);
    on<FilterTransactions>(_onFilterTransactions);
  }

  Future<void> _onLoadTransactions(
    TransactionEvent event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionLoading());
    try {
      int page = 1;
      int limit = 20;
      String? type;
      String? status;

      if (event is LoadTransactions) {
        page = event.page;
        limit = event.limit;
        type = event.type;
        status = event.status;
      } else if (event is TransactionHistoryRequested) {
        page = event.page;
        limit = event.limit;
        type = event.type;
        status = event.status;
      }

      final result = await _transactionRepository.getTransactionHistory(
        page: page,
        limit: limit,
        type: type,
        status: status,
      );
      final transactions = _parseTransactions(result);
      final pagination = _parsePagination(result);
      emit(TransactionLoaded(
        transactions: transactions,
        page: (pagination['page'] as int?) ?? 1,
        totalPages: (pagination['totalPages'] as int?) ?? 1,
        total: (pagination['total'] as int?) ?? 0,
      ));
    } catch (e) {
      emit(TransactionError(
          message: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onRefreshTransactions(
    RefreshTransactions event,
    Emitter<TransactionState> emit,
  ) async {
    try {
      final result = await _transactionRepository.getTransactionHistory(
        page: 1,
        type: event.type,
        status: event.status,
      );
      final transactions = _parseTransactions(result);
      final pagination = _parsePagination(result);
      emit(TransactionLoaded(
        transactions: transactions,
        page: (pagination['page'] as int?) ?? 1,
        totalPages: (pagination['totalPages'] as int?) ?? 1,
        total: (pagination['total'] as int?) ?? 0,
      ));
    } catch (e) {
      emit(TransactionError(
          message: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onFilterTransactions(
    FilterTransactions event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionLoading());
    try {
      final result = await _transactionRepository.getTransactionHistory(
        page: 1,
        type: event.type,
        status: event.status,
      );
      final transactions = _parseTransactions(result);
      final pagination = _parsePagination(result);
      emit(TransactionLoaded(
        transactions: transactions,
        page: (pagination['page'] as int?) ?? 1,
        totalPages: (pagination['totalPages'] as int?) ?? 1,
        total: (pagination['total'] as int?) ?? 0,
      ));
    } catch (e) {
      emit(TransactionError(
          message: e.toString().replaceAll('Exception: ', '')));
    }
  }

  List<TransactionModel> _parseTransactions(Map<String, dynamic> result) {
    if (result['transactions'] is List) {
      return (result['transactions'] as List)
          .map((t) => TransactionModel.fromJson(t as Map<String, dynamic>))
          .toList();
    }
    if (result['data'] is Map<String, dynamic>) {
      final data = result['data'] as Map<String, dynamic>;
      if (data['transactions'] is List) {
        return (data['transactions'] as List)
            .map((t) => TransactionModel.fromJson(t as Map<String, dynamic>))
            .toList();
      }
    }
    return [];
  }

  Map<String, dynamic> _parsePagination(Map<String, dynamic> result) {
    if (result['pagination'] is Map<String, dynamic>) {
      return result['pagination'] as Map<String, dynamic>;
    }
    if (result['data'] is Map<String, dynamic>) {
      final data = result['data'] as Map<String, dynamic>;
      if (data['pagination'] is Map<String, dynamic>) {
        return data['pagination'] as Map<String, dynamic>;
      }
    }
    return {'page': 1, 'totalPages': 1, 'total': 0};
  }
}
