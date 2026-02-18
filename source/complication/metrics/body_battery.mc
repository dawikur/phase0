// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Lang;
import Toybox.UserProfile;
import Toybox.Complications;

module Complication {

class BodyBattery extends Metric {
	function initialize() {
		Metric.initialize(Complications.COMPLICATION_TYPE_INVALID);

		self.label_ = "BodyBattery"; // TODO
	}

	function getValue() as Lang.Number or Null {
		var body_battery_iterator = SensorHistory.getBodyBatteryHistory({:period => 1});
		if (body_battery_iterator != null) {
			var body_battery_maybe = body_battery_iterator.next();
			if (body_battery_maybe != null) {
				return body_battery_maybe.data as Lang.Number;
			}
		}
		return null;
	}

	function getValueMax() as Lang.Number or Null {
		return 100;
	}
}

} // module Complication
