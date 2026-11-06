import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// NetworkConnectivityService continuously monitors network state and real internet reachability.
/// Notifies listeners whenever online/offline state transitions occur.
class NetworkConnectivityService extends ChangeNotifier {
  static final NetworkConnectivityService _instance = NetworkConnectivityService._internal();
  factory NetworkConnectivityService() => _instance;
  NetworkConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  bool _isChecking = false;
  bool get isChecking => _isChecking;

  bool _isInitialized = false;

  void initialize() {
    if (_isInitialized) return;
    _isInitialized = true;
    _checkInitialConnection();
    _subscription = _connectivity.onConnectivityChanged.listen(_handleConnectivityChange);
  }

  Future<void> _checkInitialConnection() async {
    try {
      final results = await _connectivity.checkConnectivity();
      await _evaluateResults(results);
    } catch (e) {
      debugPrint('Initial connectivity check note: $e');
      _isOnline = true;
      notifyListeners();
    }
  }

  Future<void> _handleConnectivityChange(List<ConnectivityResult> results) async {
    await _evaluateResults(results);
  }

  Future<void> _evaluateResults(List<ConnectivityResult> results) async {
    final hasActiveInterface = results.any((r) =>
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.ethernet ||
        r == ConnectivityResult.vpn ||
        r == ConnectivityResult.other);

    if (!hasActiveInterface) {
      _updateStatus(false);
      return;
    }

    // On real non-web platforms, verify genuine internet reachability
    if (!kIsWeb) {
      final hasInternet = await _pingInternet();
      _updateStatus(hasInternet);
    } else {
      _updateStatus(true);
    }
  }

  Future<bool> _pingInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      // If DNS lookup fails or times out, device is not connected to internet
      return false;
    }
  }

  void _updateStatus(bool status) {
    if (_isOnline != status) {
      _isOnline = status;
      notifyListeners();
    }
  }

  /// Manually force a recheck (e.g. when user taps the retry button or banner)
  Future<void> checkConnection() async {
    if (_isChecking) return;
    _isChecking = true;
    notifyListeners();

    try {
      final results = await _connectivity.checkConnectivity();
      await _evaluateResults(results);
    } catch (e) {
      debugPrint('Manual connectivity check note: $e');
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }

  /// Test-only utility to simulate online/offline state changes
  @visibleForTesting
  void setOnlineForTesting(bool value) {
    _isOnline = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

