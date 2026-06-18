// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;

module Widgets {

class Battery extends Base {
	var impl_ as Data.Battery = new Data.Battery();

	var color_ as Lang.Number = Render.COLOR_WHITE;

	var charge_ as Lang.String = "";
	var frame_ as Lang.String = "";

	function initialize(_small as Lang.Boolean) {
		Base.initialize(impl_.type);
	}

	function refresh(_dc as Graphics.Dc) as Void {
		self.impl_.refresh();

		var value = self.impl_.value as Lang.Number;
		var value_max = self.impl_.value_max as Lang.Number;

		if (value < 10) {
			self.color_ = Render.COLOR_RED;
		} else if (value < 20) {
			self.color_ = Render.COLOR_YELLOW;
		} else {
			self.color_ = Render.COLOR_WHITE;
		}

		var borders_width = Render.iconsWidth(
			_dc, Fonts.ICON_BATTERY_BEGIN + Fonts.ICON_BATTERY_END
		);
		var bar_width = Render.iconsWidth(_dc, Fonts.ICON_BATTERY_EMPTY);

		var bar_all_count = (self.size_x - borders_width) / bar_width;
		var bar_charged_count =
			Math.round(value.toFloat() / value_max * bar_all_count).toNumber();

		self.charge_ = "";

		if (self.frame_.length() == 0) {
			self.frame_ += Fonts.ICON_BATTERY_BEGIN;
			for (var i = 0; i < bar_all_count; ++i) {
				self.frame_ += Fonts.ICON_BATTERY_FRAME;
			}
			self.frame_ += Fonts.ICON_BATTERY_END;
		}

		for (var i = 0; i < bar_charged_count; ++i) {
			self.charge_ += Fonts.ICON_BATTERY_CHARGE;
		}
		for (var i = bar_charged_count; i < bar_all_count; ++i) {
			self.charge_ += Fonts.ICON_BATTERY_EMPTY;
		}
	}

	function render(_dc as Graphics.Dc) as Void {
		var pos_x = self.pos_x + self.size_x / 2;
		var pos_y = self.pos_y + self.size_y / 2;

		Render.iconsColor(_dc, pos_x, pos_y, self.charge_, self.color_);

		if (System.getSystemStats().charging) {
			Render.iconsColor(_dc, pos_x, pos_y, self.frame_, Render.COLOR_WHITE);
		} else {
			Render.iconsColor(_dc, pos_x, pos_y, self.frame_, Render.COLOR_DARK_GRAY);
		}
	}
}

} // module Widgets
