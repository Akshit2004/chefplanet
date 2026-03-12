import 'package:go_router/go_router.dart';
import 'package:chef_plannet/screens/home_screen.dart';
import 'package:chef_plannet/screens/login_screen.dart';
import 'package:chef_plannet/screens/signup_screen.dart';
import 'package:chef_plannet/screens/menu_cart_screen.dart';
import 'package:chef_plannet/screens/featured_dishes_screen.dart';
import 'package:chef_plannet/screens/product_detail_screen.dart';
import 'package:chef_plannet/screens/profile_screen.dart';
import 'package:chef_plannet/screens/my_orders_screen.dart';
import 'package:chef_plannet/screens/shipping_addresses_screen.dart';
import 'package:chef_plannet/screens/profile_options_screens.dart';
import 'package:chef_plannet/screens/checkout_screen.dart';
import 'package:chef_plannet/models/category_model.dart';
import 'package:chef_plannet/screens/category_dishes_screen.dart';
import 'package:chef_plannet/screens/search_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/menu',
        builder: (context, state) => const MenuCartScreen(),
      ),
      GoRoute(
        path: '/dishes',
        builder: (context, state) => const FeaturedDishesScreen(),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/product/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ProductDetailScreen(productId: id);
        },
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/orders',
        builder: (context, state) => const MyOrdersScreen(),
      ),
      GoRoute(
        path: '/addresses',
        builder: (context, state) => const ShippingAddressesScreen(),
      ),
      GoRoute(
        path: '/payment',
        builder: (context, state) => const PaymentMethodsScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/security',
        builder: (context, state) => const SecurityScreen(),
      ),
      GoRoute(
        path: '/checkout',
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/category',
        builder: (context, state) {
          final category = state.extra as Category;
          return CategoryDishesScreen(category: category);
        },
      ),
    ],
  );
}
