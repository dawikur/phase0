// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

module Value {

class Base {
	var pos_x as Lang.Number = 0;
	var pos_y as Lang.Number = 0;

	hidden var small_ as Lang.Boolean;

	hidden var spacing_ as Lang.Number = 0;

	hidden var count_ as Lang.Number = 3;

	hidden var header_ as Lang.String or Null = null;

	hidden var max_value_ as Lang.Number or Null = null;

	function initialize(_small as Lang.Boolean) {
		self.small_ = _small;

		if (_small) {
			self.spacing_ = Font.SPACING_TINY;
		} else {
			self.spacing_ = Font.SPACING_SMALL;
		}
	}

	function width(_dc as Graphics.Dc) as Lang.Number {
		if (self.small_) {
			return Render.numberSmallWidth(_dc, self.count_) + 3 * self.spacing_;
		} else {
			return Render.numberWidth(_dc, self.count_) + 3 * self.spacing_;
		}
	}

	function height(_dc as Graphics.Dc) as Lang.Number {
		var label_height = 0;
		if (self.header_ != null) {
			label_height = Render.labelHeight(_dc);
		}

		if (self.small_) {
			return Render.numberSmallHeight(_dc) + label_height;
		} else {
			return Render.numberHeight(_dc) + label_height;
		}
	}

	function render(_dc as Graphics.Dc) as Void {
		var pos_x = self.pos_x;
		var pos_y = self.pos_y;

		// ---- header ----

		if (self.header_ != null) {
			Render.label(_dc, pos_x, pos_y, self.header_, Graphics.TEXT_JUSTIFY_LEFT);
			pos_y += Render.labelHeight(_dc) + self.spacing_;
		}

		// ---- value ----

		var value = self.getValue_();

		if (self.small_) {
			Render.numberSmall(_dc, pos_x, pos_y, value, self.count_);
			pos_x += Render.numberSmallWidth(_dc, self.count_);
		} else {
			Render.number(_dc, pos_x, pos_y, value, self.count_);
			pos_x += Render.numberWidth(_dc, self.count_);
		}

		// ---- gauge ----

		if (value == null) {
			return;
		}

		if (self.max_value_ == null) {
			return;
		}
		var max_value = self.max_value_ as Lang.Number;

		pos_x += self.spacing_ / 2;
		pos_y += self.spacing_;

		var gauge_max_height = -2 * self.spacing_;
		if (self.small_) {
			gauge_max_height += Render.numberSmallHeight(_dc);
			Render.gaugeSmall(_dc, pos_x, pos_y, value.toFloat() / max_value, gauge_max_height, Render.GAUGE_BOTTOM);
		} else {
			gauge_max_height += Render.numberHeight(_dc);
			Render.gauge(_dc, pos_x, pos_y, value.toFloat() / max_value, gauge_max_height, Render.GAUGE_BOTTOM);
		}
	}

	function getValue_() as Lang.Number or Null {
		return null;
	}

	function refresh(_dc as Graphics.Dc) as Void {
	}
}

} // module Value
