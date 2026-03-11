import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../models/address_model.dart';
import '../models/order_model.dart';
import '../services/mongodb_service.dart';
import '../services/razorpay_service.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  Address? _selectedAddress;
  String _selectedPaymentMethod = 'Razorpay';
  bool _isProcessing = false;
  late RazorpayService _razorpayService;

  final double _deliveryFee = 2.50;
  final double _taxAndFees = 1.50;

  @override
  void initState() {
    super.initState();
    _razorpayService = RazorpayService();
    // Default to the first address if available, or finding nearest to default
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.addresses.isNotEmpty) {
        setState(() {
           // Try to find default address first
          _selectedAddress = authProvider.addresses.firstWhere(
            (a) => a.isDefault,
            orElse: () => authProvider.addresses.first,
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _razorpayService.dispose();
    super.dispose();
  }

  void _placeOrder(CartProvider cart, AuthProvider auth) async {
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a delivery address')),
      );
      return;
    }

    if (cart.items.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your cart is empty')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    final total = cart.totalAmount + _deliveryFee + _taxAndFees;

    if (auth.userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to place an order')),
      );
      return;
    }

    if (_selectedPaymentMethod == 'Razorpay') {
      await _processRazorpayPayment(cart, auth, total);
      return;
    }

    final success = await MongoDatabase.createOrder(
      userId: auth.userId!,
      items: cart.items.values.map<OrderItem>((item) => OrderItem(
        dishId: item.id,
        name: item.name,
        quantity: item.quantity,
        price: item.price,
      )).toList(),
      totalAmount: total,
      deliveryAddress: '${_selectedAddress!.street}, ${_selectedAddress!.city}, ${_selectedAddress!.state} ${_selectedAddress!.zipCode}',
      paymentMethod: _selectedPaymentMethod,
    );

    if (!success) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to place order. Please try again.')),
        );
      }
      return;
    }

    // Clear cart and go back to home with success message
    cart.clearCart();
    
    // We should ideally reload auth data so the Orders list is fresh
    await auth.fetchUserData();

    if (mounted) {
      setState(() {
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order placed successfully!')),
      );
      context.go('/');
    }
  }

  Future<void> _processRazorpayPayment(CartProvider cart, AuthProvider auth, double total) async {
    if (auth.userId == null) return;

    _razorpayService.checkout(
      amount: total,
      name: auth.userName ?? 'Customer',
      email: auth.userEmail ?? 'customer@example.com',
      mobile: '9999999999',
      onSuccess: (paymentData) async {
        final success = await MongoDatabase.createOrder(
          userId: auth.userId!,
          items: cart.items.values.map<OrderItem>((item) => OrderItem(
            dishId: item.id,
            name: item.name,
            quantity: item.quantity,
            price: item.price,
          )).toList(),
          totalAmount: total,
          deliveryAddress: '${_selectedAddress!.street}, ${_selectedAddress!.city}, ${_selectedAddress!.state} ${_selectedAddress!.zipCode}',
          paymentMethod: 'Razorpay',
        );

        if (success) {
          cart.clearCart();
          await auth.fetchUserData();
          if (mounted) {
            setState(() {
              _isProcessing = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Order placed successfully!')),
            );
            context.go('/');
          }
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Payment failed: $error')),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    
    // Fallback logic for addresses update if auth fetched slower than init
    if (_selectedAddress == null && auth.addresses.isNotEmpty) {
         _selectedAddress = auth.addresses.firstWhere(
            (a) => a.isDefault,
            orElse: () => auth.addresses.first,
          );
    }

    final double total = cart.totalAmount + _deliveryFee + _taxAndFees;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.8),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Checkout',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
      ),
      body: cart.items.isEmpty 
          ? const Center(child: Text("Your cart is empty."))
          : SingleChildScrollView(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDeliveryAddressSection(auth),
                  const SizedBox(height: 24),
                  _buildOrderSummarySection(cart),
                  const SizedBox(height: 24),
                  _buildPaymentMethodsSection(),
                  const SizedBox(height: 24),
                  _buildPricingBreakdownSection(cart, total),
                ],
              ),
      ),
      bottomSheet: _buildCheckoutCTA(context, cart, auth, total),
    );
  }

  Widget _buildDeliveryAddressSection(AuthProvider auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Delivery Address',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {
                // Navigate to standard Addresses screen
                context.push('/addresses');
              },
              child: const Text(
                'Change',
                style: TextStyle(color: Color(0xFFE67E22), fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        if (auth.addresses.isEmpty)
           Container(
             padding: const EdgeInsets.all(16),
             decoration: BoxDecoration(
               color: Colors.white,
               borderRadius: BorderRadius.circular(16),
               boxShadow: [
                 BoxShadow(
                   color: Colors.black.withOpacity(0.05),
                   blurRadius: 10,
                   offset: const Offset(0, 4),
                 ),
               ],
               border: Border.all(color: Colors.red.shade100)
             ),
             child: const Center(
               child: Text('No addresses found. Click Change to add one!', style: TextStyle(color: Colors.red)),
             ),
           )
        else
          ...auth.addresses.map((address) {
            final isSelected = _selectedAddress?.id == address.id;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedAddress = address;
                });
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? const Color(0xFFE67E22) : Colors.grey.shade100,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Radio<String>(
                      value: address.id,
                      groupValue: _selectedAddress?.id,
                      activeColor: const Color(0xFFE67E22),
                      onChanged: (value) {
                         setState(() {
                            _selectedAddress = address;
                         });
                      },
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            address.label,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${address.street}, ${address.city}, ${address.zipCode}',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
        }).toList(),
      ],
    );
  }

  Widget _buildOrderSummarySection(CartProvider cart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Order Summary',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: cart.items.values.map((item) {
              return Column(
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          item.imageUrl,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 64,
                            height: 64,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.restaurant, color: Colors.grey),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            // In a real app we'd have sub-options or ingredients
                            const Text(
                              'Standard',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '\$${item.price.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Color(0xFFE67E22), 
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'x ${item.quantity}',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (item != cart.items.values.last)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Divider(color: Colors.grey.shade100),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Method',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildPaymentOption(
          title: 'Razorpay (Test)',
          subtitle: 'Pay securely via Razorpay',
          icon: Icons.payment,
          iconColor: Colors.white,
          iconBgColor: const Color(0xFF3399FE),
          value: 'Razorpay'
        ),
        const SizedBox(height: 12),
        _buildPaymentOption(
          title: '**** **** **** 4582',
          subtitle: 'Expires 09/25',
          icon: LucideIcons.creditCard,
          iconColor: const Color(0xFF1A1F71),
          iconBgColor: Colors.blue.shade50,
          value: 'Visa Card'
        ),
        const SizedBox(height: 12),
        _buildPaymentOption(
          title: 'Apple Pay',
          icon: Icons.apple,
          iconColor: Colors.white,
          iconBgColor: Colors.black,
          value: 'Apple Pay'
        ),
      ],
    );
  }

  Widget _buildPaymentOption({
    required String title,
    String? subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String value,
  }) {
    bool isSelected = _selectedPaymentMethod == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFFE67E22) : Colors.grey.shade100,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                  ]
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: _selectedPaymentMethod,
              activeColor: const Color(0xFFE67E22),
              onChanged: (v) {
                setState(() {
                  _selectedPaymentMethod = v!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingBreakdownSection(CartProvider cart, double total) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildPriceRow('Subtotal', cart.totalAmount),
          const SizedBox(height: 12),
          _buildPriceRow('Delivery Fee', _deliveryFee),
          const SizedBox(height: 12),
          _buildPriceRow('Tax & Fees', _taxAndFees),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: Colors.grey),
          ),
          // Custom dashed border
          SizedBox(
             height: 1,
             child: OverflowBox(
                maxWidth: double.infinity,
                child: Row(
                   children: List.generate(150~/5, (index) => Expanded(
                      child: Container(
                         color: index%2==0?Colors.transparent:Colors.grey.shade300,
                         height: 1,
                      ),
                   )),
                ),
             ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '\$${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE67E22),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double val) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
        Text(
          '\$${val.toStringAsFixed(2)}',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildCheckoutCTA(BuildContext context, CartProvider cart, AuthProvider auth, double total) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -10),
          )
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: _isProcessing || cart.items.isEmpty 
              ? null 
              : () => _placeOrder(cart, auth),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE67E22),
            minimumSize: const Size(double.infinity, 60),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: _isProcessing
              ? const CircularProgressIndicator(color: Colors.white)
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Place Order',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    SizedBox(width: 12),
                    Icon(LucideIcons.arrowRight, color: Colors.white),
                  ],
                ),
        ),
      ),
    );
  }
}
