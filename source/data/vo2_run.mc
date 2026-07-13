// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Complications;
import Toybox.Lang;
import Toybox.UserProfile;

module Data {
	class Vo2Run extends Base {
		function initialize() {
			Base.initialize(
				Base.Complication(:vo2_run),
				Resources.get(Rez.Strings.LABEL_VO2_RUN)
			);
		}

		function get_() as Lang.Number? {
			return UserProfile.getProfile().vo2maxRunning;
		}
	}
} // module Data
