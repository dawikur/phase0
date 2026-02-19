// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Lang;
import Toybox.UserProfile;
import Toybox.Complications;

module Data {

class RespirationRate extends Base {
	function initialize() {
		Base.initialize(
			Complications.COMPLICATION_TYPE_RESPIRATION_RATE,
			"Respiration Rate", // TODO
			Render.COLOR_RED
		);
	}

	function get() as Lang.Number or Null {
		return ActivityMonitor.getInfo().respirationRate;
	}
}

} // module Data
