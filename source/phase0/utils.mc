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

	var center_x as Lang.Number;
	var center_y as Lang.Number;

	var radius_x as Lang.Number;
	var radius_y as Lang.Number;

	function initialize(
		_pos_x as Lang.Number,
		_pos_y as Lang.Number,
		_end_x as Lang.Number,
		_end_y as Lang.Number
	) {
		self.size_x = _end_x - _pos_x;
		self.size_y = _end_y - _pos_y;
		self.pos_x = _pos_x;
		self.pos_y = _pos_y;
		self.end_x = _end_x;
		self.end_y = _end_y;
		self.radius_x = self.size_x / 2;
		self.radius_y = self.size_y / 2;
		self.center_x = _pos_x + self.radius_x;
		self.center_y = _pos_y + self.radius_y;
	}

	static function secondLeg(_screen_size as Lang.Number, _leg as Lang.Number) as Lang.Numeric {
		var hypotenuse = _screen_size / 2;
		var leg = hypotenuse - _leg; // center of triangle is in the center of screen

		return Math.sqrt((hypotenuse * hypotenuse) - (leg * leg)).toNumber();
	}

	static function ForY(_screen_size_y as Lang.Number, _y as Lang.Number, _dy as Lang.Number) as Box {
		var pos_y = 0;
		var end_y = 0;

		if (_dy < 0) { // above
			pos_y = _y + _dy;
			end_y = _y;
		} else { // below
			pos_y = _y;
			end_y = _y + _dy;
		}

		var size_pos = Math.floor(Box.secondLeg(_screen_size_y, pos_y) * 2).toNumber();
		var size_end = Math.floor(Box.secondLeg(_screen_size_y, end_y) * 2).toNumber();

		var size_x = size_pos < size_end ? size_pos : size_end;
		var pos_x = (_screen_size_y - size_x) / 2;
		var end_x = pos_x + size_x;

		return new Box(
			pos_x,
			pos_y,
			end_x,
			end_y
		);
	}
}

} // module Phase0
