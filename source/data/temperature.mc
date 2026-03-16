// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Lang;
import Toybox.UserProfile;
import Toybox.Complications;

module Data {

class Temperature extends Base {
	function initialize() {
		Base.initialize(
			Complications.COMPLICATION_TYPE_CURRENT_TEMPERATURE,
			"Temp",
			CATEGORY_ENERGY,
			Font.ICON_NONE
		);
	}

	function getMaybe() as Lang.Number or Null {
		return self.getSensorHistoryData_(
			SensorHistory.getTemperatureHistory({:period => 1})
		) as Lang.Number or Null;
	}
}

} // module Data
