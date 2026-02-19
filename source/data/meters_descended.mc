// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.ActivityMonitor;
import Toybox.Lang;
import Toybox.Complications;

module Data {

class MetersDescended extends Base {
	function initialize() {
		Base.initialize(
			Complications.COMPLICATION_TYPE_INVALID,
			"Meters Descended", // TODO
			Render.COLOR_MAGENTA
		);
	}

	function get() as Lang.Number or Null {
		// TODO: this is in meters, convertion to ft
		// System.DeviceSettings.elevationUnits
		var meters_descended = ActivityMonitor.getInfo().metersDescended;
		if (meters_descended != null) {
			return meters_descended.toNumber();
		}
		return null;
	}
}

} // module Data
