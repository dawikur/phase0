// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Lang;
import Toybox.Graphics;

module Element {

class HR extends Value {
	function initialize() {
		Value.initialize();

		self.label = "HR:";
	}

	function get_() as Lang.Number or Null {
		var history = ActivityMonitor.getHeartRateHistory(1, true);
		return history.getMax();
	}

	function getMax_() as Lang.Number or Null {
		var currentSport = UserProfile.getCurrentSport();
		var zones = UserProfile.getHeartRateZones(currentSport) as Lang.Array<Lang.Number>;
		return zones[5] as Lang.Number;
	}
}

} // module Element
