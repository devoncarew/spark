// Copyright (c) 2014, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

library spark.html_builder;

import 'dart:async';

import 'package:logging/logging.dart';

import '../builder.dart';
import '../demo.dart';
import '../jobs.dart';
import '../workspace.dart';

Logger _logger = new Logger('spark.html_builder');

/**
 * A [Builder] implementation for Html files.
 */
class HtmlBuilder extends Builder {

  HtmlBuilder();

  Future build(ResourceChangeEvent event, ProgressMonitor monitor) {
    if (!DemoManager.isDemoMode) {
      return new Future.value();
    }

    List<ChangeDelta> projectDeletes = event.changes.where(
        (c) => c.resource is Project && c.isDelete).toList();

    if (projectDeletes.isNotEmpty) {
      // If we get a project delete, it'll be the only thing that we have to
      // process.
      return new Future.value();
    } else {
      List<File> files = event.modifiedFiles.where(_includeFile).toList();

      if (files.isEmpty) return new Future.value();

      Project project = files.first.project;

      project.workspace.pauseMarkerStream();
      return Future.forEach(files, _processFile).whenComplete(() {
        project.workspace.resumeMarkerStream();
      });
    }
  }

  bool _includeFile(File file) => !file.isDerived()
      && (file.name.endsWith('.html') || file.name.endsWith('.htm'));

  Future _processFile(File file) {
    if (file.name != 'spark_polymer_demo.html') {
      return new Future.value();
    }

    DemoManager.demoManager.reconcile();

    return new Future.value();
  }
}
