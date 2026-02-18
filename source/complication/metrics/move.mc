// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Lang;
import Toybox.UserProfile;
import Toybox.Complications;

module Complication {

class Move extends Metric {
	function initialize() {
		Metric.initialize(Complications.COMPLICATION_TYPE_INVALID);

		self.label_ = "Move"; // TODO
	}

	function getValue() as Lang.Number or Null {
		var activity_monitor = ActivityMonitor.getInfo();
		var move_maybe = activity_monitor.moveBarLevel;
		if (move_maybe != null) {
			return move_maybe as Lang.Number;
		}
		return null;
	}

	function getValueMax() as Lang.Number or Null {
		return 5;
	}
}

} // module Complication
