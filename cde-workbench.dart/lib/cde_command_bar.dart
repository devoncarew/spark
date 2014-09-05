// Copyright (c) 2014, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:async';

import 'package:cde_core/core.dart';
import 'package:cde_workbench/commands.dart';
import 'package:cde_workbench/keys.dart';
import 'package:paper_elements/paper_input.dart';
import 'package:polymer/polymer.dart';

/**
 * TODO: doc this
 */
@CustomTag('cde-command-bar')
class CdeCommandBar extends PolymerElement {
  CdeCommandBar.created() : super.created();

  bool isShowing() => !attributes.containsKey('hidden');

  void ready() {
    super.ready();

    Timer.run(() {
      CommandManager commands = Dependencies.instance[CommandManager];
      Keys keys = Dependencies.instance[Keys];
      keys.bind('macctrl-d', 'show-command-bar');
      commands.bind('show-command-bar', () => _showCommandBar());
    });
  }

  void show() {
    attributes.remove('hidden');
    PaperInput input = $['textInput'];
    input.focus();
    //input.jsElement;
    //input.shadowRoot.getElementById('input').focus();
  }

  void hide() {
    attributes['hidden'] = '';
  }

  void handleChange() {
    PaperInput input = $['textInput'];

    CommandManager commands = Dependencies.instance[CommandManager];
    String id = input.value;

    if (commands.getCommand(id) != null) {
      commands.executeCommand(null, id);
      hide();
    }
  }

  void _showCommandBar() {
    // TODO: we toggle for now
    if (isShowing()) {
      hide();
    } else {
      show();
    }
  }
}
