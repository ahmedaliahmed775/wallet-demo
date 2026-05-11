import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../repositories/wallet_repository.dart';
import '../../models/wallet_model.dart';

// ─── Events ───────────────────────────────────────────────────────────────────

abstract class WalletEvent extends Equatable {
  const WalletEvent();
  @override
  List<Object?> get props => [];
}

class LoadWallet extends WalletEvent {}

class WalletBalanceRequested extends WalletEvent {}

class RefreshWallet extends WalletEvent {}

// ─── States ───────────────────────────────────────────────────────────────────

abstract class WalletState extends Equatable {
  const WalletState();
  @override
  List<Object?> get props => [];
}

class WalletInitial extends WalletState {}

class WalletLoading extends WalletState {}

class WalletLoaded extends WalletState {
  final List<WalletModel> wallets;
  final double totalInYER;

  const WalletLoaded({
    required this.wallets,
    required this.totalInYER,
  });

  @override
  List<Object?> get props => [wallets, totalInYER];
}

class WalletError extends WalletState {
  final String message;
  const WalletError({required this.message});

  @override
  List<Object?> get props => [message];
}

// ─── Bloc ─────────────────────────────────────────────────────────────────────

class WalletBloc extends Bloc<WalletEvent, WalletState> {
  final WalletRepository _walletRepository;

  WalletBloc({required WalletRepository walletRepository})
      : _walletRepository = walletRepository,
        super(WalletInitial()) {
    on<LoadWallet>(_onLoadWallet);
    on<WalletBalanceRequested>(_onLoadWallet);
    on<RefreshWallet>(_onRefreshWallet);
  }

  Future<void> _onLoadWallet(
    WalletEvent event,
    Emitter<WalletState> emit,
  ) async {
    emit(WalletLoading());
    try {
      final result = await _walletRepository.getBalance();
      final wallets = _parseWallets(result);
      final totalInYER = _calculateTotalInYER(result, wallets);
      emit(WalletLoaded(wallets: wallets, totalInYER: totalInYER));
    } catch (e) {
      emit(WalletError(
          message: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onRefreshWallet(
    RefreshWallet event,
    Emitter<WalletState> emit,
  ) async {
    try {
      final result = await _walletRepository.getBalance();
      final wallets = _parseWallets(result);
      final totalInYER = _calculateTotalInYER(result, wallets);
      emit(WalletLoaded(wallets: wallets, totalInYER: totalInYER));
    } catch (e) {
      emit(WalletError(
          message: e.toString().replaceAll('Exception: ', '')));
    }
  }

  List<WalletModel> _parseWallets(Map<String, dynamic> result) {
    if (result['wallets'] is List) {
      return (result['wallets'] as List)
          .map((w) => WalletModel.fromJson(w as Map<String, dynamic>))
          .toList();
    }
    if (result['data'] is Map<String, dynamic>) {
      final data = result['data'] as Map<String, dynamic>;
      if (data['wallets'] is List) {
        return (data['wallets'] as List)
            .map((w) => WalletModel.fromJson(w as Map<String, dynamic>))
            .toList();
      }
    }
    return [];
  }

  double _calculateTotalInYER(
    Map<String, dynamic> result,
    List<WalletModel> wallets,
  ) {
    if (result['totalBalanceYER'] != null && result['totalBalanceYER'] is num) {
      return (result['totalBalanceYER'] as num).toDouble();
    }
    if (result['data'] is Map<String, dynamic>) {
      final data = result['data'] as Map<String, dynamic>;
      if (data['totalBalanceYER'] != null && data['totalBalanceYER'] is num) {
        return (data['totalBalanceYER'] as num).toDouble();
      }
    }

    return wallets.fold<double>(0, (sum, wallet) {
      switch (wallet.currency) {
        case 'YER':
          return sum + wallet.balance;
        case 'USD':
          return sum + wallet.balance * 530;
        case 'SAR':
          return sum + wallet.balance * 141;
        default:
          return sum;
      }
    });
  }
}
