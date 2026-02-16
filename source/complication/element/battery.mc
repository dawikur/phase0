// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;

module Complication {

class Battery extends Base {
	var charge_ as Lang.String = "";
	var frame_ as Lang.String = "";
	var charging_ as Lang.String = "";

	function initialize() {
		Base.initialize(Complications.COMPLICATION_TYPE_BATTERY);
	}

	function refresh(_dc as Graphics.Dc) as Void {
		var borders_width = Render.iconsWidth(_dc, Font.ICON_BATTERY_BEGIN + Font.ICON_BATTERY_END);
		var bar_width = Render.iconsWidth(_dc, "" + Font.ICON_BATTERY_EMPTY);

		var bar_all_count = (self.size_x - borders_width) / bar_width;
		var bar_charged_count = Math.round(System.getSystemStats().battery / 100 * bar_all_count).toNumber();

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

	function render(_dc as Graphics.Dc) as Void {
		var pos_x = self.pos_x + self.size_x / 2;
		var pos_y = self.pos_y + self.size_y / 2;

		if (System.getSystemStats().charging) {
			Render.icons(_dc, pos_x, pos_y, self.charging_, "");
		} else {
			Render.icons(_dc, pos_x, pos_y, self.charge_, "");
			Render.icons(_dc, pos_x, pos_y, "", self.frame_);
		}
	}
}

} // module Element
