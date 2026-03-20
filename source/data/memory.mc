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
			"Mem",
			CATEGORY_SYSTEM,
			Fonts.ICON_NONE
		);
	}

	function get() as Lang.Number or Null {
		return System.getSystemStats().usedMemory;
	}

	function getMax() as Lang.Number or Null {
		return System.getSystemStats().totalMemory;
	}
}

} // module Data
