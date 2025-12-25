// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Graphics;
import Toybox.System;

module Slot {

class Seconds extends Base {
	function initialize() {
		Base.initialize();

		self.styles = [
			new Slot.Style(Font.TYPEFACE, Font.STYLE_REGULAR_THIN, 0xAAAAAA),
		];
	}

	function renderData(_dc as Graphics.Dc, _clock as System.ClockTime, _data as Data) as Void {
		Base.render(_dc, _clock.sec.format("%02d"));
	}
}

} // module Slot
