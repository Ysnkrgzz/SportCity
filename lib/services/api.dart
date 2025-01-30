import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:async';

class ApiService {
  // Base URL'i .env dosyasından al
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000';
  
  // Önbellekleme için
  static final Map<String, dynamic> _cache = {};
  static const Duration _cacheDuration = Duration(minutes: 5);
  static const Duration _timeoutDuration = Duration(seconds: 10);
  
  // HTTP Client'ı tekrar kullanmak için
  final http.Client _client = http.Client();

  // Önbellek kontrolü
  bool _isCacheValid(String key) {
    if (!_cache.containsKey(key)) return false;
    final cacheTime = _cache[key]['time'] as DateTime;
    return DateTime.now().difference(cacheTime) < _cacheDuration;
  }

  // Önbellekten veri alma
  dynamic _getFromCache(String key) {
    return _cache[key]['data'];
  }

  // Önbelleğe veri kaydetme
  void _saveToCache(String key, dynamic data) {
    _cache[key] = {
      'data': data,
      'time': DateTime.now(),
    };
  }

  // HTTP GET isteği için yardımcı metod
  Future<dynamic> _get(String endpoint) async {
    if (_isCacheValid(endpoint)) {
      return _getFromCache(endpoint);
    }

    try {
      final response = await _client
          .get(Uri.parse('$baseUrl$endpoint'))
          .timeout(_timeoutDuration);
          
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _saveToCache(endpoint, data);
        return data;
      } else if (response.statusCode == 404) {
        throw Exception('Kaynak bulunamadı');
      } else if (response.statusCode >= 500) {
        throw Exception('Sunucu hatası');
      } else {
        throw Exception('İstek başarısız: ${response.statusCode}');
      }
    } on http.ClientException {
      throw Exception('Sunucuya bağlanılamıyor');
    } on TimeoutException {
      throw Exception('Bağlantı zaman aşımına uğradı');
    } catch (e) {
      throw Exception('Bağlantı hatası: $e');
    }
  }

  // Tüm ürünleri getir
  Future<List<Map<String, dynamic>>> getProducts() async {
    final data = await _get('/products');
    return List<Map<String, dynamic>>.from(data);
  }

  // Kategoriye göre ürünleri getir
  Future<List<Map<String, dynamic>>> getProductsByCategory(String category) async {
    final data = await _get('/products/category/$category');
    return List<Map<String, dynamic>>.from(data);
  }

  // Ürün ara
  Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    // Arama için önbellek kullanmıyoruz çünkü her sorgu farklı olabilir
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/products/search?q=$query')
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Arama yapılırken hata oluştu');
      }
    } catch (e) {
      throw Exception('Bağlantı hatası: $e');
    }
  }

  // Tek bir ürünün detaylarını getir
  Future<Map<String, dynamic>> getProductDetails(String productId) async {
    final data = await _get('/products/$productId');
    return Map<String, dynamic>.from(data);
  }

  // Kategorileri getir
  Future<List<String>> getCategories() async {
    final data = await _get('/categories');
    return List<String>.from(data);
  }

  // POST, PUT ve DELETE işlemleri için önbelleği temizle
  void _clearCache() {
    _cache.clear();
  }

  // Ürün güncelle
  Future<Map<String, dynamic>> updateProduct(String productId, Map<String, dynamic> updatedProduct) async {
    try {
      final response = await _client.put(
        Uri.parse('$baseUrl/products/$productId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(updatedProduct),
      );
      
      if (response.statusCode == 200) {
        _clearCache(); // Önbelleği temizle
        return json.decode(response.body);
      } else {
        throw Exception('Ürün güncellenirken hata oluştu');
      }
    } catch (e) {
      throw Exception('Bağlantı hatası: $e');
    }
  }

  // Ürün ekle
  Future<Map<String, dynamic>> addProduct(Map<String, dynamic> product) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/products'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(product),
      );

      if (response.statusCode == 201) {
        _clearCache(); // Önbelleği temizle
        return jsonDecode(response.body);
      } else {
        throw Exception('Ürün eklenirken hata oluştu');
      }
    } catch (e) {
      throw Exception('Bağlantı hatası: $e');
    }
  }

  // Ürün sil
  Future<void> deleteProduct(String productId) async {
    try {
      final response = await _client.delete(
        Uri.parse('$baseUrl/products/$productId'),
      );
      
      if (response.statusCode == 200) {
        _clearCache(); // Önbelleği temizle
      } else {
        throw Exception('Ürün silinirken hata oluştu');
      }
    } catch (e) {
      throw Exception('Bağlantı hatası: $e');
    }
  }

  // Kategori ekle
  Future<void> addCategory(String category) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/categories'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'name': category}),
      );
      
      if (response.statusCode != 201) {
        throw Exception('Kategori eklenirken hata oluştu');
      }
      _clearCache(); // Önbelleği temizle
    } catch (e) {
      throw Exception('Bağlantı hatası: $e');
    }
  }

  // Kategori güncelle
  Future<void> updateCategory(String oldCategory, String newCategory) async {
    try {
      final response = await _client.put(
        Uri.parse('$baseUrl/categories/$oldCategory'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'name': newCategory}),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Kategori güncellenirken hata oluştu');
      }
      _clearCache(); // Önbelleği temizle
    } catch (e) {
      throw Exception('Bağlantı hatası: $e');
    }
  }

  // Kategori sil
  Future<void> deleteCategory(String category) async {
    try {
      final response = await _client.delete(
        Uri.parse('$baseUrl/categories/$category'),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Kategori silinirken hata oluştu');
      }
      _clearCache(); // Önbelleği temizle
    } catch (e) {
      throw Exception('Bağlantı hatası: $e');
    }
  }

  // Sipariş oluştur
  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> order) async {
    try {
      print('Gönderilen sipariş verisi: ${json.encode(order)}'); // Debug için
      
      final response = await _client.post(
        Uri.parse('$baseUrl/orders'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'items': order['items'],
          'totalPrice': order['totalPrice'],
          'status': order['status'],
          'orderDate': order['orderDate'],
          'userEmail': order['userEmail'],
        }),
      );
      
      print('Sunucu yanıtı: ${response.statusCode} - ${response.body}'); // Debug için
      
      if (response.statusCode == 201) {
        _clearCache();
        return json.decode(response.body);
      } else {
        throw Exception('Sipariş oluşturulurken hata oluştu: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Hata detayı: $e'); // Debug için
      throw Exception('Bağlantı hatası: $e');
    }
  }

  // Siparişleri getir
  Future<List<Map<String, dynamic>>> getOrders() async {
    final data = await _get('/orders');
    return List<Map<String, dynamic>>.from(data);
  }

  // Sipariş durumunu güncelle
  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      final response = await _client.put(
        Uri.parse('$baseUrl/orders/$orderId/status'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'status': status}),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Sipariş durumu güncellenirken hata oluştu');
      }
      _clearCache();
    } catch (e) {
      throw Exception('Bağlantı hatası: $e');
    }
  }

  // Servis kapanırken HTTP client'ı kapat
  void dispose() {
    _client.close();
  }
}
