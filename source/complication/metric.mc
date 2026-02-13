// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Complications;
import Toybox.Graphics;
import Toybox.Lang;

module Complication {

class Metric extends Base {
	hidden var spacing_ as Lang.Number = Render.SPACING;

	hidden var count_ as Lang.Number = 3;

	hidden var label_ as Lang.String = "";
	hidden var value_ as Lang.Number or Null = null;
	hidden var value_max_ as Lang.Number or Null = null;

	function initialize(_type as Complications.Type) {
		Base.initialize(_type);
	}

	function width(_dc as Graphics.Dc) as Lang.Number {
		return Render.numberWidth(_dc, self.count_) + 3 * self.spacing_;
	}

	function height(_dc as Graphics.Dc) as Lang.Number {
		if (self.label_.length() == 0) {
			return Render.numberHeight(_dc);
		}
		return Render.labelHeight(_dc) + self.spacing_ + Render.numberHeight(_dc);
	}

	function refresh(_dc as Graphics.Dc) as Void {
		self.value_ = self.getValue_();
		self.value_max_ = self.getValueMax_();
	}

	function render(_dc as Graphics.Dc) as Void {
		// ---- prepare ----

		if (self.value_ == null or self.value_max_ == null) {
			self.refresh(_dc);
		}

		var pos_x = self.pos_x;
		var pos_y = self.pos_y;

		// ---- label ----

		if (self.label_.length() != 0) {
			Render.label(_dc, pos_x, pos_y, self.label_, Graphics.TEXT_JUSTIFY_LEFT);
			pos_y += Render.labelHeight(_dc) + self.spacing_;
		}

		// ---- value ----

		Render.number(_dc, pos_x, pos_y, self.value_, self.count_);
		pos_x += Render.numberWidth(_dc, self.count_);

		// ---- gauge ----

		if (self.value_ == null or self.value_max_ == null) {
			return;
		}

		var value = self.value_ as Lang.Number;
		var value_max = self.value_max_ as Lang.Number;

		if (value_max == 0) {
			return;
		}

		pos_x += self.spacing_ / 2;
		pos_y += self.spacing_;

		var gauge_max_height = Render.numberHeight(_dc) -2 * self.spacing_;

		Render.gauge(_dc, pos_x, pos_y, value.toFloat() / value_max, gauge_max_height, Render.GAUGE_BOTTOM);
	}

	hidden function getValue_() as Lang.Number or Null {
		return null;
	}

	hidden function getValueMax_() as Lang.Number or Null {
		return null;
	}
}

typedef Metrics as Lang.Array<Metric>;

} // module Complication
