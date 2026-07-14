// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Complications;
import Toybox.Lang;
import Toybox.SensorHistory;
import Toybox.UserProfile;

module Data {
	class Temperature extends Base {
		function initialize() {
			Base.initialize(
				Toybox has :Complications
					? Complications.COMPLICATION_TYPE_CURRENT_TEMPERATURE
					: null,
				Resources.get(Rez.Strings.LABEL_TEMPERATURE)
			);
		}

		function get_() as Lang.Number? {
			return SensorProvider.get(
				self.name,
				SensorHistory.getTemperatureHistory({ :period => 1 })
			);
		}
	}
} // module Data
