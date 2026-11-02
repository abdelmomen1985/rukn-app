import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'l10n/i18n.dart';
import 'screens/account_screens.dart';
import 'screens/auth_screen.dart';
import 'screens/blog_screens.dart';
import 'screens/cart_screen.dart';
import 'screens/certificate_screen.dart';
import 'screens/checkout_screen.dart';
import 'screens/home_screen.dart';
import 'screens/invest/alerts_screen.dart';
import 'screens/invest/asset_screens.dart';
import 'screens/invest/consultation_screen.dart';
import 'screens/invest/converter_screen.dart';
import 'screens/invest/invest_screen.dart';
import 'screens/invest/trips_screens.dart';
import 'screens/invest/zakat_screen.dart';
import 'screens/legal_screen.dart';
import 'screens/orders_screens.dart';
import 'screens/pricing_screen.dart';
import 'screens/product_list_screen.dart';
import 'screens/product_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/wishlist_screen.dart';
import 'services/site_analytics.dart';
import 'state/cart_state.dart';
import 'state/wishlist_state.dart';

final _rootKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootKey,
  initialLocation: '/',
  observers: [_PageViewObserver()],
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => _TabsShell(shell: shell),
      branches: [
        StatefulShellBranch(routes: [GoRoute(path: '/', builder: (_, _) => const HomeScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: '/wishlist', builder: (_, _) => const WishlistScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: '/cart', builder: (_, _) => const CartScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: '/invest', builder: (_, _) => const InvestScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen())]),
      ],
    ),
    GoRoute(parentNavigatorKey: _rootKey, path: '/product/:id', builder: (_, s) => ProductScreen(idOrHandle: s.pathParameters['id']!)),
    GoRoute(
      parentNavigatorKey: _rootKey,
      path: '/category/:id',
      builder: (_, s) => ProductListScreen(categoryId: s.pathParameters['id'], title: s.uri.queryParameters['title']),
    ),
    GoRoute(parentNavigatorKey: _rootKey, path: '/shop', builder: (_, _) => const ProductListScreen()),
    GoRoute(parentNavigatorKey: _rootKey, path: '/search', builder: (_, s) => ProductListScreen(search: true, initialQuery: s.uri.queryParameters['q'])),
    GoRoute(parentNavigatorKey: _rootKey, path: '/checkout', builder: (_, _) => const CheckoutScreen()),
    GoRoute(parentNavigatorKey: _rootKey, path: '/auth', builder: (_, _) => const AuthScreen()),
    GoRoute(parentNavigatorKey: _rootKey, path: '/orders', builder: (_, _) => const OrdersScreen()),
    GoRoute(parentNavigatorKey: _rootKey, path: '/orders/:id', builder: (_, s) => OrderDetailScreen(orderId: s.pathParameters['id']!)),
    GoRoute(parentNavigatorKey: _rootKey, path: '/account', builder: (_, _) => const EditProfileScreen()),
    GoRoute(parentNavigatorKey: _rootKey, path: '/addresses', builder: (_, _) => const AddressBookScreen()),
    GoRoute(parentNavigatorKey: _rootKey, path: '/loyalty', builder: (_, _) => const LoyaltyScreen()),
    GoRoute(parentNavigatorKey: _rootKey, path: '/certificate', builder: (_, s) => CertificateScreen(initialSerial: s.uri.queryParameters['serial'])),
    GoRoute(parentNavigatorKey: _rootKey, path: '/blog', builder: (_, _) => const BlogListScreen()),
    GoRoute(parentNavigatorKey: _rootKey, path: '/blog/:slug', builder: (_, s) => ArticleScreen(slug: s.pathParameters['slug']!)),
    GoRoute(parentNavigatorKey: _rootKey, path: '/privacy', builder: (_, _) => const LegalScreen(slug: 'privacy')),
    GoRoute(parentNavigatorKey: _rootKey, path: '/terms', builder: (_, _) => const LegalScreen(slug: 'terms')),
    GoRoute(parentNavigatorKey: _rootKey, path: '/pricing', builder: (_, _) => const PricingScreen()),
    GoRoute(parentNavigatorKey: _rootKey, path: '/invest/asset/new', builder: (_, s) => AssetFormScreen(assetId: s.uri.queryParameters['assetId'])),
    GoRoute(parentNavigatorKey: _rootKey, path: '/invest/asset/:id', builder: (_, s) => AssetDetailScreen(assetId: s.pathParameters['id']!)),
    GoRoute(parentNavigatorKey: _rootKey, path: '/invest/zakat', builder: (_, _) => const ZakatScreen()),
    GoRoute(parentNavigatorKey: _rootKey, path: '/invest/converter', builder: (_, _) => const ConverterScreen()),
    GoRoute(parentNavigatorKey: _rootKey, path: '/invest/consultation', builder: (_, _) => const ConsultationScreen()),
    GoRoute(parentNavigatorKey: _rootKey, path: '/invest/alerts', builder: (_, _) => const AlertsScreen()),
    GoRoute(parentNavigatorKey: _rootKey, path: '/invest/trips', builder: (_, _) => const TripsListScreen()),
    GoRoute(parentNavigatorKey: _rootKey, path: '/invest/trips/new', builder: (_, _) => const NewTripScreen()),
    GoRoute(parentNavigatorKey: _rootKey, path: '/invest/trips/:id', builder: (_, s) => TripDetailScreen(tripId: s.pathParameters['id']!)),
    GoRoute(parentNavigatorKey: _rootKey, path: '/invest/trips/:id/stop', builder: (_, s) => AddStopScreen(tripId: s.pathParameters['id']!)),
  ],
);

/// Reports each page view to «تحليلات الزوار». The location is read from the router, not the route,
/// because a GoRoute's page name is its pattern (`/product/:id`), not the URL the visitor sees.
class _PageViewObserver extends NavigatorObserver {
  void _pageView() => SiteAnalytics.shared.pageView(appRouter.routeInformationProvider.value.uri.toString());

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => _pageView();

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => _pageView();

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) => _pageView();
}

class _TabsShell extends StatelessWidget {
  const _TabsShell({required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final cartCount = context.watch<CartState>().itemCount;
    final wishCount = context.watch<WishlistState>().count;

    Widget badge(IconData icon, int count) => Badge(
          isLabelVisible: count > 0,
          backgroundColor: AppColors.primary,
          textColor: AppColors.darkGreen,
          label: Text('$count'),
          child: Icon(icon),
        );

    return Directionality(
      textDirection: i18n.direction,
      child: Scaffold(
        body: shell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: shell.currentIndex,
          height: 66,
          onDestinationSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
          destinations: [
            NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home), label: i18n.t('tabHome')),
            NavigationDestination(
              icon: badge(Icons.favorite_border, wishCount),
              selectedIcon: badge(Icons.favorite, wishCount),
              label: i18n.t('tabWishlist'),
            ),
            NavigationDestination(
              icon: badge(Icons.shopping_bag_outlined, cartCount),
              selectedIcon: badge(Icons.shopping_bag, cartCount),
              label: i18n.t('tabCart'),
            ),
            NavigationDestination(icon: const Icon(Icons.trending_up), label: i18n.t('tabInvest')),
            NavigationDestination(icon: const Icon(Icons.person_outline), selectedIcon: const Icon(Icons.person), label: i18n.t('tabProfile')),
          ],
        ),
      ),
    );
  }
}
