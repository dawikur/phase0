// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Weather;

module Slot {

class Temperature extends Base {
	function initialize() {
		Base.initialize();

		self.styles = [
			new Slot.Style(Font.TYPEFACE, Font.STYLE_SMALL, 0xAAAAAA),
		];
	}

	function renderData(_dc as Graphics.Dc, _clock as System.ClockTime, _data as Data) as Void {
		if (_data.hasKey(:weather)) {
			var weather = _data[:weather] as Weather.CurrentConditions;

			if (weather.temperature != null) {
				var temperature = weather.temperature as Lang.Numeric;
				var unit = "C";

				if (_data[:temperatureUnits] == System.UNIT_STATUTE) {
					temperature = (temperature * 1.8) + 32;
					unit = "F";
				}

				var temperature_str = temperature.toNumber().format("%d");

				while (temperature_str.length() < 4) {
					temperature_str = "\t" + temperature_str;
				}

				Base.render(_dc, temperature_str + unit);
			}
		}
	}
}

} // module Slot
