// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;

module Slot {

class Date extends Base {
	function initialize() {
		Base.initialize();

		self.styles = [
			new Slot.Style(Font.TYPEFACE, Font.STYLE_REGULAR, 0x555555),
			new Slot.Style(Font.TYPEFACE, Font.STYLE_REGULAR_THIN, 0xAAAAAA),
		];
	}

	function renderData(_dc as Graphics.Dc, _clock as System.ClockTime, _data as Data) as Void {
		var now = _data[:now] as Time.Gregorian.Info;

		Base.render(_dc, $.join(" ", [
			Resources.DAYS_OF_WEEK[now.day_of_week as Lang.Number],
			now.day.format("%02d"),
			Resources.MONTHS[now.month as Lang.Number],
		]));
	}
}

} // module Slot
