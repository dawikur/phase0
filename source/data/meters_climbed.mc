// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.ActivityMonitor;
import Toybox.Lang;
import Toybox.Complications;

module Data {

class MetersClimbed extends Base {
	function initialize() {
		Base.initialize(
			Complications.COMPLICATION_TYPE_INVALID,
			"Meters Climbed", // TODO
			Render.COLOR_MAGENTA
		);
	}

	function get() as Lang.Number or Null {
		// TODO: this is in meters, convertion to ft
		// System.DeviceSettings.elevationUnits
		var meters_climbed = ActivityMonitor.getInfo().metersClimbed;
		if (meters_climbed != null) {
			return meters_climbed.toNumber();
		}
		return null;
	}
}

} // module Data
