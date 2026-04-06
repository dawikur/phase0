// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.ActivityMonitor;
import Toybox.Lang;
import Toybox.Complications;

module Data {

class UV extends Base {
	function initialize() {
		Base.initialize(
			Complications.COMPLICATION_TYPE_INVALID,
			Resources.load(Rez.Strings.LABEL_UV),
			Render.COLOR_YELLOW,
			Fonts.ICON_UV_LOW
		);
	}

	function get_() as Lang.Number or Null {
		self.icon = Fonts.ICON_UV_LOW;

		var weather = Weather.getCurrentConditions();
		if (weather != null) {
			if (weather.uvIndex != null) {
				var uv_index = weather.uvIndex as Lang.Float;
				if (uv_index < 2) {
					self.icon = Fonts.ICON_UV_LOW;
				} else if (uv_index < 5) {
					self.icon = Fonts.ICON_UV_MODERATE;
				} else if (uv_index < 7) {
					self.icon = Fonts.ICON_UV_HIGH;
				} else if (uv_index < 9) {
					self.icon = Fonts.ICON_UV_VERY_HIGH;
				} else {
					self.icon = Fonts.ICON_UV_EXTREME;
				}

				return uv_index.toNumber();
			}
		}

		return null;
	}
}

} // module Data
