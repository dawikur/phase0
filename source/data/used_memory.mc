// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Complications;
import Toybox.Lang;
import Toybox.System;
import Toybox.UserProfile;

module Data {
	class UsedMemory extends Base {
		function initialize() {
			Base.initialize(null, Resources.get(Rez.Strings.LABEL_USED_MEMORY));

			self.value_max = System.getSystemStats().totalMemory;
		}

		function get_() as Lang.Number? {
			return System.getSystemStats().usedMemory;
		}
	}
} // module Data
