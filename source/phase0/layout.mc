// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

module Phase0 {
	class Layout {
		var screen_size_x as Lang.Number = 0;
		var screen_size_y as Lang.Number = 0;

		var clock as Box = new Box(0, 0, 0, 0);
		var inner as Box = new Box(0, 0, 0, 0);
		var middle as Box = new Box(0, 0, 0, 0);
		var outer as Box = new Box(0, 0, 0, 0);

		var left as Box = new Box(0, 0, 0, 0);

		function initialize(_dc as Graphics.Dc) {
			if (
				self.applyCandidate_(
					_dc,
					Render.SIZE_REGULAR,
					Render.SIZE_REGULAR,
					Render.SIZE_REGULAR,
					Render.SIZE_REGULAR
				) ||
				self.applyCandidate_(
					_dc,
					Render.SIZE_SMALL,
					Render.SIZE_REGULAR,
					Render.SIZE_REGULAR,
					Render.SIZE_REGULAR
				) ||
				self.applyCandidate_(
					_dc,
					Render.SIZE_SMALL,
					Render.SIZE_REGULAR,
					Render.SIZE_REGULAR,
					Render.SIZE_SMALL
				) ||
				self.applyCandidate_(
					_dc,
					Render.SIZE_SMALL,
					Render.SIZE_REGULAR,
					Render.SIZE_SMALL,
					Render.SIZE_SMALL
				) ||
				self.applyCandidate_(
					_dc,
					Render.SIZE_SMALL,
					Render.SIZE_SMALL,
					Render.SIZE_REGULAR,
					Render.SIZE_SMALL
				) ||
				self.applyCandidate_(
					_dc,
					Render.SIZE_SMALL,
					Render.SIZE_SMALL,
					Render.SIZE_SMALL,
					Render.SIZE_SMALL
				)
			) {
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

		hidden function applyCandidate_(
			_dc as Graphics.Dc,
			_clock_is_small as Lang.Boolean,
			_inner_is_small as Lang.Boolean,
			_middle_is_small as Lang.Boolean,
			_outer_is_small as Lang.Boolean
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
				? Render.TextHeight(_dc, Render.SIZE_REGULAR)
				: Render.LabelHeight(_dc) +
					Render.SPACING +
					Render.TextHeight(_dc, Render.SIZE_REGULAR);
			var line_outer_height = _outer_is_small
				? Render.TextHeight(_dc, Render.SIZE_SMALL)
				: Render.LabelHeight(_dc) +
					Render.SPACING +
					Render.TextHeight(_dc, Render.SIZE_SMALL);

			var side_size_x = Render.IconsWidth(_dc, " ");
			var gap_x =
				((self.screen_size_x - clock_size_x) / 2 - side_size_x) / 2;
			if (gap_x < 1) {
				return false;
			}

			var content_height =
				clock_size_y +
				2 * line_inner_height +
				2 * line_middle_height +
				2 * line_outer_height;
			var gap_y = (self.screen_size_y - content_height) / 8;
			if (gap_y <= 1) {
				return false;
			}

			var pos_y = gap_y;

			self.outer = Box.ForY(self.screen_size_y, pos_y, line_outer_height);
			pos_y = self.outer.end_y + gap_y;

			self.middle = Box.ForY(
				self.screen_size_y,
				pos_y,
				line_middle_height
			);
			pos_y = self.middle.end_y + gap_y;

			self.inner = Box.ForY(self.screen_size_y, pos_y, line_inner_height);
			pos_y = self.inner.end_y + gap_y;

			self.clock = new Box(
				(self.screen_size_x - clock_size_x) / 2,
				pos_y,
				clock_size_x,
				clock_size_y
			);

			self.left = new Box(
				2 * gap_x,
				self.clock.pos_y + 2 * Fonts.SPACING_REGULAR,
				side_size_x,
				clock_size_y - 3 * Fonts.SPACING_REGULAR
			);

			return true;
		}
	}
} // module Phase0
