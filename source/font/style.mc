// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Lang;

module Font {

class Style {
	var name as Lang.String;
	var size as Lang.Number;
	var weight as Lang.Number;

	function initialize(_name as Lang.String, _size as Lang.Number, _weight as Lang.Number) {
		self.name = _name;
		self.size = _size;
		self.weight = _weight;
	}
}

} // module Font
