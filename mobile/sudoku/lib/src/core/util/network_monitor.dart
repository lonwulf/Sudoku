import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
class NetworkMonitor{
  final Connectivity connectivity = Connectivity();
  late final StreamSubscription<List<ConnectivityResult>> subscription;

  final StreamController<bool> networkChangeController = StreamController<bool>.broadcast();
  Stream<bool> get networkChangeEvent => networkChangeController.stream;

  NetworkMonitor(){
    registerNetworkCallback();
  }

  void registerNetworkCallback(){
    checkInitialConnection();
    subscription = connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results){
      final isConnected = results.any((r) => r != ConnectivityResult.none);
      networkChangeController.add(isConnected);
    });
  }

  Future<void> checkInitialConnection() async {
    final result = await connectivity.checkConnectivity();
    final isConnected = result.any((r) => r != ConnectivityResult.none);
    networkChangeController.add(isConnected);
  }

  void unRegisterNetworkCallback(){
    subscription.cancel();
    networkChangeController.close();
  }


}