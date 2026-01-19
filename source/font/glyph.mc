// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Graphics;
import Toybox.Lang;

module Font {

class Glyph {
	var width as Lang.Number;
	var advance_ as Lang.Number;

	var data_ as Lang.Array<Lang.Number>;

	function initialize(_data as Lang.Array<Lang.Number>, _width as Lang.Number) {
		self.width = _width;
		self.advance_ = _width + 1;
		self.data_ = _data;
	}

	function render(_dc as Graphics.Dc, _pos_x as Lang.Number, _pos_y as Lang.Number, _style as Style) as Void {
		var data = self.data_;
		var size = _style.size;
		var weight = _style.weight;
		var width = self.width;
		var data_size = data.size();

		for (var j = 0; j < data_size; ++j) {
			var row = data[j];

			if (row != 0) {
				var x = _pos_x;
				for (var i = 0; i < width; ++i) {
					if ((row & 1) != 0) {
						_dc.fillRectangle(
							x, _pos_y,
							weight, weight
						);
					}

					row >>= 1;

					x += size;
				}
			}

			_pos_y += size;
		}
	}
}

} // module Font
