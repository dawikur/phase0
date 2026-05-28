// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Complications;
import Toybox.Lang;
import Toybox.UserProfile;

module Data {

class RespirationRate extends Base {
	function initialize() {
		Base.initialize(
			Complications.COMPLICATION_TYPE_RESPIRATION_RATE,
			Resources.load(Rez.Strings.LABEL_RESPIRATION_RATE),
			CATEGORY_PHYSIOLOGICAL
		);
	}

	function get_() as Lang.Number or Null {
		return ActivityMonitor.getInfo().respirationRate;
	}
}

} // module Data
