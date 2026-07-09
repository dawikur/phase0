// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Complications;
import Toybox.Lang;
import Toybox.SensorHistory;
import Toybox.UserProfile;

module Data {
	class Stress extends Base {
		function initialize() {
			Base.initialize(
				Complications.COMPLICATION_TYPE_STRESS,
				Resources.get(Rez.Strings.LABEL_STRESS)
			);

			self.value_max = 100;
		}

		function getMaybe_() as Lang.Number? {
			return (
				self.getSensorHistoryData_(
					SensorHistory.getStressHistory({ :period => 1 })
				) as Lang.Number?
			);
		}
	}
} // module Data
