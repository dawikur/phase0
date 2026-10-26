// Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

import Toybox.Complications;
import Toybox.Lang;
import Toybox.System;
import Toybox.UserProfile;

module Data {
	(:data_gauge)
	class UsedMemory extends Base {
		function initialize() {
			Base.initialize(
				Toybox has :Complications
					? Complications.COMPLICATION_TYPE_INVALID
					: null,
				Resources.get(Rez.Strings.LABEL_USED_MEMORY),
				Data.RefreshRate.MIN
			);

			self.value_max = System.getSystemStats().totalMemory;
		}

		function refresh() as Void {
			self.value = System.getSystemStats().usedMemory;
		}
	}
} // module Data
