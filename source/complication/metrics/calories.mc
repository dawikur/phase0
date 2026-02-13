// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.ActivityMonitor;
import Toybox.Lang;
import Toybox.Complications;

module Complication {

class Calories extends Metric {
	function initialize() {
		Metric.initialize(Complications.COMPLICATION_TYPE_CALORIES);

		self.label_ = Application.loadResource(Rez.Strings.LABEL_CALORIES) as Lang.String;
	}

	hidden function getValue_() as Lang.Number or Null {
		return ActivityMonitor.getInfo().calories;
	}
}

} // module Complication
