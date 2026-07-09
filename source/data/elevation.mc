// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Complications;
import Toybox.Lang;
import Toybox.SensorHistory;
import Toybox.UserProfile;

module Data {
	class Elevation extends Base {
		function initialize() {
			Base.initialize(
				Complications.COMPLICATION_TYPE_ALTITUDE,
				Resources.get(Rez.Strings.LABEL_ELEVATION)
			);
		}

		function getMaybe_() as Lang.Number? {
			return (
				self.getSensorHistoryData_(
					SensorHistory.getElevationHistory({ :period => 1 })
				) as Lang.Number?
			);
		}
	}
} // module Data
