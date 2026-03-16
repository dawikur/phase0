// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Lang;
import Toybox.UserProfile;
import Toybox.Complications;

module Data {

class SolarIntensity extends Base {
	function initialize() {
		Base.initialize(
			Complications.COMPLICATION_TYPE_SOLAR_INPUT,
			"Solar",
			CATEGORY_ENERGY,
			Font.ICON_NONE
		);
	}

	function get() as Lang.Number or Null {
		var value = System.getSystemStats().solarIntensity;
		if (value != null) {
			if (value < 0) {
				return 0;
			}
			return value;
		}
		return null;
	}

	function getMax() as Lang.Number or Null {
		return 100;
	}
}

} // module Data
