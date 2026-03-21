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
			Fonts.ICON_NONE
		);

		self.value_max = 100;
	}

	function get_() as Lang.Number or Null {
		var value = System.getSystemStats().solarIntensity;
		if (value != null and 0 <= value) {
			return value;
		}
		return null;
	}
}

} // module Data
