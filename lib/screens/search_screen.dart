import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:chef_plannet/models/category_model.dart';
import 'package:chef_plannet/models/dish_model.dart';
import 'package:chef_plannet/providers/cart_provider.dart';
import 'package:chef_plannet/services/mongodb_service.dart';
import 'package:chef_plannet/theme/app_theme.dart';
import 'package:chef_plannet/widgets/app_toast.dart';
import 'package:chef_plannet/widgets/chef_planet_bottom_nav_v2.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<Category> _categories = [];
  List<Dish> _results = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedCategory = 'Popular';

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(() {
      if (mounted) {
        _performSearch();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    await MongoDatabase.connect();
    final categories = await MongoDatabase.getCategories();

    if (!mounted) return;

    setState(() {
      _categories = categories;
      _errorMessage = MongoDatabase.lastError;
      _isLoading = false;
    });

    // perform initial search with current filters (empty query)
    await _performSearch();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _searchFocusNode.requestFocus();
      }
    });
  }

  List<String> get _filterLabels => [
    'Popular',
    ..._categories.map((category) => category.name),
  ];

  Map<String, Category> get _categoryById => {
    for (final category in _categories) category.id: category,
  };

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    final cat = _selectedCategory == 'Popular'
        ? null
        : _categories
              .firstWhere(
                (c) => c.name == _selectedCategory,
                orElse: () => Category(id: '', name: '', imageUrl: ''),
              )
              .id;

    setState(() {
      _isLoading = true;
    });

    final results = await MongoDatabase.searchDishes(query, categoryId: cat);

    if (mounted) {
      setState(() {
        _results = results;
        _isLoading = false;
        _errorMessage = MongoDatabase.lastError;
      });
    }
  }

  List<Dish> get _trendingDishes => _results.take(3).toList();

  List<Category> get _quickCravingCategories {
    final matchingIds = _results.map((dish) => dish.categoryId).toSet();
    final candidates = _categories
        .where((category) => matchingIds.contains(category.id))
        .toList();
    if (candidates.isNotEmpty) {
      return candidates.take(2).toList();
    }
    return _categories.take(2).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cart = context.watch<CartProvider>();

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(title: const Text('Search')),
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
        bottomNavigationBar: const ChefPlanetBottomNavV2(
          currentTab: ChefPlanetNavTab.search,
        ),
      );
    }

    final filteredDishes = _results;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F6),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.restaurant_menu_rounded,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Search',
                          style: theme.textTheme.displayLarge?.copyWith(
                            fontSize: 24,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Discover dishes, cuisines, and quick cravings',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFF0E7DE)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x140F172A),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  decoration: InputDecoration(
                    hintText: 'Search for dishes, cuisines...',
                    hintStyle: theme.textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppTheme.textSecondaryColor,
                    ),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            onPressed: _searchController.clear,
                            icon: const Icon(Icons.close_rounded),
                          ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 64,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  final label = _filterLabels[index];
                  final isSelected = label == _selectedCategory;
                  return FilterChip(
                    label: Text(label),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() => _selectedCategory = label);
                      _performSearch();
                    },
                    selectedColor: AppTheme.primaryColor,
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : AppTheme.textSecondaryColor,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : const Color(0xFFEDE1D5),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    showCheckmark: false,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemCount: _filterLabels.length,
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadData,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                  children: [
                    _SectionHeader(
                      title: _searchController.text.trim().isEmpty
                          ? 'Trending Searches'
                          : 'Results',
                      actionLabel: _searchController.text.trim().isEmpty
                          ? 'View All'
                          : '${filteredDishes.length} items',
                    ),
                    const SizedBox(height: 14),
                    if (filteredDishes.isEmpty)
                      _EmptySearchState(
                        onClear: () => _searchController.clear(),
                      )
                    else ...[
                      for (final dish in _trendingDishes)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _DishSearchCard(
                            dish: dish,
                            categoryName:
                                _categoryById[dish.categoryId]?.name ??
                                'Chef Special',
                            onTap: () => context.push('/product/${dish.id}'),
                            onAdd: () {
                              context.read<CartProvider>().addItem(dish, 1);
                              AppToast.show(
                                context,
                                '${dish.name} added to cart',
                              );
                            },
                          ),
                        ),
                      if (_searchController.text.trim().isNotEmpty &&
                          filteredDishes.length > 3)
                        ...filteredDishes
                            .skip(3)
                            .take(4)
                            .map(
                              (dish) => Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: _DishSearchCard(
                                  dish: dish,
                                  categoryName:
                                      _categoryById[dish.categoryId]?.name ??
                                      'Chef Special',
                                  onTap: () =>
                                      context.push('/product/${dish.id}'),
                                  onAdd: () {
                                    context.read<CartProvider>().addItem(
                                      dish,
                                      1,
                                    );
                                    AppToast.show(
                                      context,
                                      '${dish.name} added to cart',
                                    );
                                  },
                                ),
                              ),
                            ),
                      const SizedBox(height: 10),
                      const _SectionHeader(title: 'Quick Cravings'),
                      const SizedBox(height: 14),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                              childAspectRatio: 1,
                            ),
                        itemCount: _quickCravingCategories.length,
                        itemBuilder: (context, index) {
                          final category = _quickCravingCategories[index];
                          return _CategoryTile(
                            category: category,
                            onTap: () {
                              setState(() {
                                _selectedCategory = category.name;
                              });
                            },
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const ChefPlanetBottomNavV2(
        currentTab: ChefPlanetNavTab.search,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.actionLabel});

  final String title;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
        ),
        if (actionLabel != null)
          Text(
            actionLabel!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }
}

class _DishSearchCard extends StatelessWidget {
  const _DishSearchCard({
    required this.dish,
    required this.categoryName,
    required this.onTap,
    required this.onAdd,
  });

  final Dish dish;
  final String categoryName;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFF0E7DE)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x120F172A),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  dish.imageUrl,
                  width: 84,
                  height: 84,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 84,
                    height: 84,
                    color: const Color(0xFFF2ECE6),
                    child: const Icon(Icons.restaurant, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dish.name,
                      style: const TextStyle(
                        color: AppTheme.textPrimaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$categoryName • ${dish.preparationTime}',
                      style: const TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '\$${dish.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                customBorder: const CircleBorder(),
                onTap: onAdd,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, required this.onTap});

  final Category category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                category.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: const Color(0xFFF2ECE6),
                  child: const Icon(Icons.fastfood_rounded, color: Colors.grey),
                ),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00000000), Color(0xAA000000)],
                  ),
                ),
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: Text(
                  category.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptySearchState extends StatelessWidget {
  const _EmptySearchState({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF0E7DE)),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.search_off_rounded,
              color: AppTheme.primaryColor,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No matches found',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a broader keyword or switch the category filter.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          TextButton(onPressed: onClear, child: const Text('Clear search')),
        ],
      ),
    );
  }
}
