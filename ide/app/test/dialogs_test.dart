// Copyright (c) 2014, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

library spark.dialogs_test;

import 'dart:async';
import 'dart:html';

import 'package:spark_widgets/spark_dialog/spark_dialog.dart';
import 'package:unittest/unittest.dart';

import '../spark.dart';

Element _app;

defineTests(Spark spark) {
  // TODO: use the spark variable

  _app = document.querySelector('#topUi');

  group('dialogs.aboutDialog', () {
    final String id = 'aboutDialog';

    test('closeButton', () {
      spark.actionManager.getAction('help-about').invoke();

      return _testDialogVisible(id, true).then((_) {
        return _testDialogCloseX(id);
      });

//      SparkDialog dialog = _getDialog('#aboutDialog');
//      dialog.show();
//      print('foo');

      // TODO: show it programatically (using an action)
      // verify that it is visible
      // TODO: close it with a 'click' on #closingX
      // TODO: verify that it is closed

    });

    test('closeButton', () {
      // TODO: show it programatically
      // TODO: close it with a 'click' on the [dismiss] button
      // TODO: verify that it is closed

    });
  });
}

Future _testDialogVisible(String id, bool value) {
  SparkDialog dialog = _getDialog(id);

  return waitUntilCondition(
      () => (dialog.isShowing == value), _threeSeconds);
}

Future _testDialogCloseX(String id) {
  SparkDialog dialog = _getDialog(id);

  expect(dialog.isShowing, true);

  Element closeButton = dialog.shadowRoot.querySelector('#closingX');
  closeButton.onClick.listen(print);

  closeButton.click();

  return _testDialogVisible(id, false).then((_) {
    expect(dialog.isShowing, false);
  });
}

SparkDialog _getDialog(String id) => _app.shadowRoot.querySelector('#${id}');

final Duration _threeSeconds = new Duration(seconds: 3);
final Duration _smallDuration = new Duration(milliseconds: 100);

Future waitUntilCondition(Function condition, Duration timeout) {
  if (timeout.inMilliseconds < 0) {
    return new Future.error('timeout');
  } else {
    bool result = condition();
    print('dialog condition = ${condition}');
    if (result) {
      return new Future.value(result);
    } else {
      return waitUntilCondition(condition, timeout - _smallDuration);
    }
  }
}
