// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;

module Widgets {
	class Gauge extends Base {
		hidden var impl_ as Data.Base;

		hidden var value_ as Lang.Float? = null;

		var properties as Properties.Gauge;

		function initialize(
			_properties as Properties.Gauge,
			_impl as Data.Base
		) {
			Base.initialize(_impl.type);

			self.impl_ = _impl;
			self.properties = _properties;

			self.size_x = Render.SPACING;
		}

		function resize(
			_dc as Graphics.Dc,
			_size_x as Lang.Number,
			_size_y as Lang.Number
		) as Void {
			self.size_x = Render.SPACING;
			self.size_y = _size_y;
		}

		function refresh(_dc as Graphics.Dc) as Void {
			self.impl_.refresh();

			self.value_ = Render.Ratio(self.impl_.value, self.impl_.value_max);
		}

		function render(_dc as Graphics.Dc) as Void {
			if (self.value_ != null) {
				Render.Gauge(
					_dc,
					self.properties.accent,
					self.pos_x,
					self.pos_y,
					self.size_y,
					self.value_
				);
			}
		}
	}
} // module Widgets
