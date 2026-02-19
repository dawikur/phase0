// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.ActivityMonitor;
import Toybox.Lang;
import Toybox.Complications;

module Data {

class PushDistance extends Base {
	function initialize() {
		Base.initialize(
			Complications.COMPLICATION_TYPE_INVALID,
			"Push Distance", // TODO
			Render.COLOR_GREEN
		);
	}

	function get() as Lang.Number or Null {
		// TODO: this is in centimeters, convertion to ft
		// System.DeviceSettings.distanceUnits
		return ActivityMonitor.getInfo().pushDistance;
	}
}

} // module Data
