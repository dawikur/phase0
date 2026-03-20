// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.ActivityMonitor;
import Toybox.Lang;
import Toybox.Complications;

module Data {

class UV extends Base {
	function initialize() {
		Base.initialize(
			Complications.COMPLICATION_TYPE_INVALID,
			"UV",
			Render.COLOR_YELLOW,
			Fonts.ICON_UV_0
		);
	}

	function get() as Lang.Number or Null {
		self.icon = Fonts.ICON_UV_0;

		var weather = Weather.getCurrentConditions();
		if (weather != null) {
			if (weather.uvIndex != null) {
				var uv_index = weather.uvIndex as Lang.Float;
				if (uv_index < 1) {
					self.icon = Fonts.ICON_UV_0;
				} else if (uv_index < 3) {
					self.icon = Fonts.ICON_UV_1;
				} else if (uv_index < 8) {
					self.icon = Fonts.ICON_UV_2;
				} else if (uv_index < 11) {
					self.icon = Fonts.ICON_UV_3;
				} else {
					self.icon = Fonts.ICON_UV_4;
				}

				return uv_index.toNumber();
			}
		}

		return null;
	}
}

} // module Data
