import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/mongodb_service.dart';
import '../models/order_model.dart';
import '../models/address_model.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  String? _userId;
  String? _userName;
  String? _userEmail;
  String? _profileImageUrl;
  List<Order> _orders = [];
  List<Address> _addresses = [];

  bool get isAuthenticated => _isAuthenticated;
  String? get userId => _userId;
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  String? get profileImageUrl => _profileImageUrl;
  List<Order> get orders => _orders;
  List<Address> get addresses => _addresses;
  Address? get defaultAddress => _addresses.isEmpty 
    ? null 
    : _addresses.firstWhere((a) => a.isDefault, orElse: () => _addresses.first);

  // --- Session persistence ---

  Future<void> _saveSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAuthenticated', true);
    if (_userId != null) await prefs.setString('userId', _userId!);
    if (_userName != null) await prefs.setString('userName', _userName!);
    if (_userEmail != null) await prefs.setString('userEmail', _userEmail!);
    if (_profileImageUrl != null) await prefs.setString('profileImageUrl', _profileImageUrl!);
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  /// Call this on app startup to restore the session
  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final isAuth = prefs.getBool('isAuthenticated') ?? false;
    if (!isAuth) return;

    _isAuthenticated = true;
    _userId = prefs.getString('userId');
    _userName = prefs.getString('userName');
    _userEmail = prefs.getString('userEmail');
    _profileImageUrl = prefs.getString('profileImageUrl');
    await fetchUserData();
    notifyListeners();
  }

  // --- Auth methods ---

  Future<String?> login({required String email, required String password}) async {
    final result = await MongoDatabase.loginUser(email: email, password: password);

    if (result != null && result['error'] == null) {
      _isAuthenticated = true;
      _userId = result['_id'].toString();
      _userEmail = result['email'];
      _userName = result['name'];
      _profileImageUrl = result['profileImageUrl'];
      await _saveSession();
      await fetchUserData();
      notifyListeners();
      return null; // Success
    }
    return result?['error'] ?? 'Login failed';
  }

  Future<String?> signup({required String name, required String email, required String password}) async {
    final result = await MongoDatabase.registerUser(
      name: name,
      email: email,
      password: password,
    );

    if (result != null && result['error'] == null) {
      _isAuthenticated = true;
      _userId = result['_id'].toString();
      _userName = result['name'];
      _userEmail = result['email'];
      _profileImageUrl = result['profileImageUrl'];
      await _saveSession();
      await fetchUserData();
      notifyListeners();
      return null; // Success
    }
    return result?['error'] ?? 'Signup failed';
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    _userId = null;
    _userName = null;
    _userEmail = null;
    _profileImageUrl = null;
    _orders = [];
    _addresses = [];
    await _clearSession();
    notifyListeners();
  }

  Future<void> fetchUserData() async {
    if (_userId == null) return;
    _orders = await MongoDatabase.getUserOrders(_userId!);
    _addresses = await MongoDatabase.getUserAddresses(_userId!);
    notifyListeners();
  }

  Future<bool> updateProfileImage(String base64Image) async {
    if (_userId == null) return false;
    final success = await MongoDatabase.updateUserProfile(
      userId: _userId!,
      profileImageUrl: base64Image,
    );
    if (success) {
      _profileImageUrl = base64Image;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profileImageUrl', base64Image);
      notifyListeners();
    }
    return success;
  }
}
