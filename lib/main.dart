
import 'package:flutter/material.dart';

void main() {
  runApp(const TokoAisyahApp());
}

class TokoAisyahApp extends StatelessWidget {
  const TokoAisyahApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TOKO AISYAH',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D47A1), // Biru Tua
          primary: const Color(0xFF0D47A1),
          secondary: Colors.black,
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class Product {
  String id;
  String name;
  double price;
  int stock;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
  });
}

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, required this.quantity});
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Data Produk Awal
  final List<Product> _products = [
    Product(id: '1', name: 'Minyak Goreng 2L', price: 34000, stock: 10),
    Product(id: '2', name: 'Beras 5kg', price: 68000, stock: 2), // Stok Menipis
    Product(id: '3', name: 'Gula Pasir 1kg', price: 16000, stock: 15),
    Product(id: '4', name: 'Telur Ayam 1kg', price: 28000, stock: 3), // Stok Menipis
    Product(id: '5', name: 'Kopi Kapal Api', price: 12000, stock: 8),
  ];

  final List<CartItem> _cart = [];
  String _searchQuery = '';
  double _totalSales = 0.0; // Total Hasil Penjualan

  // Filter produk berdasarkan pencarian
  List<Product> get _filteredProducts {
    if (_searchQuery.isEmpty) {
      return _products;
    }
    return _products
        .where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  // Tambah/Edit Produk Dialog
  void _showProductDialog([Product? product]) {
    final nameController = TextEditingController(text: product?.name ?? '');
    final priceController =
        TextEditingController(text: product != null ? product.price.toStringAsFixed(0) : '');
    final stockController =
        TextEditingController(text: product != null ? product.stock.toString() : '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          product == null ? 'Tambah Barang Baru' : 'Edit Barang',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nama Barang'),
              ),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Harga (Rp)'),
              ),
              TextField(
                controller: stockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Jumlah Stok'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D47A1)),
            onPressed: () {
              final name = nameController.text.trim();
              final price = double.tryParse(priceController.text) ?? 0.0;
              final stock = int.tryParse(stockController.text) ?? 0;

              if (name.isNotEmpty && price > 0) {
                setState(() {
                  if (product == null) {
                    _products.add(Product(
                      id: DateTime.now().toString(),
                      name: name,
                      price: price,
                      stock: stock,
                    ));
                  } else {
                    product.name = name;
                    product.price = price;
                    product.stock = stock;
                  }
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Simpan', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  // Hapus Barang
  void _deleteProduct(String id) {
    setState(() {
      _products.removeWhere((p) => p.id == id);
    });
  }

  // Tambah ke Keranjang
  void _addToCart(Product product) {
    if (product.stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stok habis!'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      final index = _cart.indexWhere((item) => item.product.id == product.id);
      if (index >= 0) {
        if (_cart[index].quantity < product.stock) {
          _cart[index].quantity++;
        }
      } else {
        _cart.add(CartItem(product: product, quantity: 1));
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} masuk keranjang'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  // Checkout
  void _checkout() {
    double currentCartTotal = 0;
    for (var item in _cart) {
      currentCartTotal += item.product.price * item.quantity;
      item.product.stock -= item.quantity;
    }

    setState(() {
      _totalSales += currentCartTotal;
      _cart.clear();
    });

    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Transaksi Berhasil!'),
        content: Text('Total Pembayaran: Rp ${currentCartTotal.toStringAsFixed(0)}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('TOKO AISYAH', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            Text('by Joko Pranando', style: TextStyle(fontSize: 12, color: Colors.blueAccent)),
          ],
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart, color: Colors.white),
                onPressed: () => _showCartBottomSheet(),
              ),
              if (_cart.isNotEmpty)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${_cart.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                )
            ],
          )
        ],
      ),
      body: Column(
        children: [
          // Banner Total Penjualan
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            color: const Color(0xFF0D47A1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Penjualan', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    Text('Hasil Toko Hari Ini', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
                Text(
                  'Rp ${_totalSales.toStringAsFixed(0)}',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                )
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Cari nama barang...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF0D47A1)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF0D47A1)),
                ),
              ),
            ),
          ),

          // List Produk
          Expanded(
            child: _filteredProducts.isEmpty
                ? const Center(child: Text('Barang tidak ditemukan'))
                : ListView.builder(
                    itemCount: _filteredProducts.length,
                    itemBuilder: (ctx, index) {
                      final p = _filteredProducts[index];
                      final isLowStock = p.stock <= 3;

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            color: isLowStock ? Colors.red : Colors.transparent,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          title: Text(
                            p.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Rp ${p.price.toStringAsFixed(0)}',
                                  style: const TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isLowStock ? Colors.red.shade100 : Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      isLowStock ? 'Stok Menipis: ${p.stock}' : 'Stok: ${p.stock}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isLowStock ? Colors.red.shade900 : const Color(0xFF0D47A1),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.black54),
                                onPressed: () => _showProductDialog(p),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.black54),
                                onPressed: () => _deleteProduct(p.id),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_shopping_cart, color: Color(0xFF0D47A1)),
                                onPressed: () => _addToCart(p),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0D47A1),
        onPressed: () => _showProductDialog(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showCartBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        double cartTotal = _cart.fold(0, (sum, item) => sum + (item.product.price * item.quantity));

        return Container(
          padding: const EdgeInsets.all(16),
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Keranjang Belanja',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              const Divider(),
              Expanded(
                child: _cart.isEmpty
                    ? const Center(child: Text('Keranjang kosong'))
                    : ListView.builder(
                        itemCount: _cart.length,
                        itemBuilder: (ctx, i) {
                          final item = _cart[i];
                          return ListTile(
                            title: Text(item.product.name),
                            subtitle: Text('Rp ${item.product.price.toStringAsFixed(0)} x ${item.quantity}'),
                            trailing: Text(
                              'Rp ${(item.product.price * item.quantity).toStringAsFixed(0)}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          );
                        },
                      ),
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total: Rp ${cartTotal.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D47A1)),
                    onPressed: _cart.isEmpty ? null : _checkout,
                    child: const Text('Selesaikan Transaksi', style: TextStyle(color: Colors.white)),
                  )
                ],
              )
            ],
          ),
        );
      },
    );
  }
}
