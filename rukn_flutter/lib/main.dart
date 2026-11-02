import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'app_router.dart';
import 'core/format.dart';
import 'core/theme.dart';
import 'l10n/i18n.dart';
import 'models/price_alert.dart';
import 'state/alerts_state.dart';
import 'state/auth_state.dart';
import 'state/cart_state.dart';
import 'state/gold_ticker.dart';
import 'state/portfolio_state.dart';
import 'state/trips_state.dart';
import 'state/wishlist_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future.wait([initializeDateFormatting('ar'), initializeDateFormatting('en')]);
  // Phones are portrait-only, like the Expo app; tablets keep every orientation.
  final view = PlatformDispatcher.instance.implicitView;
  if (view != null && view.physicalSize.shortestSide / view.devicePixelRatio < 600) {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  final i18n = I18n();
  final auth = AuthState();
  final cart = CartState();
  final wishlist = WishlistState();
  final ticker = GoldTicker();
  final portfolio = PortfolioState();
  final trips = TripsState();
  final alerts = AlertsState();

  await i18n.load();
  // Everything else hydrates in the background; screens render their own loading states.
  cart.load();
  wishlist.load();
  trips.load();
  alerts.load();
  String? portfolioOwner = '';
  void syncPortfolioOwner() {
    final id = auth.customer?.id;
    if (auth.loading || id == portfolioOwner) return;
    portfolioOwner = id;
    portfolio.setCustomer(id);
  }

  auth.addListener(syncPortfolioOwner);
  auth.load();

  ticker.addTickListener(alerts.evaluate);
  ticker.start();
  portfolio.start();

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: i18n),
      ChangeNotifierProvider.value(value: auth),
      ChangeNotifierProvider.value(value: cart),
      ChangeNotifierProvider.value(value: wishlist),
      ChangeNotifierProvider.value(value: ticker),
      ChangeNotifierProvider.value(value: portfolio),
      ChangeNotifierProvider.value(value: trips),
      ChangeNotifierProvider.value(value: alerts),
    ],
    child: const RuknApp(),
  ));
}

class RuknApp extends StatefulWidget {
  const RuknApp({super.key});

  @override
  State<RuknApp> createState() => _RuknAppState();
}

class _RuknAppState extends State<RuknApp> {
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    context.read<AlertsState>().onFired = _showFiredAlert;
  }

  void _showFiredAlert(FiredAlert fired) {
    final i18n = context.read<I18n>();
    final a = fired.alert;
    final metal = i18n.t(a.metal);
    _messengerKey.currentState?.showSnackBar(SnackBar(
      duration: const Duration(seconds: 8),
      backgroundColor: AppColors.darkGreen,
      content: Text(i18n.t(a.direction == 'above' ? 'alertFiredAbove' : 'alertFiredBelow', {
        'metal': '$metal ${a.purityLabel}',
        'target': formatSar(a.targetPerGramSar, i18n.lang),
        'price': formatSar(fired.price, i18n.lang),
      })),
      action: SnackBarAction(
        label: i18n.t('viewAlerts'),
        textColor: AppColors.primary,
        onPressed: () => appRouter.push('/invest/alerts'),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final i18n = context.watch<I18n>();
    return MaterialApp.router(
      title: 'Rukn Thamin',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: _messengerKey,
      theme: buildTheme(i18n.lang),
      locale: i18n.locale,
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: appRouter,
    );
  }
}
