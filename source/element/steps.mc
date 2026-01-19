// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Lang;
import Toybox.Graphics;

module Element {

class Steps extends Value {
	function initialize() {
		Value.initialize();

		self.label = "Steps:";
	}

	function get_() as Lang.Number or Null {
		// TODO: get actuall number
		return 78;
	}

	function getMax_() as Lang.Number or Null {
		// TODO: get actuall number
		return 78;
	}
}

} // module Element
