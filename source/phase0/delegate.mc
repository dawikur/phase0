// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

module Phase0 {
	class Delegate extends WatchUi.WatchFaceDelegate {
		hidden var last_tap_time_ as Lang.Number = 0;

		hidden var view_ as View;

		function initialize(_view as View) {
			WatchFaceDelegate.initialize();

			view_ = _view;
		}

		function onPowerBudgetExceeded(
			_power_info as WatchUi.WatchFacePowerInfo
		) as Void {
			view_.onPowerBudgetExceeded();
		}

		function onPress(_click_event as WatchUi.ClickEvent) as Lang.Boolean {
			return view_.onPress(_click_event);
		}
	}
} // module Phase0
