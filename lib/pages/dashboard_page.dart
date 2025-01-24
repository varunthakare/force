import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'dart:math';
import 'dart:async';
import 'cart_page.dart';
import '../models/product.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with SingleTickerProviderStateMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final TextEditingController _searchController = TextEditingController();
  bool _isListening = false;
  late AnimationController _animationController;
  final List<double> _barHeights = List.filled(30, 2.0); // For visualization bars
  bool _isAnimating = false;
  Timer? _silenceTimer;

  // Initialize products with quantity 0
  final List<Product> _products = [
    Product(title: 'Samyang Ramen', price: 150, subtitle: 'Hot Chicken', quantity: 0),
    Product(title: 'Maggi Noodles', price: 14, subtitle: '35g', quantity: 0),
    Product(title: 'PastaZara', price: 197, subtitle: '39% OFF', quantity: 0),
    Product(title: 'Coke Vanilla', price: 40, subtitle: 'Cold Drink', quantity: 0),
    Product(title: 'Red Bull', price: 99, subtitle: '250ml', quantity: 0),
    Product(title: 'Dettol Skin care', price: 137, subtitle: 'Pack of 4', quantity: 0),
  ];

  List<Product> _getFilteredProducts() {
    if (_searchController.text.isEmpty) return _products;
    
    final searchQuery = _searchController.text.toLowerCase();
    final matchingProducts = _products.where(
      (product) => product.title.toLowerCase().contains(searchQuery)
    ).toList();
    
    final otherProducts = _products.where(
      (product) => !product.title.toLowerCase().contains(searchQuery)
    ).toList();
    
    return [...matchingProducts, ...otherProducts];
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _initializeSpeech();
  }

  @override
  void dispose() {
    _silenceTimer?.cancel();
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _startBarAnimation() {
    if (!_isAnimating) {
      _isAnimating = true;
      _updateBars();
    }
  }

  void _stopBarAnimation() {
    _isAnimating = false;
  }

  void _updateBars() {
    if (!_isAnimating) return;
    setState(() {
      for (int i = 0; i < _barHeights.length; i++) {
        _barHeights[i] = (Random().nextDouble() * 20) + 2;
      }
    });
    Future.delayed(Duration(milliseconds: 100), _updateBars);
  }

  void _initializeSpeech() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      print('Microphone permission not granted');
      return;
    }

    bool available = await _speech.initialize(
      onError: (error) => print('Error: $error'),
      onStatus: (status) => print('Status: $status'),
    );
    print('Speech recognition available: $available');
  }

  void _listen() async {
    try {
      if (!_isListening) {
        print('Starting to listen...');
        bool available = await _speech.initialize();
        if (available) {
          setState(() => _isListening = true);
          _animationController.forward();
          _startBarAnimation();
          
          // Start silence timer
          _silenceTimer = Timer(Duration(seconds: 5), () {
            _stopListening();
          });

          await _speech.listen(
            onResult: (result) {
              print('Got result: ${result.recognizedWords}');
              // Reset silence timer on speech detection
              _silenceTimer?.cancel();
              _silenceTimer = Timer(Duration(seconds: 3), () {
                _stopListening();
              });

              setState(() {
                _searchController.text = result.recognizedWords;
                if (result.finalResult) {
                  _stopListening();
                }
              });
            },
          );
        } else {
          print('Speech recognition not available');
        }
      } else {
        _stopListening();
      }
    } catch (e) {
      print('Error occurred: $e');
      _stopListening();
    }
  }

  void _stopListening() {
    _silenceTimer?.cancel();
    setState(() => _isListening = false);
    _animationController.reverse();
    _stopBarAnimation();
    _speech.stop();
  }

  int getTotalQuantity() {
    return _products.fold(0, (sum, product) => sum + product.quantity);
  }

  double getTotalPrice() {
    return _products.fold(0.0, (sum, product) => sum + (product.price * product.quantity));
  }

  void _navigateToCart() async {
    // Wait for the result from CartPage
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CartPage(
          cartItems: _products.where((p) => p.quantity > 0).toList(),
        ),
      ),
    );
    
    // After returning from CartPage, rebuild the state
    setState(() {
      // This will trigger a rebuild and update the bottom sheet
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasItemsInCart = getTotalQuantity() > 0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.white),
                SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Home',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Atreynadan Apartment',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(25),
                    bottomRight: Radius.circular(25),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 25, top: 8),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          alignment: Alignment.center,
                          child: Text(
                            'SHOP SMARTER, NOT HARDER',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(height: 12),
                        TextField(
                          controller: _searchController,
                          onChanged: (value) => setState(() {}),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            hintText: 'Search',
                            hintStyle: TextStyle(color: Colors.grey),
                            prefixIcon: Icon(Icons.search, color: Colors.grey),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isListening ? Icons.mic_off : Icons.mic,
                                color: Colors.grey,
                              ),
                              onPressed: _listen,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Categories Row with equal spacing and alignment
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 10.0),
                              child: _buildCategoryIcon('All', Icons.all_inclusive),
                            ),
                            _buildCategoryIcon('Kitchen', Icons.kitchen),
                            _buildCategoryIcon('Beverages', Icons.local_drink),
                            _buildCategoryIcon('Snacks', Icons.bakery_dining),
                            _buildCategoryIcon('Dairy', Icons.egg),
                            Padding(
                              padding: const EdgeInsets.only(right: 10.0),
                              child: _buildCategoryIcon('Cleaning', Icons.clean_hands),
                            ),
                          ],
                        ),
                      ),
                      // Featured Products
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          'Featured',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 120,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _buildFeaturedItem('Coke Vanilla', Colors.purple),
                            _buildFeaturedItem('Olive Oil', Colors.red),
                            _buildFeaturedItem('Abbie\'s', Colors.red.shade800),
                            _buildFeaturedItem('Olive Oil', Colors.red),
                            _buildFeaturedItem('Abbie\'s', Colors.red.shade800),
                          ],
                        ),
                      ),
                      // Gourmet Meals Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          'Everyday Grocery Essentials',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        childAspectRatio: 0.8,
                        padding: const EdgeInsets.all(8.0),
                        children: _getFilteredProducts().map((product) => 
                          _buildProductCard(
                            product.title,
                            product.price,
                            product.subtitle,
                          )
                        ).toList(),
                      ),
                      SizedBox(height: hasItemsInCart ? 80 : 0),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (hasItemsInCart)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _animationController,
                  curve: Curves.easeOut,
                )),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 2,
                        blurRadius: 8,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        margin: EdgeInsets.only(top: 8),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${getTotalQuantity()} ITEMS',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '₹${getTotalPrice().toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            ElevatedButton(
                              onPressed: _navigateToCart,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(255, 243, 143, 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              ),
                              child: Text(
                                'View Cart',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        backgroundColor: const Color.fromARGB(255, 243, 143, 12),
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black54,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'Order Again',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: 'Categories',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.print),
            label: 'Print',
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryIcon(String label, IconData icon) {
    return Column(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.grey.shade200,
          child: Icon(icon, size: 28, color: Colors.black),
        ),
        SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildFeaturedItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        width: 100,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(String title, int price, String subtitle) {
    final product = _products.firstWhere((p) => p.title == title);

    return Card(
      elevation: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 105,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10), // Adjust the radius as needed
                topRight: Radius.circular(10),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              title,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(subtitle, style: TextStyle(color: Colors.grey)),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '₹$price',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                ),
                product.quantity == 0
                  ? ElevatedButton(
                      onPressed: () {
                        setState(() {
                          product.quantity = 1;
                          if (getTotalQuantity() == 1) {
                            _animationController.forward();
                          }
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 243, 143, 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: Text(
                        'ADD',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : Container(
                      height: 36,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color.fromARGB(255, 243, 143, 12)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.remove, 
                              color: const Color.fromARGB(255, 243, 143, 12),
                              size: 18,
                            ),
                            onPressed: () {
                              setState(() {
                                if (product.quantity > 0) {
                                  product.quantity--;
                                  // Hide cart when last item is removed
                                  if (getTotalQuantity() == 0) {
                                    _animationController.reverse();
                                  }
                                }
                              });
                            },
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              '${product.quantity}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.add, 
                              color: const Color.fromARGB(255, 243, 143, 12),
                              size: 18,
                            ),
                            onPressed: () {
                              setState(() {
                                product.quantity++;
                                // Ensure cart is visible when adding items
                                if (getTotalQuantity() == 1) {
                                  _animationController.forward();
                                }
                              });
                            },
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                          ),
                        ],
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
