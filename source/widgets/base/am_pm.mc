// Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

import Toybox.Complications;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;

module Widgets {
	class AmPm extends Base {
		static const MODE_FULL = 0;
		static const MODE_TEXT = 1;
		static const MODE_ICON = 2;
		static const MODE_HIDDEN = 3;

		hidden var frame_ as Lang.String = "";
		hidden var label_ as Lang.String = "";
		hidden var fallback_ as Lang.String? = null;
		hidden var mode_ as Lang.Number = MODE_FULL;
		hidden var base_mode_ as Lang.Number = MODE_FULL;
		hidden var frame_min_width_ as Lang.Number = 0;
		hidden var fallback_width_ as Lang.Number = 0;

		function initialize() {
			Base.initialize(null, Data.RefreshRate.HOUR);
		}

		function resize(
			_dc as Graphics.Dc,
			_size_x as Lang.Number,
			_size_y as Lang.Number
		) as Void {
			Base.resize(_dc, _size_x, _size_y);
			self.is_dirty_ = true;
			self.mode_ = MODE_FULL;
			if (_size_x <= 0 or _size_y <= 0) {
				self.mode_ = MODE_HIDDEN;
				self.frame_ = "";
				return;
			}

			var icon_height = Render.IconsHeight(_dc);
			var text_height = Render.TextHeight(_dc, Render.SIZE_SMALL);
			var frame_border_width = Render.IconsRawWidth(
				_dc,
				Fonts.ICON_AM_PM_BEGIN + Fonts.ICON_AM_PM_END
			);
			var bar_width = Render.IconsRawWidth(_dc, Fonts.ICON_AM_PM_FRAME);
			self.fallback_width_ = Render.IconsWidth(_dc, Fonts.ICON_DAWN);
			var bar_all_count = Render.BarCount(
				self.size_x - Render.SHADOW_OFFSET,
				frame_border_width,
				bar_width
			);

			if (_size_y < icon_height) {
				self.mode_ = MODE_TEXT;
			}
			if (_size_y < text_height) {
				self.mode_ = _size_y < icon_height ? MODE_HIDDEN : MODE_ICON;
			}
			self.base_mode_ = self.mode_;
			self.frame_ =
				Fonts.ICON_AM_PM_BEGIN +
				Render.Repeat(Fonts.ICON_AM_PM_FRAME, bar_all_count) +
				Fonts.ICON_AM_PM_END;
			self.frame_min_width_ = frame_border_width + 2 * Render.SPACING;
		}

		function refresh(_dc as Graphics.Dc) as Void {
			var label = Data.Units.getAmPm(Runtime.clock.hour);
			var fallback = null;
			if (label.equals("am")) {
				fallback = Fonts.ICON_DAWN;
			} else if (label.equals("pm")) {
				fallback = Fonts.ICON_DUSK;
			}

			var label_width = Render.TextWidth(_dc, label, Render.SIZE_SMALL);

			var mode = self.base_mode_;
			if (
				self.size_x < label_width and
				self.fallback_width_ <= self.size_x and
				fallback != null
			) {
				mode = MODE_ICON;
			} else if (
				mode == MODE_FULL and
				self.size_x < self.frame_min_width_ + label_width
			) {
				mode = MODE_TEXT;
			}

			if (
				self.label_ != label or
				self.fallback_ != fallback or
				self.mode_ != mode
			) {
				self.is_dirty_ = true;
			}

			self.label_ = label;
			self.fallback_ = fallback;
			self.mode_ = mode;
		}

		function render(_dc as Graphics.Dc) as Void {
			if (self.mode_ == MODE_HIDDEN) {
				return;
			}

			var center_x = self.centerX();
			var center_y = self.centerY();

			if (self.mode_ == MODE_ICON and self.fallback_ != null) {
				Render.Icons(
					_dc,
					Render.foreground,
					center_x,
					center_y,
					self.fallback_,
					self.fallback_,
					Render.JUSTIFY_CENTER
				);
				return;
			}

			if (self.mode_ == MODE_FULL) {
				Render.Icons(
					_dc,
					Render.foreground,
					center_x,
					center_y,
					self.frame_,
					self.frame_,
					Render.JUSTIFY_CENTER
				);
			}

			Render.Text(
				_dc,
				Render.foreground,
				center_x,
				center_y - Render.SPACING,
				Render.SIZE_SMALL,
				self.label_,
				Render.JUSTIFY_CENTER
			);
		}
	}
} // module Widgets
