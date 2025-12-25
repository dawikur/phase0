// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;

module Slot {

class Clock extends Base {
	function initialize() {
		Base.initialize();

		// TODO: black&white colors when in sleep mode?
		self.styles = [
			new Slot.Style(Font.DIGITS, Font.STYLE_REGULAR, 0xAA5500),
			new Slot.Style(Font.DIGITS_BLURED, Font.STYLE_REGULAR_THIN, 0xAA5500),
			new Slot.Style(Font.DIGITS, Font.STYLE_REGULAR_THIN, 0xFFAA00),
		];
	}

	function renderData(_dc as Graphics.Dc, _clock as System.ClockTime, _data as Data) as Void {
		if (_data[:is24Hour] as Lang.Boolean) {
			Base.render(_dc, $.join(":", [
				_clock.hour.format("%02d"),
				_clock.min.format("%02d"),
			]));
		} else {
			var hour = _clock.hour % 12;
			if (hour == 0) {
				hour = 12;
			}

			// TODO: use it
			// var ampm = _clock.hour < 12 ? "am" : "pm";

			Base.render(_dc, $.join(":", [
				hour.format("%02d"),
				_clock.min.format("%02d"),
			]));
		}
	}
}

} // module Slot
