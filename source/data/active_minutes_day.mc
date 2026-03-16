// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.ActivityMonitor;
import Toybox.Lang;
import Toybox.Complications;

module Data {

class ActiveMinutesDay extends Base {
	function initialize() {
		Base.initialize(
			Complications.COMPLICATION_TYPE_INVALID,
			"Act/D",
			CATEGORY_MOVEMENT,
			Font.ICON_NONE
		);
	}

	function get() as Lang.Number or Null {
		var active_minutes = ActivityMonitor.getInfo().activeMinutesDay;
		if (active_minutes != null) {
			return active_minutes.total;
		}
		return null;
	}
}

} // module Data
