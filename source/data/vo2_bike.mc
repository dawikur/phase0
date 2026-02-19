// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Lang;
import Toybox.UserProfile;
import Toybox.Complications;

module Data {

class VO2Bike extends Base {
	function initialize() {
		Base.initialize(
			Complications.COMPLICATION_TYPE_VO2MAX_BIKE,
			Application.loadResource(Rez.Strings.LABEL_VO2_CYCLING) as Lang.String,
			Render.COLOR_RED
		);
	}

	function get() as Lang.Number or Null {
		return UserProfile.getProfile().vo2maxCycling;
	}
}

} // module Data
