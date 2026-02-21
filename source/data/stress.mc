// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Lang;
import Toybox.UserProfile;
import Toybox.Complications;

module Data {

class Stress extends Base {
	function initialize() {
		Base.initialize(
			Complications.COMPLICATION_TYPE_STRESS,
			"Strs",
			CATEGORY_ENERGY
		);
	}

	function get() as Lang.Number or Null {
		return ActivityMonitor.getInfo().stressScore;
	}

	function getMax() as Lang.Number or Null {
		return 100;
	}
}

} // module Data
