// Copyright (c) 2014, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

library spark.ui.polymer.files_view;

import 'package:polymer/polymer.dart';
import 'package:spark_widgets/spark_tree_view/spark_tree_view_model.dart';
import 'package:spark_widgets/spark_tree_view/src/spark_tree_view_node.dart';

@CustomTag('files-view')
class FilesView extends SparkTreeViewNode {
  @published SparkTreeViewModel model;

  /// Constructor.
  FilesView.created() : super.created();

  @override
  void enteredView() {
    super.enteredView();
  }
}
