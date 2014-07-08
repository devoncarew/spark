// Copyright (c) 2014, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

/**
 * Browser utility code.
 */
library spark.browser;

import 'dart:async';
import 'dart:html';

import 'package:chrome/chrome_app.dart' as chrome;

class BrowserHelper {
  Future openTab(String url) {
    if (chrome.browser.available) {
      return chrome.browser.openTab(new chrome.OpenTabOptions(url: url));
    } else {
      window.open(url, '_blank');
      return new Future.value();
    }
  }
}
