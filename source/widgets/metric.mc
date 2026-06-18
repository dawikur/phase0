// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Complications;
import Toybox.Graphics;
import Toybox.Lang;

module Widgets {

class Metric extends Base {
	hidden var impl_ as Data.Base;
	hidden var count_ as Lang.Number;
	hidden var small_ as Lang.Boolean;

	function initialize(
		_dc as Graphics.Dc,
		_impl as Data.Base,
		_count as Lang.Number,
		_small as Lang.Boolean
	) {
		Base.initialize(_impl.type);

		self.impl_ = _impl;
		self.count_ = _count;
		self.small_ = _small;

		self.resize(_dc);
	}

	function resize(_dc as Graphics.Dc) as Void {
		self.size_x = Render.numberWidth(_dc, self.count_, self.small_) + 3 * Render.SPACING;
		self.size_y = Render.numberHeight(_dc, self.small_);

		if (self.impl_.name.length() != 0) {
			self.size_y += Render.labelHeight(_dc) + Render.SPACING;
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
			pos_y += Render.labelHeight(_dc) + Render.SPACING;
		}

		// ---- value ----

		Render.number(_dc, pos_x, pos_y, self.impl_.value, self.count_, self.small_);
		pos_x += Render.numberWidth(_dc, self.count_, self.small_);

		// ---- gauge ----

		if (self.impl_.value == null or self.impl_.value_max == null) {
			return;
		}

		var value = self.impl_.value as Lang.Number;
		var value_max = self.impl_.value_max as Lang.Number;

		if (value_max == 0) {
			return;
		}

		pos_x += Render.SPACING / 2;
		pos_y += Render.SPACING;

		var gauge_max_height = Render.numberHeight(_dc, self.small_) - 2 * Render.SPACING;

		Render.gauge(_dc, pos_x, pos_y, value.toFloat() / value_max, gauge_max_height, Render.GAUGE_BOTTOM);
	}
}

} // module Widgets
