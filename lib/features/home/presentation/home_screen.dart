import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/cubit/theme_cubit.dart';
import '../../../app/di/service_locator.dart';
import '../../../core/network/suruh_api_client.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/storage/local_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/link_launcher.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/skeletons.dart';
import '../../../core/widgets/state_views.dart';
import '../../../domain/entities/food_category.dart';
import '../../../domain/entities/food_item.dart';
import '../../../domain/entities/operational_city.dart';

/// Single-page Landing Page for SURUH Platform.
///
/// 100% Dynamic from Backend (Django REST Framework / PostgreSQL):
/// - Operational Cities: GET /api/v1/services/cities/ (Model: OperationalCity)
/// - Service Categories: GET /api/v1/services/categories/ (Model: ServiceCategory)
/// - Services & Prices: GET /api/v1/services/services/ (Model: Service)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<OperationalCity> _cities = const <OperationalCity>[];
  OperationalCity? _selectedCity;
  List<FoodCategory> _categories = const <FoodCategory>[];
  List<FoodItem> _services = const <FoodItem>[];

  bool _isLoading = true;
  String? _errorMessage;

  String _selectedCategorySlug = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  static const Color _waGreen = Color(0xFF25D366);
  static const Color _waGreenDark = Color(0xFF1EBE5D);
  static const String _kSelectedCityKey = 'suruh_selected_city_slug';

  @override
  void initState() {
    super.initState();
    _loadBackendData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Fetches cities, categories, and all services live from backend REST API
  Future<void> _loadBackendData({bool isRefresh = false}) async {
    if (!isRefresh && _services.isEmpty) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final SuruhApiClient client = sl<SuruhApiClient>();
      final AppDatabase db = sl<AppDatabase>();
      final LocalStorage storage = sl<LocalStorage>();

      // 1. Fetch cities from backend (/api/v1/services/cities/)
      final List<dynamic> rawCities = await client.getCities();
      final List<OperationalCity> fetchedCities = rawCities
          .whereType<Map<String, dynamic>>()
          .map(OperationalCity.fromJson)
          .toList();

      // 2. Fetch categories from backend (/api/v1/services/categories/)
      final List<dynamic> rawCategories = await client.getCategories();
      final List<FoodCategory> fetchedCategories = rawCategories
          .whereType<Map<String, dynamic>>()
          .map(FoodCategory.fromJson)
          .toList();

      // 3. Fetch services from backend (/api/v1/services/services/)
      final List<dynamic> rawServices = await client.getServices();
      final List<FoodItem> fetchedServices = rawServices
          .whereType<Map<String, dynamic>>()
          .map(FoodItem.fromJson)
          .toList();

      // Save to SQLite local cache for offline availability
      if (rawCategories.isNotEmpty) {
        await db.cacheCategories(rawCategories.cast<Map<String, dynamic>>());
      }
      if (rawServices.isNotEmpty) {
        await db.cacheServices(rawServices.cast<Map<String, dynamic>>());
      }

      // Determine active city
      final String? savedSlug = storage.getString(_kSelectedCityKey);
      OperationalCity? activeCity;
      if (savedSlug != null && savedSlug.isNotEmpty && fetchedCities.isNotEmpty) {
        activeCity = fetchedCities.cast<OperationalCity?>().firstWhere(
              (OperationalCity? c) => c?.slug == savedSlug,
              orElse: () => null,
            );
      }
      activeCity ??= _selectedCity ?? (fetchedCities.isNotEmpty ? fetchedCities.first : null);

      if (mounted) {
        setState(() {
          _cities = fetchedCities;
          _selectedCity = activeCity;
          _categories = fetchedCategories;
          _services = fetchedServices;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      // Offline fallback: load from SQLite cache
      final AppDatabase db = sl<AppDatabase>();
      final List<Map<String, dynamic>> cachedServices = await db.getCachedServices();
      final List<Map<String, dynamic>> cachedCategories = await db.getCachedCategories();

      if (mounted) {
        setState(() {
          if (cachedServices.isNotEmpty) {
            _services = cachedServices.map(FoodItem.fromJson).toList();
          }
          if (cachedCategories.isNotEmpty) {
            _categories = cachedCategories.map(FoodCategory.fromJson).toList();
          }
          _isLoading = false;
          if (_services.isEmpty) {
            _errorMessage = 'Belum dapat terhubung ke server backend. Periksa koneksi atau jalankan backend API.';
          }
        });
      }
    }
  }

  Future<void> _changeCity(OperationalCity city) async {
    setState(() {
      _selectedCity = city;
    });
    try {
      final LocalStorage storage = sl<LocalStorage>();
      await storage.setString(_kSelectedCityKey, city.slug);
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Wilayah layanan aktif: ${city.name}'),
          backgroundColor: AppColors.primaryDark,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _onCategorySelected(String slug) {
    setState(() {
      _selectedCategorySlug = slug;
    });
  }

  void _openWhatsAppOrder(FoodItem item) {
    final String priceStr = item.formattedPrice;
    final String phone =
        item.whatsappNumber ?? _selectedCity?.whatsappNumber ?? '6281211112222';
    final String area =
        _selectedCity != null ? 'area ${_selectedCity!.name}' : 'wilayah Anda';
    final String message =
        'Halo Admin SURUH, saya ingin memesan layanan "${item.name}" ($priceStr) untuk $area. Mohon informasikan ketersediaan dan detailnya.';

    LinkLauncher.openWhatsApp(
      context,
      phone: phone,
      message: message,
      fullUrl: item.whatsappUrl,
    );
  }

  void _openWhatsAppGeneral() {
    final String phone = _selectedCity?.whatsappNumber ?? '6281211112222';
    final String area =
        _selectedCity != null ? 'area ${_selectedCity!.name}' : 'wilayah Anda';
    final String message =
        'Halo Admin SURUH, saya ingin bertanya atau memesan jasa untuk $area. Mohon bantuannya.';

    LinkLauncher.openWhatsApp(
      context,
      phone: phone,
      message: message,
    );
  }

  void _showCityPicker(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        'Pilih Kota / Wilayah Layanan',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                if (_cities.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Center(
                      child: Text(
                        'Daftar wilayah belum tersedia atau sedang dimuat dari backend.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  ..._cities.map((OperationalCity city) {
                    final bool isSelected = _selectedCity?.slug == city.slug;
                    return ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.15)
                              : (isDark
                                  ? AppColors.darkSurfaceAlt
                                  : AppColors.lightCanvas),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.location_city_rounded,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.lightTextSecondary,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        city.name,
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? AppColors.primary : null,
                        ),
                      ),
                      subtitle: const Text('Admin WhatsApp Lokal Aktif'),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.primary,
                            )
                          : null,
                      onTap: () {
                        Navigator.pop(ctx);
                        _changeCity(city);
                      },
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final String activeCityName = _selectedCity?.name ?? 'Pilih Wilayah';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openWhatsAppGeneral,
        backgroundColor: _waGreen,
        foregroundColor: Colors.white,
        elevation: 6,
        icon: const Icon(Icons.chat_bubble_rounded, size: 22),
        label: Text(
          _selectedCity != null ? 'WA ${_selectedCity!.name}' : 'Tanya Admin WA',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadBackendData(isRefresh: true),
        child: _buildContent(context, activeCityName, isDark),
      ),
    );
  }

  Widget _buildContent(BuildContext context, String activeCityName, bool isDark) {
    if (_isLoading && _services.isEmpty) {
      return const CustomScrollView(
        slivers: <Widget>[
          SliverToBoxAdapter(child: _LandingSkeleton()),
        ],
      );
    }

    if (_errorMessage != null && _services.isEmpty) {
      return ListView(
        children: <Widget>[
          SizedBox(height: context.screenHeight * 0.2),
          ErrorView(
            message: _errorMessage!,
            onRetry: () => _loadBackendData(),
          ),
        ],
      );
    }

    // Filter services by active city, category chip, and search keyword
    final List<FoodItem> filteredServices = _services.where((FoodItem s) {
      final bool matchesCity = _selectedCity == null ||
          s.isAvailableInCity(_selectedCity!.slug);

      final bool matchesCategory = _selectedCategorySlug == 'all' ||
          s.categoryId.toLowerCase() == _selectedCategorySlug.toLowerCase();

      final bool matchesSearch = _searchQuery.isEmpty ||
          s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.description.toLowerCase().contains(_searchQuery.toLowerCase());

      return matchesCity && matchesCategory && matchesSearch;
    }).toList();

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: <Widget>[
        // 1. Header & Hero Section
        SliverToBoxAdapter(
          child: _buildHeaderHero(context, activeCityName, isDark),
        ),

        // 2. Search Box
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              context.gutter,
              AppSpacing.lg,
              context.gutter,
              AppSpacing.sm,
            ),
            child: _buildSearchBar(context, isDark),
          ),
        ),

        // 3. Category Filter Chips (from backend ServiceCategory)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: _buildCategoryChips(context, isDark),
          ),
        ),

        // 4. Section Header
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              context.gutter,
              AppSpacing.md,
              context.gutter,
              AppSpacing.sm,
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        _selectedCity != null
                            ? 'Layanan di ${_selectedCity!.name}'
                            : 'Daftar Layanan & Harga',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tap tombol untuk pesan langsung lewat WhatsApp Admin',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    '${filteredServices.length} Layanan',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 5. Service Cards List (all services from backend)
        if (filteredServices.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
              child: EmptyView(
                title: 'Layanan belum tersedia',
                message: _selectedCity != null
                    ? 'Belum ada layanan untuk ${_selectedCity!.name}. Coba cari dengan kata kunci lain.'
                    : 'Pilih wilayah layanan terlebih dahulu.',
                icon: Icons.search_off_rounded,
              ),
            ),
          )
        else
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              context.gutter,
              AppSpacing.sm,
              context.gutter,
              AppSpacing.lg,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  final FoodItem item = filteredServices[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _buildServiceCard(context, item, isDark),
                  );
                },
                childCount: filteredServices.length,
              ),
            ),
          ),

        // 6. Custom Request Banner
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              context.gutter,
              AppSpacing.sm,
              context.gutter,
              AppSpacing.lg,
            ),
            child: _buildCustomRequestCard(context, isDark),
          ),
        ),

        // 7. Footer Information
        SliverToBoxAdapter(
          child: _buildFooter(context, isDark),
        ),

        // Spacing for FAB
        const SliverToBoxAdapter(
          child: SizedBox(height: 80),
        ),
      ],
    );
  }

  Widget _buildHeaderHero(BuildContext context, String activeCityName, bool isDark) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.xl),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            context.gutter,
            AppSpacing.md,
            context.gutter,
            AppSpacing.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Top Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: const Text('⚡', style: TextStyle(fontSize: 22)),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'SURUH',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Text(
                            'Ada urusan? Suruh kami',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => context.read<ThemeCubit>().cycle(),
                    icon: Icon(
                      isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                      color: Colors.white,
                    ),
                    tooltip: 'Ubah Tema',
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xl),

              // Hero Banner with Dynamic City Selector
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        // Interactive City Selector Button
                        InkWell(
                          onTap: () => _showCityPicker(context),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                const Icon(
                                  Icons.location_on,
                                  size: 14,
                                  color: AppColors.primaryDark,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  activeCityName,
                                  style: const TextStyle(
                                    color: AppColors.primaryDark,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 16,
                                  color: AppColors.primaryDark,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        const Text(
                          'Respon Cepat via WA',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _selectedCity != null
                          ? 'Pesan Jasa di ${_selectedCity!.name} Praktis!'
                          : 'Pesan Jasa Jadi Lebih Praktis!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Pilih layanan, lihat tarif, lalu tap pesan. Langsung terhubung ke WhatsApp Admin tanpa perlu membuat akun.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ElevatedButton.icon(
                      onPressed: _openWhatsAppGeneral,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _waGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      icon: const Icon(Icons.chat_outlined, size: 18),
                      label: Text(
                        _selectedCity != null
                            ? 'Konsultasi WA ${_selectedCity!.name}'
                            : 'Konsultasi via WhatsApp',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (String val) {
          setState(() {
            _searchQuery = val.trim();
          });
        },
        decoration: InputDecoration(
          hintText: _selectedCity != null
              ? 'Cari layanan di ${_selectedCity!.name}...'
              : 'Cari layanan yang Anda butuhkan...',
          hintStyle: TextStyle(
            color: isDark
                ? AppColors.darkTextTertiary
                : AppColors.lightTextTertiary,
            fontSize: 14,
          ),
          prefixIcon: const Icon(Icons.search, color: AppColors.primary),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips(BuildContext context, bool isDark) {
    final List<Map<String, String>> chips = <Map<String, String>>[
      <String, String>{'slug': 'all', 'name': 'Semua', 'emoji': '✨'},
      ..._categories.map(
        (FoodCategory c) => <String, String>{
          'slug': c.id,
          'name': c.name,
          'emoji': c.emoji,
        },
      ),
    ];

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: context.gutter),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (BuildContext context, int index) {
          final Map<String, String> c = chips[index];
          final String slug = c['slug'] ?? 'all';
          final String name = c['name'] ?? '';
          final String emoji = c['emoji'] ?? '✨';
          final bool isSelected = _selectedCategorySlug == slug;

          return FilterChip(
            selected: isSelected,
            label: Text('$emoji $name'),
            labelStyle: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected
                  ? Colors.white
                  : (isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary),
            ),
            backgroundColor:
                isDark ? AppColors.darkSurface : AppColors.lightSurface,
            selectedColor: AppColors.primary,
            showCheckmark: false,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              side: BorderSide(
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
            ),
            onSelected: (_) => _onCategorySelected(slug),
          );
        },
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context, FoodItem item, bool isDark) {
    final ThemeData theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Service Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    item.emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        item.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.restaurantName.isNotEmpty ? item.restaurantName : 'Layanan Resmi',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (item.description.isNotEmpty) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              Text(
                item.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                  height: 1.4,
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.lg),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.md),

            // Bottom Section: Price & WhatsApp Order Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Perkiraan Biaya',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.darkTextTertiary
                            : AppColors.lightTextTertiary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.formattedPrice,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _openWhatsAppOrder(item),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _waGreen,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                  label: const Text(
                    'Pesan via WA',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomRequestCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceAlt : AppColors.primarySurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Text('💡', style: TextStyle(fontSize: 24)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  _selectedCity != null
                      ? 'Punya Urusan Lain di ${_selectedCity!.name}?'
                      : 'Punya Permintaan Layanan Lain?',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _selectedCity != null
                ? 'Butuh bantuan personal, antar barang, atau kebutuhan khusus di ${_selectedCity!.name}? Admin SURUH siap melayani via WhatsApp.'
                : 'Butuh bantuan personal atau urusan khusus? Admin SURUH siap melayani via WhatsApp.',
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openWhatsAppGeneral,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _waGreen, width: 1.5),
                foregroundColor: _waGreenDark,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              icon: const Icon(Icons.send_rounded, size: 18),
              label: const Text(
                'Kirim Permintaan ke WhatsApp Admin',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.gutter,
        vertical: AppSpacing.lg,
      ),
      child: Column(
        children: <Widget>[
          const Divider(),
          const SizedBox(height: AppSpacing.md),
          Text(
            _selectedCity != null
                ? 'SURUH - Layanan Aktif: ${_selectedCity!.name}'
                : 'SURUH - Platform Jasa On-Demand',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Jam Operasional: 06.00 - 22.00 WIB\nSemua transaksi aman & dilayani langsung via WhatsApp admin resmi.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              height: 1.4,
              color: isDark
                  ? AppColors.darkTextTertiary
                  : AppColors.lightTextTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _LandingSkeleton extends StatelessWidget {
  const _LandingSkeleton();

  @override
  Widget build(BuildContext context) {
    return const AppShimmer(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: <Widget>[
            SkeletonBox(width: double.infinity, height: 180, radius: AppRadius.lg),
            SizedBox(height: AppSpacing.md),
            SkeletonBox(width: double.infinity, height: 48, radius: AppRadius.lg),
            SizedBox(height: AppSpacing.md),
            SkeletonBox(width: double.infinity, height: 120, radius: AppRadius.lg),
            SizedBox(height: AppSpacing.md),
            SkeletonBox(width: double.infinity, height: 120, radius: AppRadius.lg),
          ],
        ),
      ),
    );
  }
}
