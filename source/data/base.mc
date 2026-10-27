// Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

import Toybox.ActivityMonitor;
import Toybox.Complications;
import Toybox.Lang;

module Data {
	class Base {
		(:input_touch)
		hidden var type_ as Complications.Type?;
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
			self.setType_(_type);
			self.name = _name;
			self.refresh_rate = _refresh_rate;
		}

		(:input_touch)
		hidden function setType_(_type as Complications.Type?) as Void {
			self.type_ = _type;
		}

		(:input_not_touch)
		hidden function setType_(_type as Complications.Type?) as Void {}

		(:input_touch)
		function getType() as Complications.Type? {
			return self.type_;
		}

		(:input_not_touch)
		function getType() as Complications.Type? {
			return null;
		}

		function defaultWidth() as Lang.Number {
			return 3;
		}

		function refresh() as Void {}

		function refreshRevision() as Lang.Number? {
			return null;
		}
	}
} // module Data
