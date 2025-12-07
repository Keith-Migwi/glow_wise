// scan_connect_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';

class ScanConnectPage extends StatefulWidget {
  const ScanConnectPage({super.key});

  @override
  State<ScanConnectPage> createState() => _ScanConnectPageState();
}

class _ScanConnectPageState extends State<ScanConnectPage> {
  final flutterReactiveBle = FlutterReactiveBle();
  StreamSubscription<DiscoveredDevice>? _scanStream;
  StreamSubscription<ConnectionStateUpdate>? _connectionStream;

  final List<DiscoveredDevice> _devices = [];
  bool _isScanning = false;
  String? _connectedDeviceId;
  String connectionStateText = "Not connected";

  // Request permissions (Android)
  Future<bool> _requestPermissions() async {
    final scan = await Permission.bluetoothScan.request();
    final connect = await Permission.bluetoothConnect.request();
    final loc = await Permission.location.request();

    return scan.isGranted && connect.isGranted && loc.isGranted;
  }

  // Start scanning
  Future<void> _startScan() async {
    if (!await _requestPermissions()) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("BLE permissions denied")));
      return;
    }

    setState(() {
      _devices.clear();
      _isScanning = true;
    });

    _scanStream = flutterReactiveBle
        .scanForDevices(withServices: [], scanMode: ScanMode.lowLatency)
        .listen(
          (device) {
            // Filter LED Lamps by name pattern
            if (device.name.isNotEmpty &&
                device.name.toLowerCase().contains("led")) {
              // Avoid duplicates
              if (_devices.every((d) => d.id != device.id)) {
                setState(() => _devices.add(device));
              }
            }
          },
          onError: (e) {
            print("Scan error: $e");
            setState(() => _isScanning = false);
          },
        );
  }

  void _stopScan() {
    _scanStream?.cancel();
    setState(() => _isScanning = false);
  }

  // Connect to selected device
  Future<void> _connect(DiscoveredDevice device) async {
    _stopScan(); // Stop scanning when connecting

    setState(() {
      connectionStateText = "Connecting...";
      _connectedDeviceId = device.id;
    });

    _connectionStream = flutterReactiveBle
        .connectToDevice(
          id: device.id,
          connectionTimeout: const Duration(seconds: 10),
        )
        .listen(
          (update) async {
            setState(() {
              connectionStateText = update.connectionState.toString();
            });

            if (update.connectionState == DeviceConnectionState.connected) {
              _discoverServices(device.id);
            }
          },
          onError: (e) {
            print("Connection error: $e");
            setState(() {
              connectionStateText = "Error connecting";
              _connectedDeviceId = null;
            });
          },
        );
  }

  // Discover services & find 0xFFE1 characteristic
  Future<void> _discoverServices(String deviceId) async {
    final services = await flutterReactiveBle.discoverServices(deviceId);

    bool foundFFE1 = false;

    for (var service in services) {
      for (var char in service.characteristics) {
        final uuid = char.characteristicId.toString().toUpperCase();
        if (uuid.contains("FFE1")) {
          foundFFE1 = true;
        }
      }
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          foundFFE1
              ? "SUCCESS: Found LED characteristic 0xFFE1"
              : "Connected, but FFE1 not found!",
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scanStream?.cancel();
    _connectionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan & Connect to LED Lamp")),
      body: Column(
        children: [
          // Scan buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _isScanning ? null : _startScan,
                child: const Text("Start Scan"),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _isScanning ? _stopScan : null,
                child: const Text("Stop Scan"),
              ),
            ],
          ),

          // Connection status
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              "Connection: $connectionStateText",
              style: const TextStyle(fontSize: 16),
            ),
          ),

          // Device list
          Expanded(
            child: ListView.builder(
              itemCount: _devices.length,
              itemBuilder: (_, i) {
                final d = _devices[i];
                return ListTile(
                  title: Text(d.name),
                  subtitle: Text(d.id),
                  trailing: const Icon(Icons.bluetooth),
                  onTap: () => _connect(d),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
