import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../services/api.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

class AdminPanelScreen extends StatefulWidget {
  final VoidCallback onProductUpdated;
  final VoidCallback onCategoryUpdated;
  const AdminPanelScreen({
    Key? key,
    required this.onProductUpdated,
    required this.onCategoryUpdated,
  }) : super(key: key);

  @override
  _AdminPanelScreenState createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  List<Map<String, dynamic>> _products = [];
  List<String> _categories = [];
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  int _selectedIndex = 0; // 0: Ürünler, 1: Kategoriler, 2: Siparişler
  late final ApiService _apiService;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _apiService = Provider.of<ApiService>(context, listen: false);
    _loadInitialData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await Future.wait([
        _loadProducts(),
        _loadCategories(),
        _loadOrders(),
      ]);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadProducts() async {
    if (!mounted) return;
    
    try {
      final products = await _apiService.getProducts();
      if (!mounted) return;
      
      setState(() {
        _products = products;
      });
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ürünler yüklenirken hata oluştu: $e')),
      );
    }
  }

  Future<void> _loadCategories() async {
    if (!mounted) return;
    
    try {
      final categories = await _apiService.getCategories();
      if (!mounted) return;
      
      setState(() {
        _categories = categories;
      });
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kategoriler yüklenirken hata oluştu: $e')),
      );
    }
  }

  Future<void> _loadOrders() async {
    if (!mounted) return;
    
    try {
      final orders = await _apiService.getOrders();
      if (!mounted) return;
      
      setState(() {
        _orders = orders;
      });
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Siparişler yüklenirken hata oluştu: $e')),
      );
    }
  }

  Future<void> _updateOrderStatus(String orderId, String status) async {
    try {
      await _apiService.updateOrderStatus(orderId, status);
      await _loadOrders();
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sipariş durumu güncellendi')),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata oluştu: $e')),
      );
    }
  }

  void _addProduct() {
    showDialog(
      context: context,
      builder: (context) => ProductAddDialog(
        categories: _categories,
        onSave: (newProduct) async {
          try {
            await _apiService.addProduct(newProduct);
            Navigator.pop(context);
            await _loadProducts();
            widget.onProductUpdated();
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ürün başarıyla eklendi')),
            );
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Hata oluştu: $e')),
            );
          }
        },
      ),
    );
  }

  void _editProduct(Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (context) => ProductEditDialog(
        product: product,
        categories: _categories,
        onSave: (updatedProduct) async {
          try {
            await _apiService.updateProduct(updatedProduct['id'], updatedProduct);
            Navigator.pop(context);
            await _loadProducts();
            widget.onProductUpdated();
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ürün başarıyla güncellendi')),
            );
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Hata oluştu: $e')),
            );
          }
        },
      ),
    );
  }

  Future<void> _deleteProduct(String productId) async {
    try {
      await _apiService.deleteProduct(productId);
      await _loadProducts();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ürün başarıyla silindi')),
      );
      widget.onProductUpdated();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata oluştu: $e')),
      );
    }
  }

  void _addCategory() {
    showDialog(
      context: context,
      builder: (context) => CategoryAddDialog(
        onSave: (newCategory) async {
          try {
            await _apiService.addCategory(newCategory);
            if (!mounted) return;
            Navigator.pop(context);
            setState(() {
              _isLoading = true;
            });
            await Future.wait([
              _loadCategories(),
              _loadProducts(),
            ]);
            setState(() {
              _isLoading = false;
            });
            widget.onCategoryUpdated();
            widget.onProductUpdated();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Kategori başarıyla eklendi')),
            );
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Hata oluştu: $e')),
            );
          }
        },
      ),
    );
  }

  void _editCategory(String category) {
    showDialog(
      context: context,
      builder: (context) => CategoryEditDialog(
        category: category,
        onSave: (oldCategory, newCategory) async {
          try {
            await _apiService.updateCategory(oldCategory, newCategory);
            if (!mounted) return;
            Navigator.pop(context);
            setState(() {
              _isLoading = true;
            });
            await Future.wait([
              _loadCategories(),
              _loadProducts(),
            ]);
            setState(() {
              _isLoading = false;
            });
            widget.onCategoryUpdated();
            widget.onProductUpdated();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Kategori başarıyla güncellendi')),
            );
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Hata oluştu: $e')),
            );
          }
        },
      ),
    );
  }

  Future<void> _deleteCategory(int index) async {
    final category = _categories[index];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kategoriyi Sil'),
        content: const Text('Bu kategoriyi silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _apiService.deleteCategory(category);
                await Future.wait([
                  _loadCategories(),
                  _loadProducts(),
                ]);
                if (mounted) {
                  Navigator.pop(context);
                  widget.onCategoryUpdated();
                  widget.onProductUpdated();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Kategori başarıyla silindi')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Hata oluştu: $e')),
                  );
                }
              }
            },
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildProductList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: product['imageUrl'] != null
                  ? CachedNetworkImage(
                      imageUrl: product['imageUrl'],
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      errorWidget: (context, url, error) => const Icon(CupertinoIcons.photo),
                    )
                  : const Icon(CupertinoIcons.photo),
              ),
            ),
            title: Text(product['name'] ?? ''),
            subtitle: Text(
              '${product['price']} - ${product['category']}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(CupertinoIcons.pencil),
                  onPressed: () => _editProduct(product),
                ),
                IconButton(
                  icon: const Icon(CupertinoIcons.delete),
                  onPressed: () => _deleteProduct(product['id']),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryList() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const Icon(CupertinoIcons.tag),
                  title: Text(category),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(CupertinoIcons.pencil),
                        onPressed: () => _editCategory(category),
                      ),
                      IconButton(
                        icon: const Icon(CupertinoIcons.delete),
                        onPressed: () => _deleteCategory(index),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: _addCategory,
            icon: const Icon(CupertinoIcons.add),
            label: const Text('Yeni Kategori Ekle'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderList() {
    return ListView.builder(
      itemCount: _orders.length,
      itemBuilder: (context, index) {
        final order = _orders[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ExpansionTile(
            title: Text('Sipariş #${order['id']}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tarih: ${DateTime.parse(order['orderDate']).toString()}'),
                Text('Durum: ${order['status']}'),
                Text('Toplam: ${order['totalPrice']}'),
              ],
            ),
            children: [
              ...List.generate(
                (order['items'] as List).length,
                (itemIndex) {
                  final item = order['items'][itemIndex];
                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: item['imageUrl'] != null
                          ? CachedNetworkImage(
                              imageUrl: item['imageUrl'],
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              errorWidget: (context, url, error) => const Icon(CupertinoIcons.photo),
                            )
                          : const Icon(CupertinoIcons.photo),
                      ),
                    ),
                    title: Text(item['name']),
                    trailing: Text(item['price']),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () => _updateOrderStatus(order['id'], 'Onaylandı'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: const Text('Onayla'),
                    ),
                    ElevatedButton(
                      onPressed: () => _updateOrderStatus(order['id'], 'İptal Edildi'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('İptal Et'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedIndex == 0 
          ? 'Ürün Yönetimi' 
          : _selectedIndex == 1 
            ? 'Kategori Yönetimi'
            : 'Sipariş Yönetimi'
        ),
        backgroundColor: isDarkMode ? const Color(0xFF1A237E) : const Color(0xFF1E88E5),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.square_arrow_right),
            onPressed: () {
              widget.onProductUpdated();
              widget.onCategoryUpdated();
              context.go('/home');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() => _selectedIndex = 0),
                    icon: const Icon(CupertinoIcons.cube_box, size: 20),
                    label: const Text(
                      'Ürünler',
                      style: TextStyle(fontSize: 15),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedIndex == 0
                          ? (isDarkMode ? const Color(0xFF1A237E) : const Color(0xFF1E88E5))
                          : Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() => _selectedIndex = 1),
                    icon: const Icon(CupertinoIcons.tag, size: 20),
                    label: const Text(
                      'Kategoriler',
                      style: TextStyle(fontSize: 12.6),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedIndex == 1
                          ? (isDarkMode ? const Color(0xFF1A237E) : const Color(0xFF1E88E5))
                          : Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() => _selectedIndex = 2),
                    icon: const Icon(CupertinoIcons.cart, size: 20),
                    label: const Text(
                      'Siparişler',
                      style: TextStyle(fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedIndex == 2
                          ? (isDarkMode ? const Color(0xFF1A237E) : const Color(0xFF1E88E5))
                          : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _selectedIndex == 0 
              ? _buildProductList() 
              : _selectedIndex == 1 
                ? _buildCategoryList()
                : _buildOrderList(),
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: _addProduct,
              backgroundColor: isDarkMode ? const Color(0xFF1A237E) : const Color(0xFF1E88E5),
              child: const Icon(CupertinoIcons.add),
            )
          : null,
    );
  }
}

class ProductEditDialog extends StatefulWidget {
  final Map<String, dynamic> product;
  final List<String> categories;
  final Function(Map<String, dynamic>) onSave;

  const ProductEditDialog({
    Key? key,
    required this.product,
    required this.categories,
    required this.onSave,
  }) : super(key: key);

  @override
  _ProductEditDialogState createState() => _ProductEditDialogState();
}

class _ProductEditDialogState extends State<ProductEditDialog> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController nameController;
  late final TextEditingController descriptionController;
  late final TextEditingController priceController;
  late final TextEditingController imageUrlController;
  late String selectedCategory;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.product['name']);
    descriptionController = TextEditingController(text: widget.product['description']);
    priceController = TextEditingController(text: widget.product['price'].toString());
    imageUrlController = TextEditingController(text: widget.product['imageUrl']);
    selectedCategory = widget.product['category'] ?? (widget.categories.isNotEmpty ? widget.categories.first : '');
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ürünü Düzenle'),
      content: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Ürün Adı',
                  icon: Icon(CupertinoIcons.tag),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen ürün adı girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Açıklama',
                  icon: Icon(CupertinoIcons.text_alignleft),
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen açıklama girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Fiyat',
                  icon: Icon(CupertinoIcons.money_dollar),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen fiyat girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              if (widget.categories.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(CupertinoIcons.square_grid_2x2),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButton<String>(
                        value: selectedCategory,
                        isExpanded: true,
                        hint: const Text('Kategori Seçin'),
                        items: widget.categories.map((String category) {
                          return DropdownMenuItem<String>(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              selectedCategory = newValue;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: imageUrlController,
                decoration: const InputDecoration(
                  labelText: 'Resim URL',
                  icon: Icon(CupertinoIcons.photo),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen resim URL\'si girin';
                  }
                  if (!value.startsWith('http')) {
                    return 'Lütfen geçerli bir URL girin (http:// veya https://)';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        TextButton(
          onPressed: () {
            if (formKey.currentState?.validate() ?? false) {
              final updatedProduct = {
                'id': widget.product['id'],
                'name': nameController.text,
                'description': descriptionController.text,
                'price': priceController.text,
                'category': selectedCategory,
                'imageUrl': imageUrlController.text,
              };
              widget.onSave(updatedProduct);
              Navigator.pop(context);
            }
          },
          child: const Text('Kaydet'),
        ),
      ],
    );
  }
}

class ProductAddDialog extends StatefulWidget {
  final List<String> categories;
  final Function(Map<String, dynamic>) onSave;

  const ProductAddDialog({
    Key? key,
    required this.categories,
    required this.onSave,
  }) : super(key: key);

  @override
  _ProductAddDialogState createState() => _ProductAddDialogState();
}

class _ProductAddDialogState extends State<ProductAddDialog> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController nameController;
  late final TextEditingController descriptionController;
  late final TextEditingController priceController;
  late final TextEditingController imageUrlController;
  late String selectedCategory;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    descriptionController = TextEditingController();
    priceController = TextEditingController();
    imageUrlController = TextEditingController();
    selectedCategory = widget.categories.isNotEmpty ? widget.categories.first : '';
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Yeni Ürün Ekle'),
      content: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Ürün Adı',
                  icon: Icon(CupertinoIcons.tag),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen ürün adı girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Açıklama',
                  icon: Icon(CupertinoIcons.text_alignleft),
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen açıklama girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Fiyat',
                  icon: Icon(CupertinoIcons.money_dollar),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen fiyat girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              if (widget.categories.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(CupertinoIcons.square_grid_2x2),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButton<String>(
                        value: selectedCategory,
                        isExpanded: true,
                        hint: const Text('Kategori Seçin'),
                        items: widget.categories.map((String category) {
                          return DropdownMenuItem<String>(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              selectedCategory = newValue;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: imageUrlController,
                decoration: const InputDecoration(
                  labelText: 'Resim URL',
                  icon: Icon(CupertinoIcons.photo),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen resim URL\'si girin';
                  }
                  if (!value.startsWith('http')) {
                    return 'Lütfen geçerli bir URL girin (http:// veya https://)';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        TextButton(
          onPressed: () {
            if (formKey.currentState?.validate() ?? false) {
              final newProduct = {
                'name': nameController.text,
                'description': descriptionController.text,
                'price': priceController.text,
                'category': selectedCategory,
                'imageUrl': imageUrlController.text,
              };
              widget.onSave(newProduct);
              Navigator.pop(context);
            }
          },
          child: const Text('Ekle'),
        ),
      ],
    );
  }
}

class CategoryAddDialog extends StatefulWidget {
  final Function(String) onSave;

  const CategoryAddDialog({
    Key? key,
    required this.onSave,
  }) : super(key: key);

  @override
  _CategoryAddDialogState createState() => _CategoryAddDialogState();
}

class _CategoryAddDialogState extends State<CategoryAddDialog> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController categoryController;

  @override
  void initState() {
    super.initState();
    categoryController = TextEditingController();
  }

  @override
  void dispose() {
    categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Yeni Kategori Ekle'),
      content: Form(
        key: formKey,
        child: TextFormField(
          controller: categoryController,
          decoration: const InputDecoration(
            labelText: 'Kategori Adı',
            icon: Icon(CupertinoIcons.tag),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Lütfen kategori adı girin';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        TextButton(
          onPressed: () {
            if (formKey.currentState?.validate() ?? false) {
              widget.onSave(categoryController.text);
              Navigator.pop(context);
            }
          },
          child: const Text('Ekle'),
        ),
      ],
    );
  }
}

class CategoryEditDialog extends StatefulWidget {
  final String category;
  final Function(String, String) onSave;

  const CategoryEditDialog({
    Key? key,
    required this.category,
    required this.onSave,
  }) : super(key: key);

  @override
  _CategoryEditDialogState createState() => _CategoryEditDialogState();
}

class _CategoryEditDialogState extends State<CategoryEditDialog> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController categoryController;

  @override
  void initState() {
    super.initState();
    categoryController = TextEditingController(text: widget.category);
  }

  @override
  void dispose() {
    categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Kategoriyi Düzenle'),
      content: Form(
        key: formKey,
        child: TextFormField(
          controller: categoryController,
          decoration: const InputDecoration(
            labelText: 'Kategori Adı',
            icon: Icon(CupertinoIcons.tag),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Lütfen kategori adı girin';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        TextButton(
          onPressed: () {
            if (formKey.currentState?.validate() ?? false) {
              widget.onSave(widget.category, categoryController.text);
              Navigator.pop(context);
            }
          },
          child: const Text('Kaydet'),
        ),
      ],
    );
  }
} 