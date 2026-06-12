// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Complications;
import Toybox.Graphics;
import Toybox.Lang;

module Widget {

class Base {
	var pos_x as Lang.Number = 0;
	var pos_y as Lang.Number = 0;

	var size_x as Lang.Number = 0;
	var size_y as Lang.Number = 0;

	var id as Complications.Id or Null;

	function initialize(_type as Complications.Type) {
		if (_type != Complications.COMPLICATION_TYPE_INVALID) {
			self.id = new Complications.Id(_type);
		} else {
			self.id = null;
		}
	}

	function contains(_x as Lang.Number, _y as Lang.Number) as Lang.Boolean {
		var pos_x = self.pos_x;
		var pos_y = self.pos_y;
		var end_x = self.pos_x + self.size_x;
		var end_y = self.pos_y + self.size_y;

		return
			pos_x <= _x and _x <= end_x and
			pos_y <= _y and _y <= end_y;
	}

	function open() as Lang.Boolean {
		if (self.id != null) {
			Complications.exitTo(self.id);

			return true;
		}

		return false;
	}

	function refresh(_dc as Graphics.Dc) as Void {
	}

	function render(_dc as Graphics.Dc) as Void {
	}
}

} // module Widget
