// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Application;
import Toybox.System;
import Toybox.WatchUi;

typedef InitialView as
	[WatchUi.Views] or
	[WatchUi.Views, WatchUi.InputDelegates];

class App extends Application.AppBase {
	var view_ as Phase0.View;
	var delegate_ as Phase0.Delegate;

	function initialize() {
		AppBase.initialize();

		self.view_ = new Phase0.View();
		self.delegate_ = new Phase0.Delegate(view_);
	}

	function getInitialView() as $.InitialView {
		return [self.view_, self.delegate_];
	}

	function onSettingsChanged() as Void {
		Data.Units.refreshSettings();

		self.view_.onSettingsChanged();
	}
}

function getApp() as App {
	return Application.getApp() as App;
}
