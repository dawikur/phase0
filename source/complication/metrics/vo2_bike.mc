// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Lang;
import Toybox.UserProfile;
import Toybox.Complications;

module Complication {

class VO2Bike extends Metric {
	function initialize() {
		Metric.initialize(Complications.COMPLICATION_TYPE_VO2MAX_BIKE);

		self.label_ = Application.loadResource(Rez.Strings.LABEL_VO2_CYCLING) as Lang.String;
	}

	function getValue() as Lang.Number or Null {
		return UserProfile.getProfile().vo2maxCycling;
	}
}

} // module Complication
