// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;

module Label {

class Seconds extends Base {
	var size_x as Lang.Number = 0;
	var size_y as Lang.Number = 0;

	hidden var placeholder_style_ as Label.Style;

	function initialize() {
		Base.initialize();

		self.justify_ = Graphics.TEXT_JUSTIFY_RIGHT;
		self.placeholder_style_ = new Label.Style(Font.DOT_REGULAR_THIN, 0x555555);
	}

	function refresh(_dc as Graphics.Dc) as Void {
		var clock = System.getClockTime();

		self.label_ = clock.sec.format("%02d");
	}

	function renderPlaceholder(_dc as Graphics.Dc) as Void {
		self.placeholder_style_.draw(_dc, self.pos_x, self.pos_y, "00", self.justify_);
	}
}

} // module Label
