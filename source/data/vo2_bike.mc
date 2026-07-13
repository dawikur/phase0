// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Complications;
import Toybox.Lang;
import Toybox.UserProfile;

module Data {
	class Vo2Bike extends Base {
		function initialize() {
			Base.initialize(
				Base.Complication(:vo2_bike),
				Resources.get(Rez.Strings.LABEL_VO2_BIKE)
			);
		}

		function get_() as Lang.Number? {
			return UserProfile.getProfile().vo2maxCycling;
		}
	}
} // module Data
