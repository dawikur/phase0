// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

module Element {

class Base {
	var pos_x as Lang.Number = 0;
	var pos_y as Lang.Number = 0;

	hidden var label_ as Lang.String = "";
	hidden var justify_ as Lang.Number = 0;

	function initialize() {
		self.justify_ = Graphics.TEXT_JUSTIFY_LEFT;
	}

	function width(_dc as Graphics.Dc) as Lang.Number {
		return Render.textWidth(_dc, self.label_);
	}

	function height(_dc as Graphics.Dc) as Lang.Number {
		return Render.textHeight(_dc);
	}

	function render(_dc as Graphics.Dc) as Void {
		if (self.label_.length() == 0) {
			self.refresh(_dc);
		}

		if (self.label_.length() == 0) {
			return;
		}

		Render.text(_dc, self.pos_x, self.pos_y, self.label_, self.justify_);
	}

	function refresh(_dc as Graphics.Dc) as Void {
	}
}

} // module Element
