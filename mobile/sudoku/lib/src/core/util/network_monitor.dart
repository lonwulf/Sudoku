import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkMonitor {
  final Connectivity connectivity;
  late final StreamSubscription<List<ConnectivityResult>> subscription;

  final StreamController<bool> networkChangeController =
      StreamController<bool>.broadcast();
  Stream<bool> get networkChangeEvent => networkChangeController.stream;

  NetworkMonitor({Connectivity? connectivity})
    : connectivity = connectivity ?? Connectivity() {
    registerNetworkCallback();
  }

  void registerNetworkCallback() {
    checkInitialConnection();
    subscription = connectivity.onConnectivityChanged.listen((results) {
      emit(hasConnection(results));
    });
  }

  Future<bool> isConnected() async =>
      hasConnection(await connectivity.checkConnectivity());

  Future<void> checkInitialConnection() async {
    emit(await isConnected());
  }

  void unRegisterNetworkCallback() {
    subscription.cancel();
    networkChangeController.close();
  }

  void emit(bool isConnected) {
    if (!networkChangeController.isClosed) {
      networkChangeController.add(isConnected);
    }
  }

  static bool hasConnection(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);
}
