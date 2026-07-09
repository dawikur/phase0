// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.ActivityMonitor;
import Toybox.Complications;
import Toybox.Lang;
import Toybox.SensorHistory;

module Data {
	class Base {
		var type as Complications.Type;
		var name as Lang.String;

		var icon as Lang.String? = null;
		var value as Lang.Number? = null;
		var value_max as Lang.Number? = null;

		function initialize(_type as Complications.Type, _name as Lang.String) {
			self.type = _type;
			self.name = _name;
		}

		function refresh() as Void {
			self.value = self.get_();
		}

		function get_() as Lang.Number? {
			var maybe_value = self.getMaybe_();

			if (self.name.length() != 0) {
				if (maybe_value != null) {
					Cache.setValue(self.name, maybe_value as Lang.Number);
				} else {
					maybe_value = Cache.getValue(self.name, 2) as Lang.Number?;
				}
			}

			return maybe_value;
		}

		function getMaybe_() as Lang.Number? {
			return null;
		}

		protected static function getSensorHistoryData_(
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
