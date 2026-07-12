// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.ActivityMonitor;
import Toybox.Complications;
import Toybox.Lang;

module Data {
	class UvIndex extends Base {
		function initialize() {
			Base.initialize(
				Complications.COMPLICATION_TYPE_INVALID,
				Resources.get(Rez.Strings.LABEL_UV_INDEX)
			);

			self.icon = Fonts.ICON_UV_LOW;
		}

		function get_() as Lang.Number? {
			self.icon = Fonts.ICON_UV_LOW;

			var uv_index = WeatherProvider.getUvIndex();
			if (uv_index != null) {
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

			return null;
		}
	}
} // module Data
