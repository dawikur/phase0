// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.UserProfile;
import Toybox.Complications;

module Complication {

class Steps extends Metric {
	function initialize() {
		Metric.initialize(Complications.COMPLICATION_TYPE_STEPS);

		self.label_ = Application.loadResource(Rez.Strings.LABEL_STEPS) as Lang.String;
	}

	hidden function getValue_() as Lang.Number or Null {
		return ActivityMonitor.getInfo().steps;
	}

	hidden function getValueMax_() as Lang.Number or Null {
		return ActivityMonitor.getInfo().stepGoal;
	}
}

} // module Complication
