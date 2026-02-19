// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Lang;
import Toybox.UserProfile;
import Toybox.Complications;

module Data {

class SolarIntensity extends Base {
	function initialize() {
		Base.initialize(
			Complications.COMPLICATION_TYPE_SOLAR_INPUT,
			"Solar Intensity", // TODO
			Render.COLOR_YELLOW
		);
	}

	function get() as Lang.Number or Null {
		return System.getSystemStats().solarIntensity;
	}

	function getMax() as Lang.Number or Null {
		return 100;
	}
}

} // module Data
