// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Lang;
import Toybox.UserProfile;
import Toybox.Complications;
import Toybox.System;

module Complication {

class Memory extends Metric {
	function initialize() {
		Metric.initialize(Complications.COMPLICATION_TYPE_INVALID);

		self.label_ = "Memory"; // TODO
	}

	function getValue() as Lang.Number or Null {
		return System.getSystemStats().usedMemory;
	}

	function getValueMax() as Lang.Number or Null {
		return System.getSystemStats().totalMemory;
	}
}

} // module Complication
