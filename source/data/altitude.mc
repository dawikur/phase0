// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Complications;
import Toybox.Lang;
import Toybox.SensorHistory;
import Toybox.UserProfile;

module Data {
	class Altitude extends Base {
		function initialize() {
			Base.initialize(
				Toybox has :Complications
					? Complications.COMPLICATION_TYPE_ALTITUDE
					: null,
				Resources.get(Rez.Strings.LABEL_ALTITUDE)
			);
		}

		function get_() as Lang.Number? {
			return SensorProvider.get(
				self.name,
				SensorHistory.getElevationHistory({ :period => 1 })
			);
		}
	}
} // module Data
