// Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;

module Widgets {
	class Gauge extends Base {
		hidden var impl_ as Data.Base;

		hidden var value_ as Lang.Float? = null;
		hidden var refresh_revision_ as Lang.Number? = null;

		hidden var accent_ as Lang.Number;

		function initialize(
			_properties as Properties.Gauge,
			_impl as Data.Base
		) {
			Base.initialize(_impl.type, _impl.refresh_rate);

			self.impl_ = _impl;
			self.accent_ =
				_properties.accent == Properties.GLOBAL
					? Render.accent
					: _properties.accent;

			self.size_x = Render.SPACING;
		}

		function resize(
			_dc as Graphics.Dc,
			_size_x as Lang.Number,
			_size_y as Lang.Number
		) as Void {
			self.size_x = Render.SPACING;
			self.size_y = _size_y;
			self.is_dirty_ = true;
		}

		function refresh(_dc as Graphics.Dc) as Void {
			self.impl_.refresh();
			self.refresh_revision_ = self.impl_.refreshRevision();

			var value = Render.Ratio(self.impl_.value, self.impl_.value_max);
			if (self.value_ != value) {
				self.value_ = value;
				self.is_dirty_ = true;
			}
		}

		function needsRefresh() as Lang.Boolean {
			var revision = self.impl_.refreshRevision();
			return revision != null and self.refresh_revision_ != revision;
		}

		function render(_dc as Graphics.Dc) as Void {
			if (self.value_ != null and 0 < self.size_y) {
				Render.Gauge(
					_dc,
					self.accent_,
					self.pos_x,
					self.pos_y,
					self.size_y,
					self.value_
				);
			}
		}
	}
} // module Widgets
