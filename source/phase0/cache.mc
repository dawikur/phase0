// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Application;
import Toybox.Lang;
import Toybox.Time;

module Cache {

function setValue(_name as Lang.String, _data as Lang.String) as Void {
	var now = Time.now().value();

	Application.Storage.setValue(_name, _data);
	Application.Storage.setValue(_name + "_timestamp", now);
}

function getValue(_name as Lang.String, _til as Lang.Number) as Lang.String or Null {
	try {
		var data = Application.Storage.getValue(_name) as Lang.String;
		var timestamp = Application.Storage.getValue(_name + "_timestamp") as Lang.Number;

		var now = Time.now().value();
		var data_age = now - timestamp;

		if (0 < data_age and data_age < _til) {
			return data;
		}

	} catch (ex instanceof Lang.UnexpectedTypeException) {
	}

	Application.Storage.deleteValue(_name);
	Application.Storage.deleteValue(_name + "_timestamp");

	return null;
}

} // module Cache
