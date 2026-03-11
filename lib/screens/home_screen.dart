import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:chef_plannet/models/category_model.dart';
import 'package:chef_plannet/models/dish_model.dart';
import 'package:chef_plannet/services/mongodb_service.dart';
import 'package:chef_plannet/providers/cart_provider.dart';
import 'package:chef_plannet/providers/auth_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Category> _categories = [];
  List<Dish> _dishes = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    // Ensure DB is connected before querying
    await MongoDatabase.connect();
    final categories = await MongoDatabase.getCategories();
    final dishes = await MongoDatabase.getFeaturedDishes();

    if (mounted) {
      setState(() {
        _categories = categories;
        _dishes = dishes;
        _errorMessage = MongoDatabase.lastError;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chef Planet')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadData,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: InkWell(
          onTap: () => context.push('/shipping-addresses'),
          child: Consumer<AuthProvider>(
            builder: (context, auth, _) {
              final address = auth.defaultAddress;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Deliver to', style: theme.textTheme.bodyMedium),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 120),
                        child: ShaderMask(
                          shaderCallback: (Rect bounds) {
                            return const LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [Colors.black, Colors.transparent],
                              stops: [0.85, 1.0],
                            ).createShader(bounds);
                          },
                          blendMode: BlendMode.dstIn,
                          child: Text(
                            address != null
                                ? '${address.street}, ${address.city}'
                                : 'Select Address',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.clip,
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down, size: 24),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
        actions: [
          IconButton(icon: const Icon(LucideIcons.bell), onPressed: () {}),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: theme.primaryColor,
        backgroundColor: Colors.white,
        displacement: 40,
        strokeWidth: 3,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                // Search Bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search for dishes...',
                    prefixIcon: const Icon(LucideIcons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineBindingBorder(),
                  ),
                ),
                const SizedBox(height: 24),

                // Promotional Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.primaryColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Special Offer!',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            const Text(
                              'Get 20% off on your first order',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: theme.primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                              ),
                              child: const Text('Claim Now'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white24,
                        child: const Icon(
                          Icons.local_offer,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Categories Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Categories',
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontSize: 20,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        'See All',
                        style: TextStyle(color: theme.primaryColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Categories List
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 16.0),
                        child: GestureDetector(
                          onTap: () =>
                              context.push('/category', extra: category),
                          child: Column(
                            children: [
                              Hero(
                                tag: 'category_${category.id}',
                                child: CircleAvatar(
                                  radius: 35,
                                  backgroundImage: NetworkImage(
                                    category.imageUrl,
                                  ),
                                  onBackgroundImageError: (_, _) {},
                                  backgroundColor: Colors.grey.shade200,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                category.name,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Featured Dishes Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Featured Dishes',
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontSize: 20,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/dishes'),
                      child: Text(
                        'See All',
                        style: TextStyle(color: theme.primaryColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Dishes List
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _dishes.length,
                  itemBuilder: (context, index) {
                    final dish = _dishes[index];
                    return GestureDetector(
                      onTap: () => context.push('/product/${dish.id}'),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                dish.imageUrl,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      width: 80,
                                      height: 80,
                                      color: Colors.grey.shade200,
                                      child: const Icon(
                                        Icons.restaurant,
                                        color: Colors.grey,
                                      ),
                                    ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    dish.name,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    dish.description,
                                    style: theme.textTheme.bodyMedium,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '\$${dish.price.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          color: theme.primaryColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.star,
                                            color: Colors.amber,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            dish.rating.toString(),
                                            style: theme.textTheme.bodyMedium,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 80), // Padding for bottom nav
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: theme.primaryColor,
        unselectedItemColor: theme.textTheme.bodyMedium?.color,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(LucideIcons.home),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(LucideIcons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              label: Text(
                Provider.of<CartProvider>(context).itemCount.toString(),
              ),
              isLabelVisible: Provider.of<CartProvider>(context).itemCount > 0,
              child: const Icon(LucideIcons.shoppingBag),
            ),
            label: 'Cart',
          ),
          const BottomNavigationBarItem(
            icon: Icon(LucideIcons.user),
            label: 'Profile',
          ),
        ],
        onTap: (index) {
          if (index == 2) context.push('/menu');
          if (index == 3) {
            final authProvider = Provider.of<AuthProvider>(
              context,
              listen: false,
            );
            if (authProvider.isAuthenticated) {
              context.push('/profile');
            } else {
              context.push('/login');
            }
          }
        },
      ),
    );
  }
}

class OutlineBindingBorder extends OutlineInputBorder {
  OutlineBindingBorder()
    : super(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      );
}
