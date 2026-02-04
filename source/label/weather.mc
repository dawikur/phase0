// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Weather;

module Label {

class Weather extends Base {
	var size_x as Lang.Number = 0;

	hidden var units_system_ as System.UnitsSystem;

	function initialize() {
		Base.initialize();

		self.justify_ = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;

		var device_settings = System.getDeviceSettings();

		self.units_system_ = device_settings.distanceUnits;
	}

	function refresh(_dc as Graphics.Dc) as Void {
		var weather = Weather.getCurrentConditions();
		if (weather != null) {
			self.label_ = "";

			if (weather.condition != null) {
				var condition = weather.condition as Lang.Number;

				self.label_ += Application.loadResource(Resources.CONDITIONS[condition]) as Lang.String;
			}

			if (weather.temperature != null) {
				var temperature = weather.temperature as Lang.Numeric;
				var unit = "C";

				if (self.units_system_ == System.UNIT_STATUTE) {
					temperature = (temperature * 1.8) + 32;
					unit = "F";
				}

				self.label_ += "  ";
				self.label_ += temperature.toNumber().format("%d");
				self.label_ += unit;
			}
		}

		var now = Time.now().value();

		if (self.label_.length() != 0) {
			// update data
			Application.Storage.setValue("weather", self.label_);
			Application.Storage.setValue("weather_timestamp", now);
		} else {
			// read data
			try {
				var data = Application.Storage.getValue("weather") as Lang.String;
				var timestamp = Application.Storage.getValue("weather_timestamp") as Lang.Number;
				var data_age = now - timestamp;

				if (0 < data_age and data_age < 3600) {
					// data valid
					self.label_ = data;
				} else {
					// data expired: clear cache
					Application.Storage.deleteValue("weather");
					Application.Storage.deleteValue("weather_timestamp");
				}
			} catch (ex instanceof Lang.UnexpectedTypeException) {
				// error: clear data
				Application.Storage.deleteValue("weather");
				Application.Storage.deleteValue("weather_timestamp");
			}
		}
	}
}

} // module Label
