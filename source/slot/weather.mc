// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Weather;

module Slot {

class Weather extends Label {
	hidden var unitsSystem_ as System.UnitsSystem;

	function initialize() {
		Label.initialize();

		self.styles = [
			new Slot.Style(Font.TYPEFACE, Font.STYLE_SMALL, 0xAAAAAA),
		];

		var deviceSettings = System.getDeviceSettings();

		self.unitsSystem_ = deviceSettings.distanceUnits;
	}

	function refresh() as Void {
		var maybeCurrentConditions = Weather.getCurrentConditions();
		if (maybeCurrentConditions != null) {
			var currentConditions = maybeCurrentConditions;

			self.label = "";

			if (currentConditions.condition != null) {
				var condition = currentConditions.condition as Lang.Number;

				self.label += Resources.CONDITIONS[condition];
			}

			if (currentConditions.temperature != null) {
				var temperature = currentConditions.temperature as Lang.Numeric;
				var unit = "C";

				if (self.unitsSystem_ == System.UNIT_STATUTE) {
					temperature = (temperature * 1.8) + 32;
					unit = "F";
				}

				self.label += "\t";
				self.label += temperature.toNumber().format("%d");
				self.label += unit;
			}
		}
	}
}

} // module Slot
