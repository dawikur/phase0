// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Lang;
import Toybox.System;
import Toybox.Graphics;

module Element {

class Battery {
	var pos_x as Lang.Number = 0;
	var pos_y as Lang.Number = 0;

	var size_x as Lang.Number = 0;

	var charge_ as Lang.String = "";
	var frame_ as Lang.String = "";
	var charging_ as Lang.String = "";

	function initialize() {
	}

	function render(_dc as Graphics.Dc) as Void {
		if (System.getSystemStats().charging) {
			Render.icons(_dc, self.pos_x, self.pos_y, self.charging_, "");
		} else {
			Render.icons(_dc, self.pos_x, self.pos_y, self.charge_, self.frame_);
		}
	}

	function refresh(_dc as Graphics.Dc) as Void {

		var borders_width = Render.iconsWidth(_dc, Font.ICON_BATTERY_BEGIN + Font.ICON_BATTERY_END);
		var bar_width = Render.iconsWidth(_dc, "" + Font.ICON_BATTERY_EMPTY);

		var bar_all_count = (self.size_x - borders_width) / bar_width;
		var bar_charged_count = (System.getSystemStats().battery / 100 * bar_all_count).toNumber();

		self.charge_ = "";
		self.frame_ = "";
		self.charging_ = "";

		self.frame_ += Font.ICON_BATTERY_BEGIN;
		self.charging_ += Font.ICON_BATTERY_BEGIN;

		for (var i = 0; i < bar_charged_count; ++i) {
			self.charge_ += Font.ICON_BATTERY_CHARGE;
			self.frame_ += Font.ICON_BATTERY_FRAME;
			self.charging_ += Font.ICON_BATTERY_CHARGING;
		}
		for (var i = bar_charged_count; i < bar_all_count; ++i) {
			self.charge_ += Font.ICON_BATTERY_EMPTY;
			self.frame_ += Font.ICON_BATTERY_FRAME;
			self.charging_ += Font.ICON_BATTERY_FRAME;
		}

		self.frame_ += Font.ICON_BATTERY_END;
		self.charging_ += Font.ICON_BATTERY_END;
	}
}

} // module Element
