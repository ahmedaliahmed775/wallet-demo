import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'repositories/auth_repository.dart';
import 'repositories/wallet_repository.dart';
import 'repositories/transaction_repository.dart';
import 'blocs/auth/auth_bloc.dart';
import 'blocs/wallet/wallet_bloc.dart';
import 'blocs/transaction/transaction_bloc.dart';
import 'features/splash/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const MahfazApp());
}

class MahfazApp extends StatelessWidget {
  const MahfazApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(authRepository: AuthRepository())..add(AuthCheckRequested()),
        ),
        BlocProvider<WalletBloc>(
          create: (_) => WalletBloc(walletRepository: WalletRepository()),
        ),
        BlocProvider<TransactionBloc>(
          create: (_) => TransactionBloc(transactionRepository: TransactionRepository()),
        ),
      ],
      child: MaterialApp(
        title: 'مِحْفَظ',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        locale: const Locale('ar'),
        supportedLocales: const [
          Locale('ar'),
          Locale('en'),
        ],
        builder: (context, child) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          );
        },
        home: const SplashScreen(),
      ),
    );
  }
}
