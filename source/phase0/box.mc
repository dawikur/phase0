// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Lang;
import Toybox.Math;

module Phase0 {
	class Box {
		var size_x as Lang.Number;
		var size_y as Lang.Number;

		var pos_x as Lang.Number;
		var pos_y as Lang.Number;
		var end_x as Lang.Number;
		var end_y as Lang.Number;

		function initialize(
			_pos_x as Lang.Number,
			_pos_y as Lang.Number,
			_size_x as Lang.Number,
			_size_y as Lang.Number
		) {
			self.size_x = _size_x;
			self.size_y = _size_y;
			self.pos_x = _pos_x;
			self.pos_y = _pos_y;
			self.end_x = _pos_x + _size_x;
			self.end_y = _pos_y + _size_y;
		}

		static function ForY(
			_screen_size_y as Lang.Number,
			_y as Lang.Number,
			_dy as Lang.Number
		) as Box {
			var pos_y = 0;
			var end_y = 0;

			if (_dy < 0) {
				// above
				pos_y = _y + _dy;
				end_y = _y;
			} else {
				// below
				pos_y = _y;
				end_y = _y + _dy;
			}

			var size_pos = Math.floor(
				Box.SecondLeg_(_screen_size_y, pos_y) * 2
			).toNumber();
			var size_end = Math.floor(
				Box.SecondLeg_(_screen_size_y, end_y) * 2
			).toNumber();

			var size_x = size_pos < size_end ? size_pos : size_end;
			var pos_x = (_screen_size_y - size_x) / 2;
			var size_y = end_y - pos_y;

			return new Box(pos_x, pos_y, size_x, size_y);
		}

		static function SecondLeg_(
			_screen_size as Lang.Number,
			_leg as Lang.Number
		) as Lang.Numeric {
			var hypotenuse = _screen_size / 2;
			var leg = hypotenuse - _leg; // center of triangle is in the center of screen

			return Math.sqrt(hypotenuse * hypotenuse - leg * leg).toNumber();
		}
	}
} // module Phase0
