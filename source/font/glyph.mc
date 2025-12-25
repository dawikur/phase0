// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Graphics;
import Toybox.Lang;

module Font {

class Glyph {
	var width as Lang.Number;

	var data_ as Lang.Array<Lang.Number>;

	function initialize(_data as Lang.Array<Lang.Number>, _width as Lang.Number) {
		self.width = _width;
		self.data_ = _data;
	}

	function render(_dc as Graphics.Dc, _pos_x as Lang.Number, _pos_y as Lang.Number, _style as Style) as Void {
		var dy = 0;
		for (var j = 0; j < self.data_.size(); ++j) {
			var row = self.data_[j];

			var dx = 0;
			for (var i = 0; i < self.width; ++i) {
				if ((row & 1) == 1) {
					_dc.fillRectangle(
						_pos_x + dx, _pos_y + dy,
						_style.weight, _style.weight
					);
				}

				row >>= 1;

				dx += _style.size;
			}

			dy += _style.size;
		}
	}
}

} // module Font
