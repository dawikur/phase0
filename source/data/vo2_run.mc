// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Complications;
import Toybox.Lang;
import Toybox.UserProfile;

module Data {

class Vo2Run extends Base {
	function initialize() {
		Base.initialize(
			Complications.COMPLICATION_TYPE_VO2MAX_RUN,
			Resources.get(Rez.Strings.LABEL_VO2_RUN),
			CATEGORY_PHYSIOLOGICAL
		);
	}

	function get_() as Lang.Number or Null {
		return UserProfile.getProfile().vo2maxRunning;
	}
}

} // module Data
