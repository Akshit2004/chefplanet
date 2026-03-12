import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/mongodb_service.dart';
import '../widgets/app_toast.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ShippingAddressesScreen extends StatelessWidget {
  const ShippingAddressesScreen({super.key});

  void _showAddAddressModal(BuildContext context, AuthProvider auth) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _AddAddressForm(auth: auth),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    final addresses = auth.addresses;

    return Scaffold(
      appBar: AppBar(title: const Text('Shipping Addresses')),
      body: addresses.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.mapPin,
                    size: 64,
                    color: theme.disabledColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No addresses saved',
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: addresses.length,
              itemBuilder: (context, index) {
                final address = addresses[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        address.label.toLowerCase() == 'home'
                            ? LucideIcons.home
                            : LucideIcons.briefcase,
                        color: theme.primaryColor,
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(
                          address.label,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (address.isDefault)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Default',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Text(
                      '${address.street}, ${address.city}, ${address.state} ${address.zipCode}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!address.isDefault)
                          TextButton(
                            onPressed: () async {
                              final userId = auth.userId;
                              if (userId == null) return;

                              final success =
                                  await MongoDatabase.setDefaultAddress(
                                    userId,
                                    address.id,
                                  );
                              if (success) {
                                await auth.fetchUserData();
                              }
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Set Default',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        IconButton(
                          icon: const Icon(LucideIcons.edit3, size: 20),
                          onPressed: () {
                            // TODO: Implement Edit
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddAddressModal(context, auth),
        child: const Icon(LucideIcons.plus),
      ),
    );
  }
}

class _AddAddressForm extends StatefulWidget {
  final AuthProvider auth;

  const _AddAddressForm({required this.auth});

  @override
  State<_AddAddressForm> createState() => _AddAddressFormState();
}

class _AddAddressFormState extends State<_AddAddressForm> {
  final _formKey = GlobalKey<FormState>();
  String _label = 'Home';
  String _street = '';
  String _city = '';
  String _state = '';
  String _zipCode = '';
  bool _isDefault = false;
  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final userId = widget.auth.userId;
    if (userId == null) return;

    setState(() => _isLoading = true);

    final success = await MongoDatabase.addAddress(
      userId: userId,
      label: _label,
      street: _street,
      city: _city,
      state: _state,
      zipCode: _zipCode,
      isDefault: _isDefault,
    );

    if (success) {
      await widget.auth.fetchUserData(); // reload to get the new address
      if (mounted) {
        Navigator.pop(context);
        AppToast.show(context, 'Address added successfully!');
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
        AppToast.show(context, 'Failed to add address', success: false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Padding to account for the keyboard
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Add New Address',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _label,
                decoration: const InputDecoration(labelText: 'Label'),
                items: ['Home', 'Office', 'Other'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _label = val!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Street Address'),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Required' : null,
                onSaved: (val) => _street = val!,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(labelText: 'City'),
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Required' : null,
                      onSaved: (val) => _city = val!,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(labelText: 'State'),
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Required' : null,
                      onSaved: (val) => _state = val!,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Zip Code'),
                keyboardType: TextInputType.number,
                validator: (val) =>
                    val == null || val.isEmpty ? 'Required' : null,
                onSaved: (val) => _zipCode = val!,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Set as Default Address'),
                value: _isDefault,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) {
                  setState(() {
                    _isDefault = val;
                  });
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save Address'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
