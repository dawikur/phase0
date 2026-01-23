// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Weather;

module Element {

class Weather extends Label {
	var size_x as Lang.Number = 0;

	hidden var unitsSystem_ as System.UnitsSystem;

	function initialize() {
		Label.initialize();

		self.styles = [
			new Element.Style(Font.TYPEFACE_DOT, Font.STYLE_SMALL, 0xAAAAAA),
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

		var width = 0;
		var styles = self.styles;
		var styles_size = styles.size();
		var label = self.label;

		for (var i = 0; i < styles_size; ++i) {
			var style = styles[i];

			var width_i = style.typeface.measure(label, style.style);

			if (width < width_i) {
				width = width_i;
			}
		}

		if (width < self.size_x) {
			self.padding_x = (self.size_x - width) / 2;
		}
	}
}

} // module Element
