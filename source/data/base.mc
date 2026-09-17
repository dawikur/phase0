// Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

import Toybox.ActivityMonitor;
import Toybox.Complications;
import Toybox.Lang;

module Data {
	// TODO(api-4.2.0): Isolate Complications types for API 3.4 devices.
	class Base {
		var type as Complications.Type?;
		var name as Lang.String;
		var refresh_rate as Lang.Number;

		var icon as Lang.String? = null;
		var value as Lang.Number? = null;
		var value_max as Lang.Number? = null;

		function initialize(
			_type as Complications.Type?,
			_name as Lang.String,
			_refresh_rate as Lang.Number
		) {
			self.type = _type;
			self.name = _name;
			self.refresh_rate = _refresh_rate;
		}

		function refresh() as Void {}

		function refreshRevision() as Lang.Number? {
			return null;
		}
	}
} // module Data
