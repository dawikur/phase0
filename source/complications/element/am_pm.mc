// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Complications;
import Toybox.Graphics;
import Toybox.Lang;

module Complication {

class AmPm extends Base {
	var frame_ as Lang.String = "";
	var label_ as Lang.String = "";
	hidden var small_ as Lang.Boolean = false;

	function initialize(_small as Lang.Boolean) {
		Base.initialize(Complications.COMPLICATION_TYPE_INVALID);
		self.small_ = _small;
	}

	function refresh(_dc as Graphics.Dc) as Void {
		var borders_width = Render.iconsWidth(
			_dc,
			Lang.format("$1$$2$", [Fonts.ICON_AM_PM_BEGIN, Fonts.ICON_AM_PM_END])
		);
		var bar_width = Render.iconsWidth(_dc, "" + Fonts.ICON_AM_PM_FRAME);

		var bar_all_count = (self.size_x - borders_width) / bar_width;

		self.frame_ = "";
		self.frame_ += Fonts.ICON_AM_PM_BEGIN;
		for (var i = 0; i < bar_all_count; ++i) {
			self.frame_ += Fonts.ICON_AM_PM_FRAME;
		}
		self.frame_ += Fonts.ICON_AM_PM_END;

		var clock = System.getClockTime();

		self.label_ = Data.Units.getAmPm(clock.hour);

	}

	function render(_dc as Graphics.Dc) as Void {
		var pos_x = self.pos_x + self.size_x / 2;
		var pos_y = self.pos_y + self.size_y / 2;

		if (!self.small_) {
			Render.icons(_dc, pos_x, pos_y+Render.SPACING, self.frame_, self.frame_);
		}

		Render.text(
			_dc, pos_x, pos_y, self.label_,
			Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER,
			true
		);
	}
}

} // module Complication
