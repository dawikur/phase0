// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Lang;
import Toybox.ActivityMonitor;

module Value {

class Steps extends Base {
	function initialize() {
		Base.initialize();

		self.label = Application.loadResource(Rez.Strings.LABEL_STEPS) as Lang.String;
	}

	function get_() as Lang.Number or Null {
		return ActivityMonitor.getInfo().steps;
	}

	function getMax_() as Lang.Number or Null {
		return ActivityMonitor.getInfo().stepGoal;
	}
}

} // module Value
