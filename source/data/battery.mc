// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.ActivityMonitor;
import Toybox.Lang;
import Toybox.Complications;

module Data {

class Battery extends Base {
	function initialize() {
		Base.initialize(
			Complications.COMPLICATION_TYPE_BATTERY,
			Resources.load(Rez.Strings.LABEL_BATTERY),
			CATEGORY_SYSTEM,
			Fonts.ICON_NONE
		);

		self.value_max = 100;
	}

	function get_() as Lang.Number or Null {
		return System.getSystemStats().battery.toNumber();
	}
}

} // module Data
