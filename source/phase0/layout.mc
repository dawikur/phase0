// Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

module Phase0 {
	class Layout {
		var screen_size_x as Lang.Number = 0;
		var screen_size_y as Lang.Number = 0;

		var clock as Box = new Box(0, 0, 0, 0);

		var top_outer as Box = new Box(0, 0, 0, 0);
		var top_middle as Box = new Box(0, 0, 0, 0);
		var top_inner as Box = new Box(0, 0, 0, 0);

		var left as Box = new Box(0, 0, 0, 0);
		var left_raw as Box = new Box(0, 0, 0, 0);

		function initialize(_dc as Graphics.Dc) {
			if (
				self.tryApplyCandidate_(
					_dc,
					Render.SIZE_REGULAR,
					Render.SIZE_REGULAR,
					Render.SIZE_REGULAR,
					Render.SIZE_REGULAR,
					true,
					true
				) or
				self.tryApplyCandidate_(
					_dc,
					Render.SIZE_SMALL,
					Render.SIZE_REGULAR,
					Render.SIZE_REGULAR,
					Render.SIZE_REGULAR,
					true,
					true
				) or
				self.tryApplyCandidate_(
					_dc,
					Render.SIZE_SMALL,
					Render.SIZE_REGULAR,
					Render.SIZE_SMALL,
					Render.SIZE_SMALL,
					true,
					true
				) or
				self.tryApplyCandidate_(
					_dc,
					Render.SIZE_SMALL,
					Render.SIZE_REGULAR,
					Render.SIZE_REGULAR,
					Render.SIZE_SMALL,
					true,
					true
				) or
				self.tryApplyCandidate_(
					_dc,
					Render.SIZE_SMALL,
					Render.SIZE_SMALL,
					Render.SIZE_REGULAR,
					Render.SIZE_SMALL,
					true,
					true
				) or
				self.tryApplyCandidate_(
					_dc,
					Render.SIZE_SMALL,
					Render.SIZE_SMALL,
					Render.SIZE_SMALL,
					Render.SIZE_SMALL,
					true,
					true
				) or
				// Keep the left side before the right side when only one can fit.
				self.tryApplyCandidate_(
					_dc,
					Render.SIZE_SMALL,
					Render.SIZE_SMALL,
					Render.SIZE_SMALL,
					Render.SIZE_SMALL,
					true,
					false
				) or
				// FR255S is too narrow for the clock and both side areas.
				self.tryApplyCandidate_(
					_dc,
					Render.SIZE_SMALL,
					Render.SIZE_SMALL,
					Render.SIZE_SMALL,
					Render.SIZE_SMALL,
					false,
					false
				)
			) {
			} else {
				self.applyFallback_(_dc);
			}
		}

		function bottomBox(_box as Box) as Box {
			return new Box(
				_box.pos_x,
				self.screen_size_y - _box.end_y,
				_box.size_x,
				_box.size_y
			);
		}

		function rightBox(_box as Box) as Box {
			return new Box(
				self.screen_size_x - _box.end_x,
				_box.pos_y,
				_box.size_x,
				_box.size_y
			);
		}

		hidden function tryApplyCandidate_(
			_dc as Graphics.Dc,
			_clock_is_small as Lang.Boolean,
			_inner_is_small as Lang.Boolean,
			_middle_is_small as Lang.Boolean,
			_outer_is_small as Lang.Boolean,
			_show_left as Lang.Boolean,
			_show_right as Lang.Boolean
		) as Lang.Boolean {
			self.screen_size_x = _dc.getWidth();
			self.screen_size_y = _dc.getHeight();

			var clock_font =
				Application.loadResource(
					_clock_is_small
						? Rez.Fonts.DIGITS_SMALL
						: Rez.Fonts.DIGITS_REGULAR
				) as WatchUi.FontResource;

			var clock_size_x = Render.ClockWidth(_dc, "00:00", clock_font);
			var clock_size_y = Render.ClockHeight(_dc, clock_font);

			var line_inner_height = Render.TextHeight(_dc, _inner_is_small);
			var line_middle_height = _middle_is_small
				? Render.TextHeight(_dc, Render.SIZE_SMALL)
				: Render.LabelHeight(_dc) +
					Render.SPACING +
					Render.TextHeight(_dc, Render.SIZE_REGULAR);
			var line_outer_height = _outer_is_small
				? Render.TextHeight(_dc, Render.SIZE_SMALL)
				: Render.LabelHeight(_dc) +
					Render.SPACING +
					Render.TextHeight(_dc, Render.SIZE_SMALL);

			var side_size_x = 0;
			var side_size_raw_x = 0;
			var side_size_raw_y = _dc.getFontHeight(clock_font);

			if (_show_left) {
				side_size_x = Render.IconsWidth(_dc, " ");
			}
			if (_show_right) {
				side_size_raw_x = Render.IconsRawWidth(_dc, " ");
			}

			var gap_x = 0;
			if (_show_left) {
				gap_x =
					((self.screen_size_x - clock_size_x) / 2 - side_size_x) / 2;
			} else {
				gap_x = (self.screen_size_x - clock_size_x) / 4;
			}

			var content_height =
				clock_size_y +
				2 * line_inner_height +
				2 * line_middle_height +
				2 * line_outer_height;
			var gap_y = (self.screen_size_y - content_height) / 8;

			if (gap_x < 1 or gap_y < 1) {
				return false;
			}

			var pos_y = gap_y;
			var layout_end_y =
				pos_y +
				line_outer_height +
				gap_y +
				line_middle_height +
				gap_y +
				line_inner_height +
				gap_y +
				clock_size_y;
			if (pos_y < 0 or self.screen_size_y < layout_end_y) {
				return false;
			}

			self.top_outer = Box.ForY(
				self.screen_size_y,
				pos_y,
				line_outer_height
			);
			pos_y = self.top_outer.end_y + gap_y;

			self.top_middle = Box.ForY(
				self.screen_size_y,
				pos_y,
				line_middle_height
			);
			pos_y = self.top_middle.end_y + gap_y;

			self.top_inner = Box.ForY(
				self.screen_size_y,
				pos_y,
				line_inner_height
			);
			pos_y = self.top_inner.end_y + gap_y;

			self.clock = new Box(
				(self.screen_size_x - clock_size_x) / 2,
				pos_y,
				clock_size_x,
				clock_size_y
			);

			self.left = new Box(
				2 * gap_x,
				self.clock.pos_y,
				side_size_x,
				clock_size_y
			);

			self.left_raw = new Box(
				2 * gap_x,
				self.clock.pos_y + Render.SPACING,
				side_size_raw_x,
				side_size_raw_y - Render.SPACING
			);

			return true;
		}

		hidden function applyFallback_(_dc as Graphics.Dc) as Void {
			self.screen_size_x = _dc.getWidth();
			self.screen_size_y = _dc.getHeight();

			var clock_font =
				Application.loadResource(Rez.Fonts.DIGITS_SMALL) as
				WatchUi.FontResource;
			var clock_size_x = Render.ClockWidth(_dc, "00:00", clock_font);
			var clock_size_y = Render.ClockHeight(_dc, clock_font);

			self.clock = new Box(
				(self.screen_size_x - clock_size_x) / 2,
				(self.screen_size_y - clock_size_y) / 2,
				clock_size_x,
				clock_size_y
			);
			self.left = new Box(0, 0, 0, 0);
			self.left_raw = new Box(0, 0, 0, 0);

			self.top_outer = new Box(0, 0, 0, 0);
			self.top_middle = new Box(0, 0, 0, 0);
			self.top_inner = new Box(0, 0, 0, 0);
		}
	}
} // module Phase0
