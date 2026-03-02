// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;

module Complication {

class Gauge extends Base {
	hidden var impl_ as Data.Base;

	hidden var value_ as Lang.Float or Null = null;

	function initialize(_impl as Data.Base) {
		Base.initialize(_impl.type);

		self.impl_ = _impl;

		self.size_x = Render.SPACING;
	}

	function refresh(_dc as Graphics.Dc) as Void {
		self.value_ = self.getValue_();
	}

	function render(_dc as Graphics.Dc) as Void {
		if (self.value_ != null) {
			Render.gaugeColor(
				_dc,
				self.pos_x,
				self.pos_y,
				self.value_,
				self.size_y,
				Render.GAUGE_BOTTOM,
				self.impl_.category
			);
		}
	}

	function getValue_() as Lang.Float or Null {
		var value = self.impl_.get();
		if (value == null) {
			return null;
		}

		var value_max = self.impl_.getMax();
		if (value_max == null) {
			return null;
		}
		if (value_max == 0) {
			return null;
		}

		return value.toFloat() / value_max;
	}
}

} // module Complication
