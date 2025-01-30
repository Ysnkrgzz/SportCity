const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');
const app = express();

app.use(cors());
app.use(express.json());

const dataFilePath = path.join(__dirname, 'products.json');
const categoriesFilePath = path.join(__dirname, 'categories.json');

// Kategorileri dosyadan oku
function loadCategories() {
  try {
    if (fs.existsSync(categoriesFilePath)) {
      const data = fs.readFileSync(categoriesFilePath, 'utf8');
      const categories = JSON.parse(data);
      // Tekrar eden kategorileri temizle
      return [...new Set(categories)];
    }
    return ['Ayakkabı', 'Giyim', 'Ekipman'];
  } catch (error) {
    console.error('Kategori okuma hatası:', error);
    return ['Ayakkabı', 'Giyim', 'Ekipman'];
  }
}

// Kategorileri dosyaya kaydet
function saveCategories(categories) {
  try {
    // Tekrar eden kategorileri temizle
    const uniqueCategories = [...new Set(categories)];
    fs.writeFileSync(categoriesFilePath, JSON.stringify(uniqueCategories, null, 2));
  } catch (error) {
    console.error('Kategori yazma hatası:', error);
  }
}

// İlk çalıştırmada örnek kategoriler
let categories = loadCategories();

// Verileri dosyadan oku
function loadProducts() {
  try {
    if (fs.existsSync(dataFilePath)) {
      const data = fs.readFileSync(dataFilePath, 'utf8');
      return JSON.parse(data);
    }
    return [];
  } catch (error) {
    console.error('Veri okuma hatası:', error);
    return [];
  }
}

// Verileri dosyaya kaydet
function saveProducts(products) {
  try {
    fs.writeFileSync(dataFilePath, JSON.stringify(products, null, 2));
  } catch (error) {
    console.error('Veri yazma hatası:', error);
  }
}

// İlk çalıştırmada ürünleri yükle
let products = loadProducts();

// Siparişler için veri yapısı
let orders = [];

// Sipariş oluştur
app.post('/orders', (req, res) => {
  const order = {
    id: Date.now().toString(),
    ...req.body,
  };
  orders.push(order);
  saveOrders(orders);
  res.status(201).json(order);
});

// Tüm siparişleri getir
app.get('/orders', (req, res) => {
  res.json(orders);
});

// Sipariş durumunu güncelle
app.put('/orders/:id/status', (req, res) => {
  const { id } = req.params;
  const { status } = req.body;
  
  const orderIndex = orders.findIndex(order => order.id === id);
  if (orderIndex === -1) {
    return res.status(404).json({ error: 'Sipariş bulunamadı' });
  }
  
  orders[orderIndex].status = status;
  saveOrders(orders);
  res.json(orders[orderIndex]);
});

// Siparişleri kaydet
function saveOrders(orders) {
  fs.writeFileSync(
    path.join(__dirname, 'orders.json'),
    JSON.stringify(orders, null, 2)
  );
}

// Siparişleri yükle
function loadOrders() {
  try {
    const data = fs.readFileSync(path.join(__dirname, 'orders.json'));
    orders = JSON.parse(data);
  } catch (error) {
    orders = [];
    saveOrders(orders);
  }
}

// Başlangıçta siparişleri yükle
loadOrders();

// Ana sayfa
app.get('/', (req, res) => {
  res.json({
    message: 'Sport City API',
    endpoints: {
      getAllProducts: '/products',
      getProductsByCategory: '/products/category/:category',
      searchProducts: '/products/search?q=query',
      getProductDetails: '/products/:id'
    }
  });
});

// Tüm ürünleri getir
app.get('/products', (req, res) => {
  res.json(products);
});

// Kategoriye göre ürünleri getir
app.get('/products/category/:category', (req, res) => {
  const category = req.params.category;
  const filteredProducts = products.filter(product => 
    product.category.toLowerCase() === category.toLowerCase()
  );
  res.json(filteredProducts);
});

// Ürün ara
app.get('/products/search', (req, res) => {
  const query = req.query.q ? req.query.q.toLowerCase() : '';
  const searchResults = products.filter(product => 
    product.name.toLowerCase().includes(query) ||
    product.description.toLowerCase().includes(query) ||
    product.category.toLowerCase().includes(query)
  );
  res.json(searchResults);
});

// Tek bir ürünün detaylarını getir
app.get('/products/:id', (req, res) => {
  const product = products.find(p => p.id === req.params.id);
  if (product) {
    res.json(product);
  } else {
    res.status(404).json({ message: 'Ürün bulunamadı' });
  }
});

// Ürün güncelle
app.put('/products/:id', (req, res) => {
  const productId = req.params.id;
  const updatedProduct = req.body;
  
  const index = products.findIndex(p => p.id === productId);
  if (index !== -1) {
    products[index] = { ...products[index], ...updatedProduct };
    saveProducts(products); // Değişiklikleri kaydet
    res.json(products[index]);
  } else {
    res.status(404).json({ message: 'Ürün bulunamadı' });
  }
});

// Yeni ürün ekleme
app.post('/products', (req, res) => {
  const newProduct = {
    id: (products.length + 1).toString(),
    name: req.body.name,
    description: req.body.description,
    price: req.body.price,
    category: req.body.category,
    imageUrl: req.body.imageUrl,
  };

  products.push(newProduct);
  saveProducts(products); // Değişiklikleri kaydet
  res.status(201).json(newProduct);
});

// Ürün silme
app.delete('/products/:id', (req, res) => {
  const productId = req.params.id;
  const index = products.findIndex(p => p.id === productId);
  
  if (index !== -1) {
    products.splice(index, 1);
    saveProducts(products); // Değişiklikleri kaydet
    res.json({ message: 'Ürün başarıyla silindi' });
  } else {
    res.status(404).json({ message: 'Ürün bulunamadı' });
  }
});

// Tüm kategorileri getir
app.get('/categories', (req, res) => {
  res.json(categories);
});

// Yeni kategori ekle
app.post('/categories', (req, res) => {
  const newCategory = req.body.name;
  // Kategori adını temizle ve kontrol et
  const trimmedCategory = newCategory.trim();
  if (!trimmedCategory) {
    return res.status(400).json({ message: 'Geçersiz kategori adı' });
  }
  
  if (!categories.includes(trimmedCategory)) {
    categories.push(trimmedCategory);
    saveCategories(categories);
    res.status(201).json({ message: 'Kategori başarıyla eklendi' });
  } else {
    res.status(400).json({ message: 'Bu kategori zaten mevcut' });
  }
});

// Kategori güncelle
app.put('/categories/:oldCategory', (req, res) => {
  const oldCategory = req.params.oldCategory;
  const newCategory = req.body.name;
  const index = categories.indexOf(oldCategory);
  
  if (index !== -1) {
    categories[index] = newCategory;
    
    // İlgili ürünlerin kategorilerini de güncelle
    products.forEach(product => {
      if (product.category === oldCategory) {
        product.category = newCategory;
      }
    });
    
    saveCategories(categories);
    saveProducts(products);
    res.json({ message: 'Kategori başarıyla güncellendi' });
  } else {
    res.status(404).json({ message: 'Kategori bulunamadı' });
  }
});

// Kategori sil
app.delete('/categories/:category', (req, res) => {
  const categoryToDelete = req.params.category;
  const index = categories.indexOf(categoryToDelete);
  
  if (index !== -1) {
    categories.splice(index, 1);
    
    // İlgili kategorideki ürünleri de sil
    products = products.filter(product => product.category !== categoryToDelete);
    
    saveCategories(categories);
    saveProducts(products);
    res.json({ message: 'Kategori başarıyla silindi' });
  } else {
    res.status(404).json({ message: 'Kategori bulunamadı' });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
}); 