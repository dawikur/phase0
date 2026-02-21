// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.ActivityMonitor;
import Toybox.Lang;
import Toybox.Complications;

module Data {

class Battery extends Base {
	function initialize() {
		Base.initialize(
			Complications.COMPLICATION_TYPE_BATTERY,
			"Batt",
			CATEGORY_SYSTEM
		);
	}

	function get() as Lang.Number or Null {
		return System.getSystemStats().battery.toNumber();
	}

	function getMax() as Lang.Number or Null {
		return 100;
	}
}

} // module Data
