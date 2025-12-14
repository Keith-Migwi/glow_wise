import 'dart:io' show Platform;
import 'dart:typed_data' show Uint8List;
import 'package:android_intent_plus/android_intent.dart' show AndroidIntent;
import 'package:flutter/cupertino.dart' show CupertinoPageRoute;
import 'package:flutter/material.dart';
import 'package:led/control/index.dart';
import 'package:led/scan_&_connect/components/bluetooth_dialog.dart'
    show BluetoothDialog;
import 'package:led/scan_&_connect/components/connection_toast.dart'
    show showConnectionToast;
import 'package:led/scan_&_connect/components/list_item.dart'
    show DeviceListItem;
import 'package:led/scan_&_connect/components/scan_button.dart';
import 'package:led/scan_&_connect/components/scanning_indicator.dart'
    show ScanningIndicator;
import 'package:led/main.dart';
import 'package:lucide_icons/lucide_icons.dart' show LucideIcons;
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';

extension DiscoveredDeviceJson on DiscoveredDevice {
  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "serviceData": serviceData.map(
      (k, v) => MapEntry(k.toString(), base64Encode(v)),
    ),
    "manufacturerData": base64Encode(manufacturerData),
    "rssi": rssi,
    "serviceUuids": serviceUuids.map((u) => u.toString()).toList(),
  };
}

DiscoveredDevice discoveredDeviceFromJson(Map<String, dynamic> json) {
  return DiscoveredDevice(
    id: json["id"],
    name: json["name"],
    serviceData: (json["serviceData"] as Map).map(
      (k, v) => MapEntry(Uuid.parse(k), base64Decode(v)),
    ),
    manufacturerData: base64Decode(json["manufacturerData"]),
    rssi: json["rssi"],
    serviceUuids: (json["serviceUuids"] as List)
        .map((e) => Uuid.parse(e))
        .toList(),
  );
}

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> with WidgetsBindingObserver {
  final _flutterReactiveBle = FlutterReactiveBle();
  StreamSubscription<DiscoveredDevice>? _scanStream;
  StreamSubscription<ConnectionStateUpdate>? _connectionStream;

  final List<DiscoveredDevice> _devices = [];
  bool _isScanning = false;
  String? _connectedDeviceId;
  bool _isBluetoothDialogOpen = false;
  bool _hasNavigated = false;

  late final bool _isSandboxMode;

  Future<bool> _shouldUseSandbox() async {
    // Android emulator / Bluestacks detection
    if (Platform.isAndroid) {
      final state = await FlutterBluePlus.adapterState.first;
      if (state == BluetoothAdapterState.unavailable ||
          state == BluetoothAdapterState.unknown)
        return true;
    }

    return false;
  }

  // Request permissions (Android)
  Future<bool> _requestPermissions() async {
    final scan = await Permission.bluetoothScan.request();
    final connect = await Permission.bluetoothConnect.request();
    final loc = await Permission.location.request();

    return scan.isGranted && connect.isGranted && loc.isGranted;
  }

  // Start scanning
  Future<void> _startScan() async {
    if (_isSandboxMode) {
      _startSandboxScan();
      return;
    }

    if (!await _requestPermissions() && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("BLE permissions denied")));
      return;
    }

    final bluetoothState = await FlutterBluePlus.adapterState.firstWhere(
      (state) => state != BluetoothAdapterState.unknown,
    );

    if (bluetoothState != BluetoothAdapterState.on) {
      if (mounted) {
        setState(() {
          _isBluetoothDialogOpen = true;
        });
      }
      return;
    }

    _stopScan();

    setState(() {
      _devices.removeWhere((device) => device.id != _connectedDeviceId);
      _isScanning = true;
    });

    _listenToConnectedDevices();

    _scanStream = _flutterReactiveBle
        .scanForDevices(withServices: [], scanMode: ScanMode.lowLatency)
        .listen(
          (device) {
            final md = device.manufacturerData;

            if (md.length >= 2 && md[0] == 66 && md[1] == 6) {
              if (_devices.every((d) => d.id != device.id)) {
                setState(() => _devices.add(device));
              }
            }
          },
          onError: (e) {
            setState(() {
              _isScanning = false;
            });
            _stopScan();
            throw ("Error scanning devices: $e");
          },
        );

    //auto-stop after 8 seconds
    Future.delayed(const Duration(seconds: 8), () {
      if (_isScanning) _stopScan();
    });
  }

  void _stopScan() {
    _scanStream?.cancel();
    setState(() => _isScanning = false);
  }

  // Connect to selected device
  Future<void> _connect(DiscoveredDevice device) async {
    if (_isSandboxMode) {
      _connectSandbox(device);
      return;
    }

    _stopScan(); // Stop scanning when connecting

    if (mounted && device.id == _connectedDeviceId) {
      Navigator.of(context).push(
        CupertinoPageRoute(
          builder: (context) => ControlIndex(
            device: _devices.firstWhere(
              (device) => device.id == _connectedDeviceId,
            ),
          ),
        ),
      );
      return;
    }

    showConnectionToast(context, "Connecting...");

    setState(() {
      _connectedDeviceId = device.id;
    });

    _connectionStream = _flutterReactiveBle
        .connectToDevice(
          id: device.id,
          connectionTimeout: const Duration(seconds: 10),
        )
        .listen(
          (update) async {
            if (update.connectionState == DeviceConnectionState.connected) {
              setState(() {
                showConnectionToast(context, "Connected");
              });
              _discoverServices(device);
            }
          },
          onError: (e) {
            setState(() {
              showConnectionToast(context, "Connection Failed");
              _connectedDeviceId = null;
            });
            throw ("Error connecting to device");
          },
        );
  }

  Future<void> _saveDevice(DiscoveredDevice device) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(device.toJson());
    await prefs.setString("device_${device.id}", jsonString);
  }

  Future<DiscoveredDevice?> _loadDevice(String deviceId) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString("device_$deviceId");
    if (jsonString == null) return null;
    final data = jsonDecode(jsonString);
    return discoveredDeviceFromJson(data);
  }

  // Discover services & find 0xFFE1 characteristic
  Future<void> _discoverServices(DiscoveredDevice device) async {
    final services = await _flutterReactiveBle.getDiscoveredServices(device.id);

    bool foundFFE1 = false;

    for (var service in services) {
      for (var char in service.characteristics) {
        final uuid = char.id.toString().toUpperCase();
        if (uuid.contains("FFE1")) {
          foundFFE1 = true;
        }
      }
    }

    if (!foundFFE1) {
      if (mounted) {
        showConnectionToast(context, "Device not supported yet, disconnected");
      }

      await _connectionStream?.cancel();
      _connectionStream = null;

      setState(() {
        _connectedDeviceId = null;
      });
    } else {
      _saveDevice(device);

      if (mounted && !_hasNavigated) {
        _hasNavigated = true;

        Navigator.of(context)
            .push(
              CupertinoPageRoute(
                builder: (context) => ControlIndex(
                  device: _devices.firstWhere(
                    (device) => device.id == _connectedDeviceId,
                  ),
                ),
              ),
            )
            .then((_) {
              // Page popped
              if (mounted) {
                setState(() {
                  _hasNavigated = false;
                });
              }
            });
      }
    }
  }

  Future<void> _turnOnBluetooth() async {
    if (Platform.isAndroid) {
      final intent = AndroidIntent(
        action: 'android.settings.BLUETOOTH_SETTINGS',
      );

      setState(() {
        _isBluetoothDialogOpen = false;
      });

      try {
        await intent.launch();
      } catch (e) {
        // fallback - open general settings
        final fallback = AndroidIntent(action: 'android.settings.SETTINGS');
        await fallback.launch();
      }
    }
  }

  void _bluetoothStateStream() {
    FlutterBluePlus.adapterState.listen((state) {
      if (state == BluetoothAdapterState.on) {
        _startScan();
        setState(() {
          _isBluetoothDialogOpen = false;
        });
      } else {
        _stopScan();
        setState(() {
          _isBluetoothDialogOpen = true;
          _devices.clear();
        });
      }
    });
  }

  void _listenToConnectedDevices() async {
    _connectionStream = _flutterReactiveBle.connectedDeviceStream.listen((
      update,
    ) async {
      if (update.connectionState == DeviceConnectionState.connected) {
        // Avoid duplicates
        if (_devices.any((d) => d.id == update.deviceId)) {
          final d = _devices.firstWhere((d) => d.id == update.deviceId);
          await _discoverServices(d);
          return;
        }

        // Try load from SharedPreferences
        DiscoveredDevice? savedDevice = await _loadDevice(update.deviceId);

        if (savedDevice != null) {
          _devices.add(savedDevice);
        } else {
          // fallback minimal version
          savedDevice = DiscoveredDevice(
            id: update.deviceId,
            name: "",
            serviceData: {},
            rssi: 0,
            serviceUuids: [],
            manufacturerData: Uint8List(0),
          );
          _devices.add(savedDevice);
        }

        _connectedDeviceId = update.deviceId;
        setState(() {});
        await _discoverServices(savedDevice);
      }
    });
  }

  Future<void> _initMode() async {
    _isSandboxMode = await _shouldUseSandbox();

    if (!_isSandboxMode) {
      _bluetoothStateStream();
    }
  }

  DiscoveredDevice _fakeDevice(int index) {
    return DiscoveredDevice(
      id: "FAKE_LED_$index",
      name: "GlowWise Lamp ${index + 1}",
      rssi: -40 - index * 5,
      serviceUuids: [Uuid.parse("0000FFE0-0000-1000-8000-00805F9B34FB")],
      serviceData: {},
      manufacturerData: Uint8List.fromList([66, 6]),
    );
  }

  void _startSandboxScan() {
    _stopScan();

    setState(() {
      _devices.clear();
      _isScanning = true;
    });

    // Simulate scan delay
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;

      setState(() {
        _devices.addAll(List.generate(3, _fakeDevice));
        _isScanning = false;
      });
    });
  }

  void _connectSandbox(DiscoveredDevice device) {
    showConnectionToast(context, "Connecting...");

    setState(() {
      _connectedDeviceId = device.id;
    });

    // Simulate connection delay
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted || _hasNavigated) return;

      showConnectionToast(context, "Connected");

      _hasNavigated = true;

      Navigator.of(context)
          .push(
            CupertinoPageRoute(builder: (_) => ControlIndex(device: device)),
          )
          .then((_) {
            if (mounted) {
              setState(() {
                _hasNavigated = false;
                _connectedDeviceId = null;
              });
            }
          });
    });
  }

  @override
  void initState() {
    _initMode();
    super.initState();
  }

  @override
  void dispose() {
    _scanStream?.cancel();
    _connectionStream?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {}
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: Colors.black,

            appBar: AppBar(
              backgroundColor: Colors.black,
              surfaceTintColor: Colors.black,
              title: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF22D3EE), Color(0xFF8B5CF6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x8022D3EE),
                          blurRadius: 8,
                          spreadRadius: 0,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        LucideIcons.zap,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),
                  Text(
                    'GlowWise',
                    style: TextStyle(
                      fontSize: headerFont,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Connect to LED Light',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: bodyFont, color: Colors.white),
                    ),
                    const SizedBox(height: 5),

                    Text(
                      'Scan for nearby LED lamps and connect',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: secondaryFont,
                        color: Colors.grey.shade500,
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      child: ScanningIndicator(isScanning: _isScanning),
                    ),

                    Text(
                      _isScanning ? 'Scanning for devices...' : 'Ready to scan',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: secondaryFont,
                        color: _isScanning
                            ? const Color(0xFF06B6D4)
                            : Colors.grey.shade600,
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      child: ScanButton(
                        isScanning: _isScanning,
                        onClick: _isScanning ? _stopScan : _startScan,
                      ),
                    ),

                    //Available devices
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Available Devices',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: _devices.isEmpty
                                ? Center(
                                    child: Text(
                                      'No devices found yet',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  )
                                : ListView.separated(
                                    itemCount: _devices.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 12),
                                    itemBuilder: (context, index) {
                                      final device = _devices[index];
                                      return DeviceListItem(
                                        device: device,
                                        isSelected:
                                            _connectedDeviceId == device.id,
                                        onClick: () {
                                          _connect(device);
                                        },
                                      );
                                    },
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

          BluetoothDialog(
            isOpen: _isBluetoothDialogOpen,
            onClose: () => setState(() => _isBluetoothDialogOpen = false),
            onEnable: _turnOnBluetooth,
          ),
        ],
      ),
    );
  }
}
