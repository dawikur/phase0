// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.ActivityMonitor;
import Toybox.Graphics;
import Toybox.Lang;

module Field {

class Steps extends Base {
	function initialize(_small as Lang.Boolean) {
		Base.initialize(_small);

		self.header_ = Application.loadResource(Rez.Strings.LABEL_STEPS) as Lang.String;
	}

	function getValue_() as Lang.Number or Null {
		return ActivityMonitor.getInfo().steps;
	}

	function refresh(_dc as Graphics.Dc) as Void {
		self.max_value_ = ActivityMonitor.getInfo().stepGoal;
	}
}

} // module Field
