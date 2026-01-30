// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Lang;
import Toybox.System;

module Value {

class Battery extends Base {
	function initialize() {
		Base.initialize();

		self.label = Application.loadResource(Rez.Strings.LABEL_BATTERY) as Lang.String;
	}

	function get_() as Lang.Number or Null {
		return System.getSystemStats().battery.toNumber();
	}

	function getMax_() as Lang.Number or Null {
		return 100;
	}
}

} // module Value
