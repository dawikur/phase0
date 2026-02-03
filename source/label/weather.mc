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
		var current_conditions = Weather.getCurrentConditions();
		if (current_conditions != null) {
			self.label_ = "";

			if (current_conditions.condition != null) {
				var condition = current_conditions.condition as Lang.Number;

				self.label_ += Application.loadResource(Resources.CONDITIONS[condition]) as Lang.String;
			}

			if (current_conditions.temperature != null) {
				var temperature = current_conditions.temperature as Lang.Numeric;
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
	}
}

} // module Label
