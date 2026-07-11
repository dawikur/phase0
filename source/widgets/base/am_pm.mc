// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Complications;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;

module Widgets {
	class AmPm extends Base {
		hidden var frame_ as Lang.String = "";
		hidden var label_ as Lang.String = "";
		hidden var fallback_ as Lang.String? = null;

		var is_small as Lang.Boolean = false;

		function initialize() {
			Base.initialize(Complications.COMPLICATION_TYPE_INVALID);
		}

		function refresh(_dc as Graphics.Dc) as Void {
			if (self.frame_.length() == 0) {
				var borders_width = Render.IconsWidth(
					_dc,
					Lang.format("$1$$2$", [
						Fonts.ICON_AM_PM_BEGIN,
						Fonts.ICON_AM_PM_END,
					])
				);
				var bar_width = Render.IconsWidth(_dc, Fonts.ICON_AM_PM_FRAME);
				var bar_all_count =
					(2 * self.size_x - borders_width) / bar_width;

				self.frame_ += Fonts.ICON_AM_PM_BEGIN;
				for (var i = 0; i < bar_all_count; ++i) {
					self.frame_ += Fonts.ICON_AM_PM_FRAME;
				}
				self.frame_ += Fonts.ICON_AM_PM_END;
			}

			var clock = System.getClockTime();

			self.label_ = Data.Units.getAmPm(clock.hour);
			if (self.label_ == "am") {
				self.fallback_ = Fonts.ICON_DAWN;
			} else if (self.label_ == "pm") {
				self.fallback_ = Fonts.ICON_DUSK;
			} else {
				self.fallback_ = null;
			}
		}

		function render(_dc as Graphics.Dc) as Void {
			var label_width = Render.TextWidth(_dc, self.label_, true);
			if (label_width <= 2 * self.size_x or self.fallback_ == null) {
				if (!self.is_small) {
					Render.Icons(
						_dc,
						Properties.general.foreground,
						self.pos_x,
						self.pos_y + Render.SPACING,
						self.frame_,
						self.frame_,
						Render.JUSTIFY_CENTER
					);
				}

				Render.Text(
					_dc,
					Properties.general.foreground,
					self.pos_x,
					self.pos_y - Render.SPACING,
					Render.SIZE_SMALL,
					self.label_,
					Render.JUSTIFY_CENTER
				);
			} else {
				Render.Icons(
					_dc,
					Properties.general.foreground,
					self.pos_x,
					self.pos_y,
					self.fallback_,
					self.fallback_,
					Render.JUSTIFY_CENTER
				);
			}
		}
	}
} // module Widgets
