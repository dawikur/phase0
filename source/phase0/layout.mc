// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Graphics;
import Toybox.Lang;

module Phase0 {

class Layout {
	var screen_size_x as Lang.Number = 0;
	var screen_size_y as Lang.Number = 0;

	var clock as Box = new Box(0, 0, 0, 0, false);
	var inner as Box = new Box(0, 0, 0, 0, false);
	var middle as Box = new Box(0, 0, 0, 0, false);
	var outer as Box = new Box(0, 0, 0, 0, false);

	var left as Box = new Box(0, 0, 0, 0, false);

	function initialize(_dc as Graphics.Dc) {
		if (self.configure(_dc, false, false, false, false)) { return; }
		if (self.configure(_dc, true, false, false, false)) { return; }
		if (self.configure(_dc, true, false, false, true)) { return; }
		if (self.configure(_dc, true, true, false, true)) { return; }
		self.configure(_dc, true, true, true, true);
	}

	function bottomBox(_box as Box) as Box {
		return Box.PosSize(
			_box.pos_x,
			self.screen_size_y - _box.end_y + Render.SPACING,
			_box.size_x,
			_box.size_y,
			_box.small
		);
	}

	function rightBox(_box as Box) as Box {
		return Box.PosSize(
			self.screen_size_x - _box.end_x,
			_box.pos_y,
			_box.size_x,
			_box.size_y,
			_box.small
		);
	}

	hidden function configure(
		_dc as Graphics.Dc,
		_clock_small as Lang.Boolean,
		_inner_small as Lang.Boolean,
		_middle_small as Lang.Boolean,
		_outer_small as Lang.Boolean
	) as Lang.Boolean {
		self.screen_size_x = _dc.getWidth();
		self.screen_size_y = _dc.getHeight();

		var clock_font = _clock_small ? Fonts.DIGITS_SMALL : Fonts.DIGITS;
		var clock_size = _dc.getTextDimensions("00:00", clock_font);
		var clock_size_x = clock_size[0];
		var clock_size_y = clock_size[1];

		var line_inner_height =
			Render.textHeight(_dc, _inner_small);
		var line_middle_height = _middle_small ?
			Render.textHeight(_dc, false) :
			Render.labelHeight(_dc) + Render.SPACING + Render.textHeight(_dc, false);
		var line_outer_height = _outer_small ?
			Render.textHeight(_dc, true) :
			Render.labelHeight(_dc) + Render.SPACING + Render.textHeight(_dc, true);

		var side_size_x = Render.iconsWidth(_dc, " ");
		var gap_x = ((self.screen_size_x - clock_size_x) / 2 - side_size_x) / 2;
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

		self.outer = Box.ForY(
			self.screen_size_y, pos_y, line_outer_height, _outer_small
		);
		pos_y = self.outer.end_y + gap_y;

		self.middle = Box.ForY(
			self.screen_size_y, pos_y, line_middle_height, _middle_small
		);
		pos_y = self.middle.end_y + gap_y;

		self.inner = Box.ForY(
			self.screen_size_y, pos_y, line_inner_height, _inner_small
		);
		pos_y = self.inner.end_y + gap_y;

		self.clock = Box.PosSize(
			(self.screen_size_x - clock_size_x) / 2,
			pos_y,
			clock_size_x,
			clock_size_y,
			_clock_small
		);

		self.left = Box.PosSize(
			2 * gap_x,
			self.clock.pos_y + 2 * Fonts.SPACING_REGULAR,
			side_size_x,
			clock_size_y - 3 * Fonts.SPACING_REGULAR,
			false
		);

		return true;
	}
}

} // module Phase0
