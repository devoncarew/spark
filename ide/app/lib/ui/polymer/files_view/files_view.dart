// Copyright (c) 2014, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

library spark.ui.polymer.files_view;

//import 'dart:html';

import 'package:polymer/polymer.dart';
import 'package:spark_widgets/common/spark_widget.dart';

import '../../../../spark_flags.dart';

@CustomTag('files-view')
class FilesView extends SparkWidget {

  //factory FilesView() => new Element.tag('files-view');

  FilesView.created() : super.created();

  @override
  void enteredView() {
    SparkFlags.showFilesView = true;

    print('files-view created');
  }
}
