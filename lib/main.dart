import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
          seedColor: const Color(0xFF0D47A1),
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

class CartItem {
  final String id;
  final String name;
  final double price;
  int quantity;
  int currentStock;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.currentStock,
  });
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final CollectionReference _productsRef =
      FirebaseFirestore.instance.collection('products');
  final DocumentReference _salesRef =
      FirebaseFirestore.instance.collection('reports').doc('daily_sales');

  final List<CartItem> _cart = [];
  String _searchQuery = '';

  // Tambah/Edit Produk ke Cloud Firestore
  void _showProductDialog([DocumentSnapshot? doc]) {
    final nameController = TextEditingController(text: doc?['name'] ?? '');
    final priceController = TextEditingController(
        text: doc != null ? doc['price'].toStringAsFixed(0) : '');
    final stockController =
        TextEditingController(text: doc != null ? doc['stock'].toString() : '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          doc == null ? 'Tambah Barang Baru' : 'Edit Barang',
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
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
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D47A1)),
            onPressed: () async {
              final name = nameController.text.trim();
              final price = double.tryParse(priceController.text) ?? 0.0;
              final stock = int.tryParse(stockController.text) ?? 0;

              if (name.isNotEmpty && price > 0) {
                if (doc == null) {
                  await _productsRef.add({
                    'name': name,
                    'price': price,
                    'stock': stock,
                    'created_at': FieldValue.serverTimestamp(),
                  });
                } else {
                  await _productsRef.doc(doc.id).update({
                    'name': name,
                    'price': price,
                    'stock': stock,
                  });
                }
                if (mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Simpan', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  void _deleteProduct(String id) async {
    await _productsRef.doc(id).delete();
  }

  void _addToCart(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final int stock = data['stock'] ?? 0;

    if (stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Stok habis!'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      final index = _cart.indexWhere((item) => item.id == doc.id);
      if (index >= 0) {
        if (_cart[index].quantity < stock) {
          _cart[index].quantity++;
        }
      } else {
        _cart.add(CartItem(
          id: doc.id,
          name: data['name'],
          price: (data['price'] as num).toDouble(),
          quantity: 1,
          currentStock: stock,
        ));
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${data['name']} masuk keranjang'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  // Transaction Checkout Online
  void _checkout() async {
    double currentCartTotal = 0;

    WriteBatch batch = FirebaseFirestore.instance.batch();

    for (var item in _cart) {
      currentCartTotal += item.price * item.quantity;
      DocumentReference pRef = _productsRef.doc(item.id);
      batch.update(pRef, {'stock': FieldValue.increment(-item.quantity)});
    }

    batch.set(
        _salesRef,
        {
          'total_sales': FieldValue.increment(currentCartTotal),
        },
        SetOptions(merge: true));

    await batch.commit();

    setState(() {
      _cart.clear();
    });

    if (mounted) {
      Navigator.pop(context);
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Transaksi Berhasil!'),
          content: Text(
              'Total Pembayaran: Rp ${currentCartTotal.toStringAsFixed(0)}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            )
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('TOKO AISYAH (ONLINE)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('by Joko Pranando',
                style: TextStyle(fontSize: 12, color: Colors.blueAccent)),
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
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                )
            ],
          )
        ],
      ),
      body: Column(
        children: [
          // Banner Real-time Total Penjualan Online
          StreamBuilder<DocumentSnapshot>(
            stream: _salesRef.snapshots(),
            builder: (context, snapshot) {
              double totalSales = 0.0;
              if (snapshot.hasData && snapshot.data!.exists) {
                final data = snapshot.data!.data() as Map<String, dynamic>?;
                totalSales = (data?['total_sales'] ?? 0.0).toDouble();
              }

              return Container(
                padding: const EdgeInsets.all(16),
                width: double.infinity,
                color: const Color(0xFF0D47A1),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Penjualan Online',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 13)),
                        Text('Hasil Toko Hari Ini',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Text(
                      'Rp ${totalSales.toStringAsFixed(0)}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              );
            },
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Cari nama barang...',
                prefixIcon:
                    const Icon(Icons.search, color: Color(0xFF0D47A1)),
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

          // StreamBuilder Real-time List Produk dari Firebase Cloud
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _productsRef.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text('Belum ada produk di database online'));
                }

                final docs = snapshot.data!.docs.where((doc) {
                  final name = (doc['name'] ?? '').toString().toLowerCase();
                  return name.contains(_searchQuery);
                }).toList();

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (ctx, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final stock = data['stock'] ?? 0;
                    final isLowStock = stock <= 3;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
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
                          data['name'] ?? '',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Rp ${(data['price'] ?? 0).toStringAsFixed(0)}',
                                style: const TextStyle(
                                    color: Color(0xFF0D47A1),
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isLowStock
                                    ? Colors.red.shade100
                                    : Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isLowStock
                                    ? 'Stok Menipis: $stock'
                                    : 'Stok: $stock',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isLowStock
                                      ? Colors.red.shade900
                                      : const Color(0xFF0D47A1),
                                ),
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit,
                                  color: Colors.black54),
                              onPressed: () => _showProductDialog(doc),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  color: Colors.black54),
                              onPressed: () => _deleteProduct(doc.id),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_shopping_cart,
                                  color: Color(0xFF0D47A1)),
                              onPressed: () => _addToCart(doc),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
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
        double cartTotal =
            _cart.fold(0, (sum, item) => sum + (item.price * item.quantity));

        return Container(
          padding: const EdgeInsets.all(16),
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Keranjang Belanja',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
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
                            title: Text(item.name),
                            subtitle: Text(
                                'Rp ${item.price.toStringAsFixed(0)} x ${item.quantity}'),
                            trailing: Text(
                              'Rp ${(item.price * item.quantity).toStringAsFixed(0)}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
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
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D47A1)),
                    onPressed: _cart.isEmpty ? null : _checkout,
                    child: const Text('Selesaikan Transaksi',
                        style: TextStyle(color: Colors.white)),
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
