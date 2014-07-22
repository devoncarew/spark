// Copyright (c) 2014, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

/**
 * TODO: Add documentation.
 */
library spark.ui_access;

import 'dart:async';
import 'dart:html';

import 'package:spark_widgets/common/spark_widget.dart';
import 'package:spark_widgets/spark_button/spark_button.dart';
import 'package:spark_widgets/spark_dialog/spark_dialog.dart';
import 'package:spark_widgets/spark_dialog_button/spark_dialog_button.dart';
import 'package:spark_widgets/spark_menu_button/spark_menu_button.dart';
import 'package:spark_widgets/spark_menu_item/spark_menu_item.dart';
import 'package:spark_widgets/spark_modal/spark_modal.dart';

import '../../spark_polymer_ui.dart';

class SparkUIAccess {
  static SparkUIAccess _instance;

  MenuItemAccess newProjectMenu =
      new MenuItemAccess("project-new", "newProjectDialog");
  MenuItemAccess gitCloneMenu =
      new MenuItemAccess("git-clone", "gitCloneDialog");
  MenuItemAccess aboutMenu =
      new MenuItemAccess("help-about", "aboutDialog");

  DialogAccess get aboutDialog => aboutMenu.dialog;
  DialogAccess get gitCloneDialog => gitCloneMenu.dialog;
  DialogAccess get newProjecteDialog => newProjectMenu.dialog;

  DialogAccess get okCancelDialog => new DialogAccess("okCancelDialog");

  SparkMenuButton get menu => getUIElement("#mainMenu");

  SparkPolymerUI get _ui => document.querySelector('#topUi');
  SparkButton get _menuButton => getUIElement("#mainMenu > spark-button");

  factory SparkUIAccess() {
    if (_instance == null) _instance = new SparkUIAccess._internal();
    return _instance;
  }

  Element getUIElement(String selectors) => _ui.getShadowDomElement(selectors);

  void _sendMouseEvent(Element element, String eventType) {
    Rectangle<int> bounds = element.getBoundingClientRect();
    element.dispatchEvent(new MouseEvent(eventType,
        clientX: bounds.left.toInt() + bounds.width ~/ 2,
        clientY: bounds.top.toInt() + bounds.height ~/ 2));
  }

  void selectMenu() => _menuButton.click();

  void clickElement(Element element) {
    _sendMouseEvent(element, "mouseover");
    _sendMouseEvent(element, "click");
  }

  SparkUIAccess._internal();
}

class MenuItemAccess {
  final String _menuItemId;
  DialogAccess _dialog = null;

  DialogAccess get dialog => _dialog;

  SparkUIAccess get _sparkAccess => new SparkUIAccess();

  SparkMenuItem get _menuItem => _getMenuItem(_menuItemId);

  MenuItemAccess(this._menuItemId, [String _dialogId]) {
    if (_dialogId != null) {
      _dialog = new DialogAccess(_dialogId);
    }
  }

  void select() => _sparkAccess.clickElement(_menuItem);

  SparkMenuItem _getMenuItem(String id) =>
      _sparkAccess.menu.querySelector("spark-menu-item[action-id=$id]");
}

class DialogAccess {
  final String id;

  SparkModal get modalElement => _dialog.getShadowDomElement("#modal");
  bool get opened => modalElement.opened;

  bool get fullyVisible {
    Rectangle<int> bounds = modalElement.getBoundingClientRect();
    var elementFromPoint = _sparkAccess._ui.shadowRoot.elementFromPoint(
        bounds.left.toInt() + bounds.width ~/ 2,
        bounds.top.toInt() + bounds.height ~/ 2);
    SparkDialog dialog = _dialog;
    return elementFromPoint == _dialog || _dialog.contains(elementFromPoint);
  }

  Stream get onTransitionComplete => modalElement.on['transition-complete'];

  SparkUIAccess get _sparkAccess => new SparkUIAccess();
  SparkDialog get _dialog => _sparkAccess.getUIElement("#$id");
  List<SparkDialogButton> get _dialogButtons =>
      _dialog.querySelectorAll("spark-dialog-button");

  DialogAccess(this.id);

  void clickButtonWithTitle(String title) =>
      _sparkAccess.clickElement(_getButtonByTitle(title));

  void clickButtonWithSelector(String query) =>
      _sparkAccess.clickElement(_getButtonBySelector(query));

  SparkWidget _getButtonByTitle(String title) =>
      _dialogButtons.firstWhere((b) => b.text.toLowerCase() == title.toLowerCase());

  SparkWidget _getButtonBySelector(String query) {
    SparkWidget button = _dialog.querySelector(query);

    if (button == null) button = _dialog.getShadowDomElement(query);

    if (button == null) throw "Could not find button with selector $query";

    return button;
  }
}
