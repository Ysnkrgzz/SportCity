import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isDarkMode = false;
  String? eposta;
  String? sifre;
  int _selectedIndex = 0;
  Set<String> _selectedCategories = {};
  String _searchQuery = '';
  bool _isLoading = true;
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _cartItems = [];
  final ApiService _apiService = ApiService();
  List<String> _categories = [];

  List<Map<String, dynamic>> get filteredProducts {
    if (_selectedCategories.isEmpty) {
      return _products;
    }
    return _products.where((product) => 
      _selectedCategories.contains(product['category'])
    ).toList();
  }

  List<Map<String, dynamic>> get searchResults {
    if (_searchQuery.isEmpty) {
      return _products;
    }
    return _products.where((product) {
      final name = product['name'].toString().toLowerCase();
      final description = product['description'].toString().toLowerCase();
      final category = product['category'].toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      
      return name.contains(query) || 
             description.contains(query) || 
             category.contains(query);
    }).toList();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final products = await _apiService.getProducts();
      if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ürünler yüklenirken hata oluştu: $e')),
        );
      }
    }
  }

  Future<void> _loadProductsByCategory(String category) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final products = await _apiService.getProductsByCategory(category);
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kategori ürünleri yüklenirken hata oluştu: $e')),
      );
    }
  }

  Future<void> _searchProducts(String query) async {
    if (query.isEmpty) {
      _loadProducts();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final products = await _apiService.searchProducts(query);
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Arama yapılırken hata oluştu: $e')),
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadProducts();
    _loadCategories();
    _loadUserData();
  }

  @override
  void initState() {
    super.initState();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      eposta = prefs.getString('eposta');
      sifre = prefs.getString('sifre');
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    });
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _apiService.getCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kategoriler yüklenirken hata oluştu: $e')),
        );
      }
    }
  }

  void ClearPref() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    final isDarkMode = preferences.getBool('isDarkMode') ?? false;
    await preferences.remove('eposta');
    await preferences.remove('sifre');
    await preferences.setBool('isDarkMode', isDarkMode);
    context.go("/login");
  }

  void _toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = !_isDarkMode;
      prefs.setBool('isDarkMode', _isDarkMode);
    });
  }

  void _addToCart(Map<String, dynamic> product) {
    setState(() {
      _cartItems.add(product);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${product['name']} sepete eklendi')),
    );
  }

  void _navigateToAdminLogin() {
    context.push('/admin', extra: {
      'onProductUpdated': () {
        setState(() {
          _loadProducts();
        });
      },
      'onCategoryUpdated': () {
        setState(() {
          _loadCategories();
        });
      },
    });
  }

  void _createOrder() async {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sepetiniz boş')),
      );
      return;
    }

    if (eposta == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen önce giriş yapın')),
      );
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      final order = {
        'items': _cartItems.map((item) => {
          'id': item['id'],
          'name': item['name'],
          'price': item['price'],
          'imageUrl': item['imageUrl'],
          'category': item['category'],
        }).toList(),
        'totalPrice': _calculateTotalPrice(),
        'status': 'Beklemede',
        'orderDate': DateTime.now().toIso8601String(),
        'userEmail': eposta,
      };

      await _apiService.createOrder(order);
      
      if (!mounted) return;

      setState(() {
        _cartItems.clear();
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Siparişiniz başarıyla oluşturuldu')),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sipariş oluşturulurken hata oluştu: $e')),
      );
    }
  }

  Widget _buildHomeContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Column(
      children: [
        Container(
          height: 50,
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.only(left: 10),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              final isSelected = _selectedCategories.contains(category);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: FilterChip(
                  selected: isSelected,
                  label: Text(category),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedCategories.add(category);
                      } else {
                        _selectedCategories.remove(category);
                      }
                    });
                  },
                  backgroundColor: _isDarkMode ? Colors.grey[800] : Colors.grey[200],
                  selectedColor: _isDarkMode ? const Color(0xFF1A237E) : const Color(0xFF1E88E5),
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : (_isDarkMode ? Colors.white : Colors.black),
                  ),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: _selectedCategories.isEmpty
              ? _buildProductGrid(_products)
              : _buildProductGrid(_products.where((product) => 
                  _selectedCategories.contains(product['category'])).toList()),
        ),
      ],
    );
  }

  Widget _buildProductGrid(List<Map<String, dynamic>> productsToShow) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: productsToShow.length,
      itemBuilder: (context, index) {
        final product = productsToShow[index];
        return Card(
          elevation: 2,
          color: _isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: _isDarkMode ? const Color(0xFF1A237E) : const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: product['imageUrl'] != null
                        ? CachedNetworkImage(
                            imageUrl: product['imageUrl'],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            placeholder: (context, url) => Center(
                              child: CircularProgressIndicator(
                                color: _isDarkMode ? Colors.white70 : Colors.blue,
                              ),
                            ),
                            errorWidget: (context, url, error) => Center(
                              child: Icon(
                                CupertinoIcons.photo,
                                size: 40,
                                color: _isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                          )
                        : const Center(
                            child: Icon(
                              CupertinoIcons.photo,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product['name'] ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _isDarkMode ? Colors.white : const Color(0xFF2962FF),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  product['description'] ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    color: _isDarkMode ? Colors.white70 : const Color(0xFF757575),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      product['price'] ?? '',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _isDarkMode ? Colors.white : const Color(0xFF1E88E5),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        CupertinoIcons.cart_badge_plus,
                        color: _isDarkMode ? Colors.white : const Color(0xFF1E88E5),
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _addToCart(product),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchContent() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            style: TextStyle(
              color: _isDarkMode ? Colors.white : Colors.black,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                _searchProducts(value);
              });
            },
            decoration: InputDecoration(
              hintText: 'Ürün ara...',
              hintStyle: TextStyle(
                color: _isDarkMode ? Colors.white70 : Colors.black54,
              ),
              prefixIcon: Icon(
                CupertinoIcons.search,
                color: _isDarkMode ? Colors.white70 : Colors.black54,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _isDarkMode ? Colors.white24 : Colors.black12,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _isDarkMode ? Colors.white24 : Colors.black12,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _isDarkMode ? Colors.white : Colors.blue,
                ),
              ),
              filled: true,
              fillColor: _isDarkMode ? Colors.grey[850] : Colors.grey[200],
            ),
          ),
        ),
        if (_isLoading)
          const Expanded(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          )
        else
          Expanded(
            child: searchResults.isEmpty
                ? Center(
                    child: Text(
                      'Ürün bulunamadı',
                      style: TextStyle(
                        color: _isDarkMode ? Colors.white : Colors.black,
                        fontSize: 16,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: searchResults.length,
                    itemBuilder: (context, index) {
                      final product = searchResults[index];
                      return ListTile(
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: _isDarkMode ? Colors.grey[800] : Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: product['imageUrl'] != null
                                ? Image.network(
                                    product['imageUrl'],
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    alignment: Alignment.center,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Center(
                                        child: CircularProgressIndicator(
                                          value: loadingProgress.expectedTotalBytes != null
                                              ? loadingProgress.cumulativeBytesLoaded /
                                                  loadingProgress.expectedTotalBytes!
                                              : null,
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return Center(
                                        child: Icon(
                                          CupertinoIcons.photo,
                                          size: 24,
                                          color: _isDarkMode ? Colors.white : Colors.black,
                                        ),
                                      );
                                    },
                                  )
                                : Center(
                                    child: Icon(
                                      CupertinoIcons.photo,
                                      size: 24,
                                      color: _isDarkMode ? Colors.white : Colors.black,
                                    ),
                                  ),
                          ),
                        ),
                        title: Text(
                          product['name'] ?? '',
                          style: TextStyle(
                            color: _isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        subtitle: Text(
                          product['description'] ?? '',
                          style: TextStyle(
                            color: _isDarkMode ? Colors.white70 : Colors.grey[600],
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              product['price'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                CupertinoIcons.cart_badge_plus,
                                color: _isDarkMode ? Colors.white : Colors.black,
                              ),
                              onPressed: () => _addToCart(product),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
      ],
    );
  }

  Widget _buildCartContent() {
    return _cartItems.isEmpty
        ? Center(
            child: Text(
              'Sepetiniz boş',
              style: TextStyle(
                fontSize: 18,
                color: _isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          )
        : Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: _cartItems.length,
                  itemBuilder: (context, index) {
                    final product = _cartItems[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      color: _isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: _isDarkMode ? Colors.grey[800] : Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: product['imageUrl'] != null
                              ? CachedNetworkImage(
                                  imageUrl: product['imageUrl'],
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Center(
                                    child: CircularProgressIndicator(
                                      color: _isDarkMode ? Colors.white70 : Colors.blue,
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Icon(
                                    CupertinoIcons.photo,
                                    color: _isDarkMode ? Colors.white70 : Colors.grey[600],
                                  ),
                                )
                              : Icon(
                                  CupertinoIcons.photo,
                                  color: _isDarkMode ? Colors.white70 : Colors.grey[600],
                                ),
                          ),
                        ),
                        title: Text(
                          product['name'] ?? '',
                          style: TextStyle(
                            color: _isDarkMode ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          product['description'] ?? '',
                          style: TextStyle(
                            color: _isDarkMode ? Colors.white70 : Colors.grey[600],
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              product['price'] ?? '',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _isDarkMode ? const Color(0xFF1E88E5) : Colors.blue,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                CupertinoIcons.trash,
                                color: Colors.red,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _cartItems.removeAt(index);
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${product['name']} sepetten çıkarıldı'),
                                    action: SnackBarAction(
                                      label: 'Geri Al',
                                      onPressed: () {
                                        setState(() {
                                          _cartItems.insert(index, product);
                                        });
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Toplam Tutar:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          Text(
                            _calculateTotalPrice(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _isDarkMode ? const Color(0xFF1E88E5) : Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _cartItems.isEmpty ? null : _createOrder,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isDarkMode ? const Color(0xFF1A237E) : const Color(0xFF1E88E5),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Sipariş Ver',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
  }

  String _calculateTotalPrice() {
    double total = 0;
    for (var item in _cartItems) {
      // Fiyat string'inden sayısal değeri çıkar
      String priceStr = item['price'].toString().replaceAll(RegExp(r'[^0-9.]'), '');
      total += double.tryParse(priceStr) ?? 0;
    }
    return '${total.toStringAsFixed(2)} TL';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: _isDarkMode ? Colors.white : Colors.black,
        ),
        title: Text(
          'Sport City',
          style: TextStyle(
            color: _isDarkMode ? const Color(0xFFF5F5F5) : const Color(0xFF121212),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: _isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(CupertinoIcons.bell, color: _isDarkMode ? Colors.white : Colors.black),
            onPressed: _navigateToAdminLogin,
          ),
        ],
      ),
      backgroundColor: _isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      drawer: Drawer(
        elevation: 0,
        backgroundColor: _isDarkMode ? const Color(0xFF1F1F1F) : Colors.white,
        child: Column(
          children: [
            Container(
              height: 200,
              color: _isDarkMode ? const Color(0xFF121212) : Colors.white,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _isDarkMode ? Colors.white.withOpacity(0.5) : Colors.blue.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      CupertinoIcons.person_circle,
                      size: 80,
                      color: _isDarkMode ? Colors.white : Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    eposta ?? "Kullanıcı",
                    style: TextStyle(
                      color: _isDarkMode ? Colors.white : Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(
                CupertinoIcons.moon,
                color: _isDarkMode ? Colors.white : Colors.black,
              ),
              title: Text(
                'Karanlık Tema',
                style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
              ),
              onTap: _toggleTheme,
            ),
            CustomSizedBox(550),
            ListTile(
              leading: Icon(
                CupertinoIcons.arrow_left_square,
                color: _isDarkMode ? Colors.white : Colors.black,
              ),
              title: Text(
                'Çıkış Yap',
                style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
              ),
              onTap: () {
                ClearPref();
              },
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeContent(),
          _buildSearchContent(),
          _buildCartContent(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          items: [
            const BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.home),
              label: 'Ana Sayfa',
            ),
            const BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.search),
              label: 'Ara',
            ),
            BottomNavigationBarItem(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(CupertinoIcons.cart),
                  if (_cartItems.isNotEmpty)
                    Positioned(
                      right: -8,
                      top: -8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${_cartItems.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              label: 'Sepet',
            ),
          ],
          selectedItemColor: _isDarkMode ? Colors.white : const Color(0xFF1E88E5),
          unselectedItemColor: Colors.grey,
          backgroundColor: _isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        ),
      ),
    );
  }
}

Widget CustomSizedBox(double $deger) => SizedBox(
  height: $deger,
);

