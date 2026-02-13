// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Lang;
import Toybox.UserProfile;
import Toybox.Complications;

module Complication {

class VO2Run extends Metric {
	function initialize() {
		Metric.initialize(Complications.COMPLICATION_TYPE_VO2MAX_RUN);

		self.label_ = Application.loadResource(Rez.Strings.LABEL_VO2_RUNNING) as Lang.String;
	}

	hidden function getValue_() as Lang.Number or Null {
		return UserProfile.getProfile().vo2maxRunning;
	}
}

} // module Complication
