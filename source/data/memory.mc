// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Lang;
import Toybox.UserProfile;
import Toybox.Complications;
import Toybox.System;

module Data {

class Memory extends Base {
	function initialize() {
		Base.initialize(
			Complications.COMPLICATION_TYPE_INVALID,
			Resources.load(Rez.Strings.LABEL_MEMORY),
			CATEGORY_SYSTEM,
			Fonts.ICON_NONE
		);

		self.value_max = System.getSystemStats().totalMemory;
	}

	function get_() as Lang.Number or Null {
		return System.getSystemStats().usedMemory;
	}
}

} // module Data
