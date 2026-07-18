// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Complications;
import Toybox.Lang;
import Toybox.SensorHistory;
import Toybox.UserProfile;

module Data {
	class Stress extends Base {
		function initialize() {
			Base.initialize(
				Toybox has :Complications
					? Complications.COMPLICATION_TYPE_STRESS
					: null,
				Resources.get(Rez.Strings.LABEL_STRESS),
				RefreshRate.MIN
			);

			self.value_max = 100;
		}

		function get_() as Lang.Number? {
			return SensorProvider.get(
				self.name,
				SensorHistory.getStressHistory({ :period => 1 })
			);
		}
	}
} // module Data
