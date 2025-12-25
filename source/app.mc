// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Application;
import Toybox.WatchUi;

import Toybox.System;

typedef InitialView as
	[WatchUi.Views] or
	[WatchUi.Views, WatchUi.InputDelegates];

class App extends Application.AppBase {
	var view_ as Phase0.View;
	var delegate_ as Phase0.Delegate;

	function initialize() {
		AppBase.initialize();

		view_ = new Phase0.View();
		delegate_ = new Phase0.Delegate(view_);
	}

	function getInitialView() as $.InitialView {
		if (WatchUi has :WatchFaceDelegate) {
			return [view_, delegate_];
		} else {
			return [view_];
		}
	}

	function onSettingsChanged() as Void {
		view_.onSettingsChanged();
	}
}

function getApp() as App {
	return Application.getApp() as App;
}
