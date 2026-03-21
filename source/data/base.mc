// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.ActivityMonitor;
import Toybox.Lang;
import Toybox.Complications;
import Toybox.SensorHistory;

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
	var icon as Lang.Char;

	var value as Lang.Number or Null = null;
	var value_max as Lang.Number or Null = null;

	function initialize(
		_type as Complications.Type,
		_name as Lang.String,
		_category as Lang.Number,
		_icon as Lang.Char
	) {
		self.type = _type;
		self.name = _name;
		self.category = _category;
		self.icon = _icon;
	}

	function refresh() as Void {
		self.value = self.get_();
	}

	function get_() as Lang.Number or Null {
		var maybe_value = self.getMaybe_();

		if (self.name.length() != 0) {
			if (maybe_value != null) {
				Cache.setValue(self.name, maybe_value as Lang.Number);
			} else {
				maybe_value = Cache.getValue(self.name, 1) as Lang.Number or Null;
			}
		}

		return maybe_value;
	}

	function getMaybe_() as Lang.Number or Null {
		return null;
	}

	static protected function getSensorHistoryData_(
		_iterator as SensorHistory.SensorHistoryIterator
	) as Lang.Number or Lang.Float or Null {
		if (_iterator != null) {
			var data_maybe = _iterator.next();
			if (data_maybe != null) {
				return data_maybe.data;
			}
		}
		return null;
	}
}

} // module Data
