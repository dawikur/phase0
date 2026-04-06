// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Lang;
import Toybox.UserProfile;
import Toybox.Complications;

module Data {

class Elevation extends Base {
	function initialize() {
		Base.initialize(
			Complications.COMPLICATION_TYPE_ALTITUDE,
			Resources.load(Rez.Strings.LABEL_ELEVATION),
			CATEGORY_VERTICAL,
			Fonts.ICON_NONE
		);
	}

	function getMaybe_() as Lang.Number or Null {
		return self.getSensorHistoryData_(
			SensorHistory.getElevationHistory({:period => 1})
		) as Lang.Number or Null;
	}
}

} // module Data
