// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Lang;
import Toybox.UserProfile;
import Toybox.Complications;

module Data {

class BodyBattery extends Base {
	function initialize() {
		Base.initialize(
			Complications.COMPLICATION_TYPE_BODY_BATTERY,
			"BodyBattery", // TODO
			Render.COLOR_CYAN
		);
	}

	function get() as Lang.Number or Null {
		var body_battery_iterator = SensorHistory.getBodyBatteryHistory({:period => 1});
		if (body_battery_iterator != null) {
			var body_battery_maybe = body_battery_iterator.next();
			if (body_battery_maybe != null) {
				return body_battery_maybe.data as Lang.Number;
			}
		}
		return null;
	}

	function getMax() as Lang.Number or Null {
		return 100;
	}
}

} // module Data
