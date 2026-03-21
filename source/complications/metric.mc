// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Complications;
import Toybox.Graphics;
import Toybox.Lang;

module Complication {

class Metric extends Base {
	hidden var spacing_ as Lang.Number = Render.SPACING;

	hidden var impl_ as Data.Base;
	hidden var count_ as Lang.Number;

	function initialize(_dc as Graphics.Dc, _impl as Data.Base, _count as Lang.Number) {
		Base.initialize(_impl.type);

		self.impl_ = _impl;
		self.count_ = _count;

		self.size_x = Render.numberWidth(_dc, self.count_) + 3 * self.spacing_;
		self.size_y = Render.numberHeight(_dc);
		if (self.impl_.name.length() != 0) {
			self.size_y += Render.labelHeight(_dc) + self.spacing_;
		}
	}

	function refresh(_dc as Graphics.Dc) as Void {
		self.impl_.refresh();
	}

	function render(_dc as Graphics.Dc) as Void {
		// ---- prepare ----

		if (self.impl_.value == null or self.impl_.value_max == null) {
			self.refresh(_dc);
		}

		var pos_x = self.pos_x;
		var pos_y = self.pos_y;

		// ---- label ----

		if (self.impl_.name.length() != 0) {
			Render.label(_dc, pos_x, pos_y, self.impl_.name, Graphics.TEXT_JUSTIFY_LEFT);
			pos_y += Render.labelHeight(_dc) + self.spacing_;
		}

		// ---- value ----

		Render.number(_dc, pos_x, pos_y, self.impl_.value, self.count_);
		pos_x += Render.numberWidth(_dc, self.count_);

		// ---- gauge ----

		if (self.impl_.value == null or self.impl_.value_max == null) {
			return;
		}

		var value = self.impl_.value as Lang.Number;
		var value_max = self.impl_.value_max as Lang.Number;

		if (value_max == 0) {
			return;
		}

		pos_x += self.spacing_ / 2;
		pos_y += self.spacing_;

		var gauge_max_height = Render.numberHeight(_dc) -2 * self.spacing_;

		Render.gauge(_dc, pos_x, pos_y, value.toFloat() / value_max, gauge_max_height, Render.GAUGE_BOTTOM);
	}
}

} // module Complication
