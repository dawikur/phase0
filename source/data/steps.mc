// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.ActivityMonitor;
import Toybox.Lang;
import Toybox.Complications;

module Data {

class Steps extends Base {
	function initialize() {
		Base.initialize(
			Complications.COMPLICATION_TYPE_STEPS,
			Application.loadResource(Rez.Strings.LABEL_STEPS) as Lang.String,
			Render.COLOR_GREEN
		);
	}

	function get() as Lang.Number or Null {
		return ActivityMonitor.getInfo().steps;
	}

	function getMax() as Lang.Number or Null {
		return ActivityMonitor.getInfo().stepGoal;
	}
}

} // module Data
