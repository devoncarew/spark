// Copyright (c) 2014, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

/**
 * A simple debugger UI.
 */
library spark.debugger_ui;

import 'dart:html';

import 'debugger.dart';

class DebuggerUI {

  /**
   * TODO: doc
   */
  static void listenTo(DebuggerManager debuggerManager) {
    debuggerManager.onConnect.listen((DebuggerConnection connection) {
      DebuggerUI ui = new DebuggerUI(connection);
      ui.show();
    });
  }

  DebuggerConnection connection;
  DivElement div;

  DebuggerUI(this.connection) {
    div = new DivElement();
    div.style.zIndex = '100';
    div.style.position = 'fixed';
    div.style.top = '0';
    div.style.left = '200px';
    div.style.right = '200px';

    DivElement buttons = new DivElement();
    buttons.style.padding = '0.5em';
    buttons.style.background = 'rgb(84, 180, 84)';
    buttons.style.borderRadius = '2px';
    div.nodes.add(buttons);

    DivElement console = new DivElement();
    console.style.padding = '0 0.5em 0.25em 0.5em';
    console.style.background = 'rgb(84, 180, 84)';
    console.style.borderRadius = '2px';
    console.style.textOverflow = 'ellipsis';
    div.nodes.add(console);

    ButtonElement pauseButton = new ButtonElement();
    pauseButton.text = 'Pause';
    pauseButton.onClick.listen((_) {
      if (!pauseButton.disabled) connection.pause();
    });
    buttons.nodes.add(pauseButton);

    ButtonElement runButton = new ButtonElement();
    runButton.text = 'Resume';
    runButton.onClick.listen((_) {
      if (!runButton.disabled) connection.resume();
    });
    buttons.nodes.add(runButton);

    SpanElement span = new SpanElement();
    span.innerHtml = '&nbsp;';
    buttons.nodes.add(span);

    ButtonElement stepInButton = new ButtonElement();
    stepInButton.text = 'Step In';
    stepInButton.onClick.listen((_) {
      if (!stepInButton.disabled) connection.stepIn();
    });
    buttons.nodes.add(stepInButton);

    ButtonElement stepOverButton = new ButtonElement();
    stepOverButton.text = 'Step Over';
    stepOverButton.onClick.listen((_) {
      if (!stepOverButton.disabled) connection.stepOver();
    });
    buttons.nodes.add(stepOverButton);

    ButtonElement stepOutButton = new ButtonElement();
    stepOutButton.text = 'Step Out';
    stepOutButton.onClick.listen((_) {
      if (!stepOutButton.disabled) connection.stepOut();
    });
    buttons.nodes.add(stepOutButton);

    span = new SpanElement();
    span.innerHtml = '&nbsp;';
    buttons.nodes.add(span);

    ButtonElement stopButton = new ButtonElement();
    stopButton.text = 'Terminate';
    stopButton.onClick.listen((_) {
      connection.terminate();
    });
    buttons.nodes.add(stopButton);

    connection.onConsole.listen((String message) {
      console.text = message;
    });

    var updateButtons = () {
      pauseButton.disabled = connection.paused;
      runButton.disabled = !connection.paused;
      stepInButton.disabled = !connection.paused;
      stepOverButton.disabled = !connection.paused;
      stepOutButton.disabled = !connection.paused;
    };

    connection.onSuspended.listen((_) {
      updateButtons();
      print('suspended');
      print(connection.frames);
    });

    connection.onResumed.listen((_) {
      updateButtons();
      print('resumed');
    });

    connection.onClose.listen((_) {
      document.body.nodes.remove(div);
    });

    updateButtons();
  }

  void show() {
    document.body.nodes.add(div);
  }
}
