// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.ActivityMonitor;
import Toybox.Lang;
import Toybox.Complications;

module Data {

const CATEGORY_ENERGY = Render.COLOR_YELLOW;
const CATEGORY_MOVEMENT = Render.COLOR_GREEN;
const CATEGORY_PHYSIOLOGICAL = Render.COLOR_RED;
const CATEGORY_RECOVERY = Render.COLOR_CYAN;
const CATEGORY_SYSTEM = Render.COLOR_BLUE;
const CATEGORY_VERTICAL = Render.COLOR_MAGENTA;

class Base {
	var type as Complications.Type;
	var name as Lang.String;
	var category as Lang.Number;

	function initialize(
		_type as Complications.Type,
		_name as Lang.String,
		_category as Lang.Number
	) {
		self.type = _type;
		self.name = _name;
		self.category = _category;
	}

	function get() as Lang.Number or Null {
		var maybe_value = self.getMaybe();

		if (self.name.length() != 0) {
			if (maybe_value != null) {
				Cache.setValue(self.name, maybe_value as Lang.Number);
			} else {
				maybe_value = Cache.getValue(self.name, 1) as Lang.Number or Null;
			}
		}

		return maybe_value;
	}

	function getMaybe() as Lang.Number or Null {
		return null;
	}

	function getMax() as Lang.Number or Null {
		return null;
	}
}

} // module Data
