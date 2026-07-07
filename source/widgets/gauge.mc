// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;

module Widgets {
	class Gauge extends Base {
		hidden var impl_ as Data.Base;

		hidden var value_ as Lang.Float? = null;

		function initialize(_impl as Data.Base, _size_y as Lang.Number) {
			Base.initialize(_impl.type);

			self.impl_ = _impl;

			self.size_x = Render.SPACING;
			self.size_y = _size_y;
		}

		function refresh() as Void {
			self.impl_.refresh();

			if (
				self.impl_.value == null or
				self.impl_.value_max == null or
				self.impl_.value_max == 0
			) {
				self.value_ = null;
				return;
			}

			var value = self.impl_.value as Lang.Number;
			var value_max = self.impl_.value_max as Lang.Number;

			self.value_ = value.toFloat() / value_max;
		}

		function render(_dc as Graphics.Dc) as Void {
			if (self.value_ != null) {
				Render.GaugeColor(
					_dc,
					self.impl_.category,
					self.pos_x,
					self.pos_y,
					self.size_y,
					self.value_
				);
			}
		}
	}
} // module Widgets
