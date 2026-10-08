// Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

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

	(:display_amoled)
	function onDisplayModeChanged() as Void {
		self.view_.handleDisplayModeChanged();
	}

	function onSettingsChanged() as Void {
		Data.Units.refresh();

		SensorProvider.clearCache();
		WeatherProvider.clearCache();

		var properties = new Properties();

		Render.accent = properties.global.accent;
		Render.foreground = properties.global.foreground;
		Render.shade = properties.global.shade;
		Render.background = properties.global.background;

		self.view_.onSettingsChanged(properties);
	}
}

function getApp() as App {
	return Application.getApp() as App;
}
