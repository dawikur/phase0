// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Application;
import Toybox.System;
import Toybox.WatchUi;

typedef InitialView as
	[WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates];

class App extends Application.AppBase {
	var view_ as Phase0.View;
	var delegate_ as Phase0.Delegate;

	function initialize() {
		AppBase.initialize();

		self.view_ = new Phase0.View();
		self.delegate_ = new Phase0.Delegate(view_);

		self.onSettingsChanged();

		System.println("Phase0 initialized");
	}

	function getInitialView() as $.InitialView {
		return [self.view_, self.delegate_];
	}

	function onSettingsChanged() as Void {
		Data.Units.refresh();

		SensorProvider.clearCache();
		WeatherProvider.clearCache();

		var properties = new Properties();

		Render.accent = properties.general.accent;
		Render.foreground = properties.general.foreground;
		Render.shade = properties.general.shade;
		Render.background = properties.general.background;

		self.view_.onSettingsChanged(properties);
	}
}

function getApp() as App {
	return Application.getApp() as App;
}
