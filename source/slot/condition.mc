// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Weather;

module Slot {

class Condition extends Base {
	function initialize() {
		Base.initialize();

		self.styles = [
			new Slot.Style(Font.TYPEFACE, Font.STYLE_SMALL, 0xAAAAAA),
		];
	}

	function renderData(_dc as Graphics.Dc, _clock as System.ClockTime, _data as Data) as Void {
		if (_data.hasKey(:weather)) {
			var weather = _data[:weather] as Weather.CurrentConditions;

			if (weather.condition != null) {
				Base.render(_dc, Resources.CONDITIONS[weather.condition as Lang.Number]);
			}
		}
	}
}

} // module Slot
