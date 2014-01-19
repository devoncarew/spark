// Copyright (c) 2014, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

/**
 * TODO:
 */
library spark.mobile;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:chrome/chrome_app.dart' as chrome;

// Nexus 7: { "vendorId": 6353, "productId": 20034 }
// Nexus 5: { "vendorId": 6353, "productId": 20194 }

/**
 * TODO:
 */
class MobileManager {
  final int _ADB_INTERFACE_CLASS = 255;
  final int _ADB_INTERFACE_SUBCLASS = 66;
  final int _ADB_INTERFACE_ID = 1;

  final List<_DeviceInfo> _deviceInfos = [];

  final List<MobileConnection> connections = [];

  StreamController<MobileConnection> _controller = new StreamController.broadcast();

  Timer _scanTimer;

  MobileManager() {
    // Get the list of permitted devices from the manifest.
    Map manifest = chrome.runtime.getManifest();
    List permissions = manifest['permissions'];

    for (var permission in permissions) {
      if (permission is Map && permission['usbDevices'] != null) {
        List<Map> devices = permission['usbDevices'];
        for (Map deviceInfo in devices) {
          _deviceInfos.add(new _DeviceInfo.fromMap(deviceInfo));
        }
      }
    }
  }

  /**
   * Start automatically scanning for devices to connect to. This will continue
   * scanning until [dispose] is called.
   */
  void scanForDevicesContinuous() {
    _keepScanning(new Duration(seconds: 3));
  }

  void _keepScanning(Duration duration) {
    _scanTimer = new Timer(duration, () {
      scanForDevicesOnce().then((connection) {
        if (connection == null) {
          _keepScanning(new Duration(seconds: 6));
        }
      });
    });
  }

  /**
   * Scan for and attempt to connect to new mobile devices. This will return the
   * connection if a mobile device is found and `null` otherwise.
   *
   * This should only be called if there are no current connections.
   */
  Future<MobileConnection> scanForDevicesOnce() {
    if (_deviceInfos.isEmpty) {
      return new Future.value();
    }

    return _scanForDevices(_deviceInfos.toList());
  }

  Stream<MobileConnection> get onConnectionChange => _controller.stream;

  void dispose() {
    connections.forEach((connection) => connection.dispose());

    if (_scanTimer != null) {
      _scanTimer.cancel();
      _scanTimer = null;
    }
  }

  Future _scanForDevices(List devices) {
    return _attemptConnect(devices.first).then((result) {
      if (result != null) {
        return result;
      } else if (devices.length > 1) {
        return _scanForDevices(devices.take(1));
      } else {
        return null;
      }
    }).catchError((e) {
      if (devices.length > 1) {
        return _scanForDevices(devices.take(1));
      } else {
        return null;
      }
    });
  }

  Future<MobileConnection> _attemptConnect(_DeviceInfo device) {
    var options = new chrome.EnumerateDevicesAndRequestAccessOptions(
        vendorId: device.vendorId, productId: device.productId);

    return chrome.usb.findDevices(options).then((List<chrome.ConnectionHandle> connections) {
      if (connections.isNotEmpty) {
        // Close the other n-1 devices.
        if (connections.length > 1) {
          connections.skip(1).forEach((conn) => chrome.usb.closeDevice(conn));
        }

        // Use the first connection.
        chrome.ConnectionHandle connection = connections.first;

        return chrome.usb.listInterfaces(connection).then((List<chrome.InterfaceDescriptor> interfaces) {
          bool foundDevice = false;

          for (chrome.InterfaceDescriptor interface in interfaces) {
            if (interface.interfaceClass == _ADB_INTERFACE_CLASS &&
                interface.interfaceSubclass == _ADB_INTERFACE_SUBCLASS &&
                interface.interfaceProtocol == _ADB_INTERFACE_ID) {
              foundDevice = true;
              return _claimInterface(connection, interface);
            }
          }

          if (!foundDevice) {
            chrome.usb.closeDevice(connection);
          }

          return null;
        });
      }
    });
  }

  Future<MobileConnection> _claimInterface(chrome.ConnectionHandle connection, chrome.InterfaceDescriptor interface) {
    return chrome.usb.claimInterface(connection, interface.interfaceNumber).then((_) {
      MobileConnection conn = new MobileConnection._(this, connection, interface);
      connections.add(conn);
      _controller.add(conn);
      return conn;
    });
  }

  void _disposeConnection(MobileConnection connection) {
    if (connections.contains(connection)) {
      connections.remove(connection);
      _controller.add(null);

      if (connections.isEmpty && _scanTimer != null) {
        _keepScanning(new Duration(seconds: 6));
      }
    }
  }
}

/**
 * TODO:
 */
class MobileConnection {
  final MobileManager _manager;
  final chrome.ConnectionHandle usbConnection;
  final chrome.InterfaceDescriptor usbInterface;

  chrome.EndpointDescriptor _inEndpoint;
  chrome.EndpointDescriptor _outEndpoint;

  MobileConnection._(this._manager, this.usbConnection, this.usbInterface) {
    for (chrome.EndpointDescriptor endpoint in usbInterface.endpoints) {
      if (endpoint.type == chrome.TransferType.BULK) {
        if (endpoint.direction == chrome.Direction.IN) {
          _inEndpoint = endpoint;
        }
        if (endpoint.direction == chrome.Direction.OUT) {
          _outEndpoint = endpoint;
        }
      }
    }

    Timer.run(_connect);
  }

  void _connect() {
    // TODO: send a connect
    _AdbMessage message = new _AdbMessage(
        command: _AdbMessage.A_CNXN,
        arg0: _AdbMessage.A_VERSION,
        arg1: _AdbMessage.MAX_PAYLOAD,
        dataString: "host::\0");

    _bulkSend(message);

    // TODO: listen for data coming back
    _bulkReceive().then((chrome.TransferResultInfo result) {
      print('_bulkReceive(): result code: ${result.resultCode}');
      print(result.data.getBytes());
      print('[' + UTF8.decode(result.data.getBytes(), allowMalformed: true) + ']');
    }).catchError((e) {
      print('error from _bulkReceive(): ${e}');
    });

    // TODO: dispose of myself if a connection fails

  }

  _bulkSend(_AdbMessage message) {
    var info = new chrome.GenericTransferInfo(
        direction: chrome.Direction.OUT,
        endpoint: _outEndpoint.address,
        data: new chrome.ArrayBuffer.fromBytes(message.getHeaderBytes()));

    chrome.usb.bulkTransfer(usbConnection, info).then((chrome.TransferResultInfo result) {
      print('_bulkSend() result code: ${result.resultCode}');
    }).catchError((e) {
      print('error from _bulkSend(): ${e}');
    });

    if (message.data != null) {
      info = new chrome.GenericTransferInfo(
          direction: chrome.Direction.OUT,
          endpoint: _outEndpoint.address,
          data: new chrome.ArrayBuffer.fromBytes(message.data));

      chrome.usb.bulkTransfer(usbConnection, info).then((chrome.TransferResultInfo result) {
        print('_bulkSend() result code: ${result.resultCode}');
      }).catchError((e) {
        print('error from _bulkSend(): ${e}');
      });
    }
  }

  Future<chrome.TransferResultInfo> _bulkReceive() {
    var info = new chrome.GenericTransferInfo(
        direction: chrome.Direction.IN,
        endpoint: _inEndpoint.address,
        length: _inEndpoint.maximumPacketSize);
    return chrome.usb.bulkTransfer(usbConnection, info);
  }

  /**
   * Release the USB interface.
   */
  Future dispose() {
    return chrome.usb.releaseInterface(usbConnection, usbInterface.interfaceNumber).
        whenComplete(() => _manager._disposeConnection(this));
  }

  String toString() =>
      '[connection, vendor=${usbConnection.vendorId}, product=${usbConnection.productId}]';
}

class _DeviceInfo {
  final int vendorId;
  final int productId;

  _DeviceInfo(this.vendorId, this.productId);
  _DeviceInfo.fromMap(Map m) : vendorId = m['vendorId'], productId = m['productId'];

  String toString() => '[vendor=${vendorId}, product=${productId}]';
}

/*
 * Common destination naming conventions include:
 *
 * "tcp:<host>:<port>" - host may be omitted to indicate localhost
 * "udp:<host>:<port>" - host may be omitted to indicate localhost
 * "local-dgram:<identifier>"
 * "local-stream:<identifier>"
 * "shell" - local shell service
 * "upload" - service for pushing files across (like aproto's /sync)
 * "fs-bridge" - FUSE protocol filesystem bridge
 */

class _AdbMessage {
  static final int A_SYNC = 0x434e5953;
  static final int A_CNXN = 0x4e584e43;
  static final int A_AUTH = 0x48545541;
  static final int A_OPEN = 0x4e45504f;
  static final int A_OKAY = 0x59414b4f;
  static final int A_CLSE = 0x45534c43;
  static final int A_WRTE = 0x45545257;

  // ADB protocol version
  static final int A_VERSION = 0x01000000;
  static final int HEADER_SIZE = 24;
  static final int MAX_PAYLOAD = 4096;

  /*
   * struct message {
   *   unsigned command;       /* command identifier constant      */
   *   unsigned arg0;          /* first argument                   */
   *   unsigned arg1;          /* second argument                  */
   *   unsigned data_length;   /* length of payload (0 is allowed) */
   *   unsigned data_crc32;    /* crc32 of data payload            */
   *   unsigned magic;         /* command ^ 0xffffffff             */
   * };
   */
  int command = 0;
  int arg0 = 0;
  int arg1 = 0;
  List<int> data;

  _AdbMessage({this.command, this.arg0, this.arg1, this.data, String dataString}) {
    if (dataString != null) {
      data = '${dataString}\0'.codeUnits;
    }
  }

  List<int> getHeaderBytes() {
    ByteData bytes = new ByteData(HEADER_SIZE);

    bytes.setUint32(0, command, Endianness.LITTLE_ENDIAN);
    bytes.setUint32(4, arg0, Endianness.LITTLE_ENDIAN);
    bytes.setUint32(8, arg1, Endianness.LITTLE_ENDIAN);
    bytes.setUint32(12, data == null ? 0 : data.length, Endianness.LITTLE_ENDIAN);
    bytes.setUint32(16, data == null ? 0 : _checksum(data), Endianness.LITTLE_ENDIAN);
    bytes.setUint32(20, command ^ 0xFFFFFFFF, Endianness.LITTLE_ENDIAN);

    return new Uint8List.view(bytes.buffer);
  }

  // ByteData

  int _checksum(List<int> data) {
    int result = 0;

    for (int i = 0; i < data.length; i++) {
      int x = data[i];
      if (x < 0) x += 256;
      result += x;
    }

    return result;
  }
}
