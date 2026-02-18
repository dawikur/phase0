// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Lang;
import Toybox.UserProfile;
import Toybox.Complications;

module Complication {

class SolarIntensity extends Metric {
	function initialize() {
		Metric.initialize(Complications.COMPLICATION_TYPE_INVALID);

		self.label_ = "Solar Intensity"; // TODO
	}

	function getValue() as Lang.Number or Null {
		var solar_intensity = System.getSystemStats().solarIntensity;
		if (solar_intensity != null) {
			return solar_intensity as Lang.Number;
		}
		return null;
	}

	function getValueMax() as Lang.Number or Null {
		return 100;
	}
}

} // module Complication
