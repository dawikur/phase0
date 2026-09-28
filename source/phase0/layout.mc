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
		var bottom_inner as Box = new Box(0, 0, 0, 0);
		var bottom_middle as Box = new Box(0, 0, 0, 0);
		var bottom_outer as Box = new Box(0, 0, 0, 0);

		var left as Box = new Box(0, 0, 0, 0);
		var right as Box = new Box(0, 0, 0, 0);
		var show_left as Lang.Boolean = false;
		var show_right as Lang.Boolean = false;

		hidden var show_top_outer_ as Lang.Boolean = false;
		hidden var show_top_middle_ as Lang.Boolean = false;
		hidden var show_top_inner_ as Lang.Boolean = false;
		hidden var show_bottom_inner_ as Lang.Boolean = false;
		hidden var show_bottom_middle_ as Lang.Boolean = false;
		hidden var show_bottom_outer_ as Lang.Boolean = false;

		function initialize(
			_dc as Graphics.Dc,
			_show_top_outer as Lang.Boolean,
			_show_top_middle as Lang.Boolean,
			_show_top_inner as Lang.Boolean,
			_show_bottom_inner as Lang.Boolean,
			_show_bottom_middle as Lang.Boolean,
			_show_bottom_outer as Lang.Boolean
		) {
			self.screen_size_x = _dc.getWidth();
			self.screen_size_y = _dc.getHeight();

			self.show_top_outer_ = _show_top_outer;
			self.show_top_middle_ = _show_top_middle;
			self.show_top_inner_ = _show_top_inner;
			self.show_bottom_inner_ = _show_bottom_inner;
			self.show_bottom_middle_ = _show_bottom_middle;
			self.show_bottom_outer_ = _show_bottom_outer;

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

		hidden function tryApplyCandidate_(
			_dc as Graphics.Dc,
			_clock_is_small as Lang.Boolean,
			_inner_is_small as Lang.Boolean,
			_middle_is_small as Lang.Boolean,
			_outer_is_small as Lang.Boolean,
			_show_left as Lang.Boolean,
			_show_right as Lang.Boolean
		) as Lang.Boolean {
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

			var clock_pos_y = (self.screen_size_y - clock_size_y) / 2;
			var top_content_height =
				(self.show_top_inner_ ? line_inner_height : 0) +
				(self.show_top_middle_ ? line_middle_height : 0) +
				(self.show_top_outer_ ? line_outer_height : 0);
			var bottom_content_height =
				(self.show_bottom_inner_ ? line_inner_height : 0) +
				(self.show_bottom_middle_ ? line_middle_height : 0) +
				(self.show_bottom_outer_ ? line_outer_height : 0);
			var top_line_count =
				(self.show_top_middle_ ? 1 : 0) +
				(self.show_top_outer_ ? 1 : 0);
			var bottom_line_count =
				(self.show_bottom_middle_ ? 1 : 0) +
				(self.show_bottom_outer_ ? 1 : 0);
			var top_available_y = clock_pos_y;
			var bottom_available_y =
				self.screen_size_y - clock_pos_y - clock_size_y;
			// Anchor inner as though all three lines were present.
			var top_inner_gap_y = self.show_top_inner_
				? (top_available_y -
						line_inner_height -
						line_middle_height -
						line_outer_height) /
					4
				: 0;
			var bottom_inner_gap_y = self.show_bottom_inner_
				? (bottom_available_y -
						line_inner_height -
						line_middle_height -
						line_outer_height) /
					4
				: 0;
			var top_gap_y =
				(top_available_y - top_content_height - top_inner_gap_y) /
				(top_line_count + 1);
			var bottom_gap_y =
				(bottom_available_y -
					bottom_content_height -
					bottom_inner_gap_y) /
				(bottom_line_count + 1);

			if (
				gap_x < 1 or
				top_gap_y < 1 or
				bottom_gap_y < 1 or
				(self.show_top_inner_ and top_inner_gap_y < 1) or
				(self.show_bottom_inner_ and bottom_inner_gap_y < 1)
			) {
				return false;
			}

			self.show_left = _show_left;
			self.show_right = _show_right;

			var pos_y = top_gap_y;
			self.top_outer = new Box(0, 0, 0, 0);
			self.top_middle = new Box(0, 0, 0, 0);
			self.top_inner = new Box(0, 0, 0, 0);
			if (self.show_top_outer_) {
				self.top_outer = Box.ForY(
					self.screen_size_y,
					pos_y,
					line_outer_height
				);
				pos_y = self.top_outer.end_y + top_gap_y;
			}
			if (self.show_top_middle_) {
				self.top_middle = Box.ForY(
					self.screen_size_y,
					pos_y,
					line_middle_height
				);
				pos_y = self.top_middle.end_y + top_gap_y;
			}
			if (self.show_top_inner_) {
				self.top_inner = Box.ForY(
					self.screen_size_y,
					clock_pos_y - top_inner_gap_y - line_inner_height,
					line_inner_height
				);
			}

			self.clock = new Box(
				(self.screen_size_x - clock_size_x) / 2,
				clock_pos_y,
				clock_size_x,
				clock_size_y
			);

			self.left = new Box(
				2 * gap_x,
				self.clock.pos_y,
				side_size_x,
				clock_size_y
			);

			self.right = new Box(
				self.screen_size_x - 2 * gap_x - side_size_raw_x,
				self.clock.pos_y + Render.SPACING,
				side_size_raw_x,
				side_size_raw_y - Render.SPACING
			);

			var bottom_pos_y = self.screen_size_y - bottom_gap_y;
			self.bottom_inner = new Box(0, 0, 0, 0);
			self.bottom_middle = new Box(0, 0, 0, 0);
			self.bottom_outer = new Box(0, 0, 0, 0);
			if (self.show_bottom_outer_) {
				self.bottom_outer = Box.ForY(
					self.screen_size_y,
					bottom_pos_y,
					-line_outer_height
				);
				bottom_pos_y = self.bottom_outer.pos_y - bottom_gap_y;
			}
			if (self.show_bottom_middle_) {
				self.bottom_middle = Box.ForY(
					self.screen_size_y,
					bottom_pos_y,
					-line_middle_height
				);
				bottom_pos_y = self.bottom_middle.pos_y - bottom_gap_y;
			}
			if (self.show_bottom_inner_) {
				self.bottom_inner = Box.ForY(
					self.screen_size_y,
					clock_pos_y +
						clock_size_y +
						bottom_inner_gap_y +
						line_inner_height,
					-line_inner_height
				);
			}

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
			self.right = new Box(0, 0, 0, 0);
			self.show_left = false;
			self.show_right = false;

			self.top_outer = new Box(0, 0, 0, 0);
			self.top_middle = new Box(0, 0, 0, 0);
			self.top_inner = new Box(0, 0, 0, 0);
			self.bottom_inner = new Box(0, 0, 0, 0);
			self.bottom_middle = new Box(0, 0, 0, 0);
			self.bottom_outer = new Box(0, 0, 0, 0);
		}
	}
} // module Phase0
