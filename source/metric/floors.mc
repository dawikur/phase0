// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.ActivityMonitor;
import Toybox.Graphics;
import Toybox.Lang;

module Metric {

class Floors extends Base {
	function initialize() {
		Base.initialize();

		self.header_ = Application.loadResource(Rez.Strings.LABEL_FLOORS) as Lang.String;
	}

	function getValue_() as Lang.Number or Null {
		return ActivityMonitor.getInfo().floorsClimbed;
	}

	function refresh(_dc as Graphics.Dc) as Void {
		self.max_value_ = ActivityMonitor.getInfo().floorsClimbedGoal;
	}
}

} // module Metric
