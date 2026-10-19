// Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

import Toybox.Graphics;
import Toybox.Lang;

module Widgets {
	// A layout spacer with no data refreshes or drawing operations.
	class Empty extends Base {
		function initialize() {
			Base.initialize(null, Data.RefreshRate.NONE);
		}

		function isEmpty() as Lang.Boolean {
			return false;
		}

		function resize(
			_dc as Graphics.Dc,
			_size_x as Lang.Number,
			_size_y as Lang.Number
		) as Void {
			self.size_x = Render.NumberWidth(_dc, 3, self.is_small);
			self.size_y = 0;
		}

		function clear(_dc as Graphics.Dc) as Void {}
	}
} // module Widgets
