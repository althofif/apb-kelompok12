import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../models/restaurant_model.dart';
import '../models/menu_item.dart';
import '../providers/cart_provider.dart';
import 'restaurant_menu_screen.dart';
import 'cart_screen.dart';
import 'customer_profile_screen.dart';
import 'order_history_screen.dart';

// CustomerHomeScreen (Widget utama dengan Bottom Navigation)
class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({Key? key}) : super(key: key);

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = <Widget>[
    _HomeContent(),
    OrderHistoryScreen(key: PageStorageKey('order_history')),
    CartScreen(),
    CustomerProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Pesanan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Keranjang',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
      ),
    );
  }
}

// _HomeContent (Isi dari Tab Beranda)
class _HomeContent extends StatefulWidget {
  const _HomeContent({Key? key}) : super(key: key);

  @override
  _HomeContentState createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  String _selectedCategory = 'Semua';
  final List<Map<String, dynamic>> _categories = [
    {'name': 'Semua', 'icon': Icons.fastfood_rounded},
    {'name': 'Makanan', 'icon': Icons.ramen_dining_rounded},
    {'name': 'Minuman', 'icon': Icons.local_cafe_rounded},
    {'name': 'Cemilan', 'icon': Icons.icecream_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 16),
              _buildSectionHeader('Menu Rekomendasi', ''),
              _buildRecommendedMenuSection(),
              _buildSectionHeader('Restoran Untukmu', ''),
              _buildRestaurantList(),
              _buildSectionHeader('Kategori', ''),
              _buildCategoryList(),
              _buildSectionHeader('Menu Pilihan', ''),
            ]),
          ),
          _buildMenuList(),
        ],
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      floating: true,
      backgroundColor: Colors.white,
      elevation: 1,
      centerTitle: true,
      title: const Text(
        'DapoerKita',
        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: GestureDetector(
            onTap: () {
              showSearch(context: context, delegate: MenuSearchDelegate());
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Row(
                children: [
                  Icon(Icons.search, color: Colors.grey),
                  SizedBox(width: 8),
                  Text(
                    'Cari makanan atau restoran...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendedMenuSection() {
    return SizedBox(
      height: 220,
      child: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('menus')
                .orderBy('popularity', descending: true)
                .limit(5)
                .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return _buildShimmerList();
          if (snapshot.data!.docs.isEmpty) return const SizedBox.shrink();

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 16, right: 6),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final menu = MenuItem.fromFirestore(snapshot.data!.docs[index]);
              return _buildMenuCard(menu);
            },
          );
        },
      ),
    );
  }

  Widget _buildRestaurantList() {
    return SizedBox(
      height: 220,
      child: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('restaurants')
                .orderBy('name')
                .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return _buildShimmerList();
          if (snapshot.data!.docs.isEmpty)
            return const Center(child: Text('Belum ada restoran.'));
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 16, right: 6),
            itemCount: snapshot.data!.docs.length,
            itemBuilder:
                (context, index) => _buildRestaurantCard(
                  RestaurantModel.fromFirestore(snapshot.data!.docs[index]),
                ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryList() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 16, right: 6),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final bool isSelected = category['name'] == _selectedCategory;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = category['name']),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  width: 65,
                  height: 65,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.orange[100] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(15),
                    border:
                        isSelected
                            ? Border.all(color: Colors.orange, width: 2)
                            : null,
                  ),
                  child: Icon(
                    category['icon'],
                    color: isSelected ? Colors.orange : Colors.grey[600],
                  ),
                ),
                Text(
                  category['name'],
                  style: TextStyle(
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuList() {
    return StreamBuilder<QuerySnapshot>(
      stream: () {
        Query query = FirebaseFirestore.instance.collection('menus');
        if (_selectedCategory != 'Semua') {
          query = query.where('category', isEqualTo: _selectedCategory);
        }
        return query.orderBy('name').snapshots();
      }(),
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return SliverToBoxAdapter(
            child: Center(child: Text('Error: ${snapshot.error}')),
          );
        if (!snapshot.hasData)
          return const SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          );
        if (snapshot.data!.docs.isEmpty)
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Center(
                child: Text('Tidak ada menu di kategori "$_selectedCategory"'),
              ),
            ),
          );

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildMenuTile(
                MenuItem.fromFirestore(snapshot.data!.docs[index]),
              ),
              childCount: snapshot.data!.docs.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuCard(MenuItem menu) {
    return GestureDetector(
      onTap:
          () => _navigateToRestaurantByName(
            context,
            menu.restaurantId,
            menu.restaurantName ?? 'Restoran',
          ),
      child: SizedBox(
        width: 150,
        child: Card(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 120,
                width: double.infinity,
                child: CachedNetworkImage(
                  imageUrl: menu.imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      menu.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Rp ${menu.price.toStringAsFixed(0)}",
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).primaryColor,
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

  Widget _buildSectionHeader(String title, String actionText) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        if (actionText.isNotEmpty)
          Text(
            actionText,
            style: const TextStyle(color: Colors.orange, fontSize: 14),
          ),
      ],
    ),
  );
  Widget _buildRestaurantCard(RestaurantModel restaurant) => GestureDetector(
    onTap: () => _navigateToRestaurant(context, restaurant),
    child: SizedBox(
      width: 150,
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 120,
              width: double.infinity,
              child: CachedNetworkImage(
                imageUrl: restaurant.imageUrl ?? 'https://placehold.co/600x400',
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      Text(
                        ' ${restaurant.rating.toStringAsFixed(1)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
  Widget _buildMenuTile(MenuItem menu) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: menu.imageUrl,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
          ),
        ),
        title: Text(
          menu.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('dari: ${menu.restaurantName ?? 'Restoran'}'),
            Text(
              'Rp ${menu.price.toStringAsFixed(0)}',
              style: const TextStyle(color: Colors.green),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.add_shopping_cart, color: Colors.orange),
          onPressed: () {
            cart.addItem(
              menu.id,
              menu.price,
              menu.name,
              menu.imageUrl,
              menu.restaurantId,
              menu.restaurantName ?? 'Restoran',
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${menu.name} ditambahkan ke keranjang'),
                duration: const Duration(seconds: 1),
              ),
            );
          },
        ),
      ),
    );
  }

  void _navigateToRestaurant(
    BuildContext context,
    RestaurantModel restaurant,
  ) => Navigator.push(
    context,
    MaterialPageRoute(
      builder:
          (context) => RestaurantMenuScreen(
            restaurantId: restaurant.id,
            restaurantName: restaurant.name,
          ),
    ),
  );
  void _navigateToRestaurantByName(
    BuildContext context,
    String restaurantId,
    String restaurantName,
  ) => Navigator.push(
    context,
    MaterialPageRoute(
      builder:
          (context) => RestaurantMenuScreen(
            restaurantId: restaurantId,
            restaurantName: restaurantName,
          ),
    ),
  );
  Widget _buildShimmerList() => Shimmer.fromColors(
    baseColor: Colors.grey[300]!,
    highlightColor: Colors.grey[100]!,
    child: ListView(
      scrollDirection: Axis.horizontal,
      children: List.filled(
        5,
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            width: 150,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    ),
  );
}

class MenuSearchDelegate extends SearchDelegate<String> {
  @override
  String get searchFieldLabel => 'Cari menu favoritmu...';
  @override
  List<Widget>? buildActions(BuildContext context) => [
    IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
  ];
  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => close(context, ''),
  );
  @override
  Widget buildResults(BuildContext context) => _buildSearchResults(query);
  @override
  Widget buildSuggestions(BuildContext context) => _buildSearchResults(query);

  Widget _buildSearchResults(String searchQuery) {
    if (searchQuery.isEmpty) {
      return const Center(child: Text('Ketik untuk mulai mencari menu.'));
    }
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('menus')
              .where('keywords', arrayContains: searchQuery.toLowerCase())
              .limit(10)
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError)
          return Center(child: Text("Error: ${snapshot.error}"));
        if (snapshot.data!.docs.isEmpty)
          return Center(child: Text('Tidak ada hasil untuk "$query"'));

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final menu = MenuItem.fromFirestore(snapshot.data!.docs[index]);
            return ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: menu.imageUrl,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
              ),
              title: Text(menu.name),
              subtitle: Text(menu.restaurantName ?? 'Restoran'),
              onTap: () {
                close(context, menu.name);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => RestaurantMenuScreen(
                          restaurantId: menu.restaurantId,
                          restaurantName: menu.restaurantName ?? 'Restoran',
                        ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
