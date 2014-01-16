// Copyright (c) 2014, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

/**
 * TODO:
 */
library spark.mobile;

import 'dart:async';

import 'package:chrome/chrome_app.dart' as chrome;

// Nexus 5: { "vendorId": 6353, "productId": 20194 }

/**
 * TODO:
 */
class MobileManager {
  final int _ADB_INTERFACE_CLASS = 255;
  final int _ADB_INTERFACE_SUBCLASS = 66;
  final int _ADB_INTERFACE_ID = 1;

  final List<MobileConnection> connections = [];

  final List<_DeviceInfo> _deviceInfos = [];

  StreamController<MobileConnection> _connectController = new StreamController.broadcast();
  StreamController<MobileConnection> _disconnectController = new StreamController.broadcast();

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
   * Scan for and attempt to connect to new mobile devices.
   *
   * Generally this should only be called if there are no current connections.
   */
  void scanForDevices() {
    _DeviceInfo info = _deviceInfos.first;

    var options = new chrome.EnumerateDevicesAndRequestAccessOptions(
        vendorId: info.vendorId, productId: info.productId);

    chrome.usb.findDevices(options).then((List<chrome.ConnectionHandle> connections) {
      if (connections.isNotEmpty) {
        chrome.ConnectionHandle connection = connections.first;

        chrome.usb.listInterfaces(connection).then((List<chrome.InterfaceDescriptor> interfaces) {
          bool foundDevice = false;

          for (chrome.InterfaceDescriptor interface in interfaces) {
            if (interface.interfaceClass == _ADB_INTERFACE_CLASS &&
                interface.interfaceSubclass == _ADB_INTERFACE_SUBCLASS &&
                interface.interfaceProtocol == _ADB_INTERFACE_ID) {
              foundDevice = true;
              _claimInterface(connection, interface);
            }
          }

          if (!foundDevice) {
            chrome.usb.closeDevice(connection);
          }
        });
      }

      // Close the other n-1 devices.
      if (connections.length > 1) {
        connections.skip(1).forEach((conn) => chrome.usb.closeDevice(conn));
      }
    });
  }

  Stream<MobileConnection> get onMobileConnected => _connectController.stream;

  Stream<MobileConnection> get onMobileDisconnected => _disconnectController.stream;

  void _claimInterface(chrome.ConnectionHandle connection, chrome.InterfaceDescriptor interface) {
    chrome.usb.claimInterface(connection, interface.interfaceNumber).then((_) {
      MobileConnection conn = new MobileConnection._(this, connection, interface);
      connections.add(conn);
      _connectController.add(conn);
    });
  }

  void _disposeConnection(MobileConnection connection) {
    connections.remove(connection);
    _disconnectController.add(connection);
  }
}

/**
 * TODO:
 */
class MobileConnection {
  final MobileManager _manager;
  final chrome.ConnectionHandle usbConnection;
  final chrome.InterfaceDescriptor usbInterface;

  MobileConnection._(this._manager, this.usbConnection, this.usbInterface);

  bool amIHappy() {
    // TODO:

  }

  /**
   * Release the USB interface.
   */
  Future dispose() {
    return chrome.usb.releaseInterface(usbConnection, usbInterface.interfaceNumber).
        whenComplete(() => _manager._disposeConnection(this));
  }
}

class _DeviceInfo {
  final int vendorId;
  final int productId;

  _DeviceInfo(this.vendorId, this.productId);
  _DeviceInfo.fromMap(Map m) : vendorId = m['vendorId'], productId = m['productId'];

  String toString() => '[vendor=${vendorId}, product=${productId}]';
}
