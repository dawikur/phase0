// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Complications;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;

module Widgets {
	class Seconds extends Base {
		hidden var second_ as Lang.Number = -1;
		hidden var value_ as Lang.String = "";

		hidden var is_minimal_ as Lang.Boolean = false;
		hidden var digit_width_ as Lang.Number = -1;

		function initialize() {
			Base.initialize(null, RefreshRate.SEC);
		}

		function refresh(_dc as Graphics.Dc) as Void {
			self.second_ = Runtime.clock.sec;
			self.value_ = self.second_.format("%02d");
		}

		function resize(
			_dc as Graphics.Dc,
			_size_x as Lang.Number,
			_size_y as Lang.Number
		) as Void {
			Base.resize(_dc, _size_x, _size_y);
			self.second_ = -1;
			self.is_minimal_ = false;
			self.is_dirty_ = true;
			self.is_small = Render.SIZE_REGULAR;
			if (
				!Fits(
					Render.TextWidth(_dc, "00", self.is_small),
					Render.TextHeight(_dc, self.is_small),
					_size_x,
					_size_y
				)
			) {
				self.is_small = Render.SIZE_SMALL;
			}

			self.digit_width_ =
				Render.TextWidth(_dc, "0", self.is_small) -
				Render.SHADOW_OFFSET;
		}

		function render(_dc as Graphics.Dc) as Void {
			self.is_minimal_ = false;
			self.render_(_dc, self.pos_x, self.value_, Render.foreground);
		}

		function renderMinimal(_dc as Graphics.Dc) as Void {
			self.is_minimal_ = true;
			self.render_(_dc, self.pos_x, "00", Render.shade);
		}

		function update(_dc as Graphics.Dc) as Void {
			var previous_second = self.second_;
			var was_minimal = self.is_minimal_;

			self.refresh(_dc);

			if (was_minimal or previous_second < 0) {
				self.updateRange_(_dc, 0);
			} else if (previous_second / 10 != self.second_ / 10) {
				self.updateRange_(_dc, 0);
			} else if (previous_second != self.second_) {
				self.updateRange_(_dc, 1);
			}
		}

		function updateMinimal(_dc as Graphics.Dc) as Void {
			if (!self.is_minimal_) {
				self.clear(_dc);
				self.renderMinimal(_dc);
			}
		}

		function invalidate() as Void {
			self.second_ = -1;
			self.is_minimal_ = false;
			self.is_dirty_ = true;
		}

		hidden function render_(
			_dc as Graphics.Dc,
			_pos_x as Lang.Number,
			_value as Lang.String,
			_color as Lang.Number
		) as Void {
			Render.Text(
				_dc,
				_color,
				_pos_x,
				self.pos_y,
				self.is_small,
				_value,
				Render.JUSTIFY_LEFT
			);
		}

		hidden function updateRange_(
			_dc as Graphics.Dc,
			_start as Lang.Number
		) as Void {
			var pos_x = self.pos_x + _start * self.digit_width_;
			var width = (2 - _start) * self.digit_width_ + Render.SHADOW_OFFSET;

			_dc.setClip(pos_x, self.pos_y, width, self.size_y);
			_dc.setColor(Render.background, Render.background);
			_dc.clear();

			self.is_minimal_ = false;
			self.render_(
				_dc,
				pos_x,
				self.value_.substring(_start, null) as Lang.String,
				Render.foreground
			);
		}
	}
} // module Widgets
