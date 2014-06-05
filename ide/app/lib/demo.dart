// Copyright (c) 2014, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

library spark.demo;

import 'workspace.dart';
import 'package_mgmt/pub.dart';

class DemoManager {
  static DemoManager _manager;

  static bool get isDemoMode => _manager != null;

  static DemoManager get demoManager => _manager;

  static bool isDemoProject(Project project) => project.name == 'ide';

  static void init(Workspace workspace, DemoState demoState) {
    _manager = new DemoManager(workspace, demoState);
  }

  static void dispose() {
    _manager = null;
  }

  final Workspace workspace;
  final DemoState demoState;

  DemoManager(this.workspace, this.demoState);

  bool get hasDemoProject => demoProject != null;

  Project get demoProject => workspace.getChild('ide');

  void reconcile() {
    // Check for the 'analyzer' dependency in the pubspec.
    File pubspecFile = demoProject.getChild('pubspec.yaml');

    pubspecFile.getContents().then((String str) {
      bool hasAnalyzer = false;

      try {
        PubSpecInfo info = new PubSpecInfo.parse(str);
        hasAnalyzer = info.getDependencies().contains('analyzer');
      } catch (e) { }

      demoState.hasAnalyzer = hasAnalyzer;
    });

    File htmlFile = demoProject.getChildPath('app/spark_polymer_demo.html');
    htmlFile.getContents().then((String contents) {
      // Check for the file view.
      demoState.hasFilesView = contents.contains('<files-view>');

      // Check for the git clone button.
      demoState.hasGitCloneButton = contents.contains('<git-clone-button>');

      // Check for the deploy to mobile button.
      demoState.hasMobileDeployButton = contents.contains('<mobile-deploy-button>');
    });
  }
}

abstract class DemoState {
  bool hasFilesView;
  bool hasGitCloneButton;
  bool hasAnalyzer;
  bool hasMobileDeployButton;
}
