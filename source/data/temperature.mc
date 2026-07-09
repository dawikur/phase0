// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Complications;
import Toybox.Lang;
import Toybox.SensorHistory;
import Toybox.UserProfile;

module Data {
	class Temperature extends Base {
		function initialize() {
			Base.initialize(
				Complications.COMPLICATION_TYPE_CURRENT_TEMPERATURE,
				Resources.get(Rez.Strings.LABEL_TEMPERATURE)
			);
		}

		function getMaybe_() as Lang.Number? {
			return (
				self.getSensorHistoryData_(
					SensorHistory.getTemperatureHistory({ :period => 1 })
				) as Lang.Number?
			);
		}
	}
} // module Data
