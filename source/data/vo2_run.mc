// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Complications;
import Toybox.Lang;
import Toybox.UserProfile;

module Data {
	class Vo2Run extends Base {
		function initialize() {
			Base.initialize(
				Toybox has :Complications
					? Complications.COMPLICATION_TYPE_VO2MAX_RUN
					: null,
				Resources.get(Rez.Strings.LABEL_VO2_RUN),
				RefreshRate.MIN
			);
		}

		function refresh() as Void {
			self.value = UserProfile.getProfile().vo2maxRunning;
		}
	}
} // module Data
