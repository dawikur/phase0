// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Complications;
import Toybox.Graphics;
import Toybox.Lang;

module Widgets {
	function Fits(
		_size_x as Lang.Number,
		_size_y as Lang.Number,
		_available_x as Lang.Number,
		_available_y as Lang.Number
	) as Lang.Boolean {
		return _size_x <= _available_x and _size_y <= _available_y;
	}

	function CenterStart(
		_center as Lang.Number,
		_size as Lang.Number
	) as Lang.Number {
		return _center - _size / 2;
	}

	function AlignCenter(
		_pos as Lang.Number,
		_anchor_size as Lang.Number,
		_size as Lang.Number
	) as Lang.Number {
		return _pos + (_anchor_size - _size) / 2;
	}

	class Base {
		var pos_x as Lang.Number = 0;
		var pos_y as Lang.Number = 0;

		var size_x as Lang.Number = 0;
		var size_y as Lang.Number = 0;

		var id as Complications.Id?;

		function initialize(_type as Complications.Type?) {
			if (
				Toybox has :Complications and
				_type != null and
				_type != Complications.COMPLICATION_TYPE_INVALID
			) {
				self.id = new Complications.Id(_type);
			} else {
				self.id = null;
			}
		}

		function resize(
			_dc as Graphics.Dc,
			_size_x as Lang.Number,
			_size_y as Lang.Number
		) as Void {
			self.size_x = _size_x;
			self.size_y = _size_y;
		}

		function centerX() as Lang.Number {
			return self.pos_x + self.size_x / 2;
		}

		function centerY() as Lang.Number {
			return self.pos_y + self.size_y / 2;
		}

		function contains(
			_x as Lang.Number,
			_y as Lang.Number
		) as Lang.Boolean {
			var pos_x = self.pos_x;
			var pos_y = self.pos_y;
			var end_x = self.pos_x + self.size_x;
			var end_y = self.pos_y + self.size_y;

			return pos_x <= _x and _x <= end_x and pos_y <= _y and _y <= end_y;
		}

		function open() as Lang.Boolean {
			if (Toybox has :Complications and self.id != null) {
				Complications.exitTo(self.id);

				return true;
			}

			return false;
		}

		function refresh(_dc as Graphics.Dc) as Void {}

		function render(_dc as Graphics.Dc) as Void {}
	}
} // module Widgets
