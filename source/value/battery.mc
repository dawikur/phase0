// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Lang;
import Toybox.System;

module Value {

class Battery extends Base {
	function initialize(_small as Lang.Boolean) {
		Base.initialize(_small);

		self.header_ = Application.loadResource(Rez.Strings.LABEL_BATTERY) as Lang.String;
		self.max_value_ = 100;
	}

	function getValue_() as Lang.Number or Null {
		return System.getSystemStats().battery.toNumber();
	}
}

} // module Value
