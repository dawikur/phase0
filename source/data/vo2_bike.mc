// Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

import Toybox.Complications;
import Toybox.Lang;
import Toybox.UserProfile;

module Data {
	class Vo2Bike extends Base {
		function initialize() {
			Base.initialize(
				Toybox has :Complications
					? Complications.COMPLICATION_TYPE_VO2MAX_BIKE
					: null,
				Resources.get(Rez.Strings.LABEL_VO2_BIKE),
				RefreshRate.MIN
			);
		}

		function refresh() as Void {
			self.value = UserProfile.getProfile().vo2maxCycling;
		}
	}
} // module Data
