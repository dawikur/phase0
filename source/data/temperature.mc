// Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

import Toybox.Complications;
import Toybox.Lang;
import Toybox.SensorHistory;

module Data {
	class Temperature extends Base {
		function initialize() {
			Base.initialize(
				Toybox has :Complications
					? Complications.COMPLICATION_TYPE_CURRENT_TEMPERATURE
					: null,
				Resources.get(Rez.Strings.LABEL_TEMPERATURE),
				Data.RefreshRate.MIN
			);

			self.icon = Fonts.ICON_NONE;
		}

		function refresh() as Void {
			var temperature_c = null;
			if (SensorHistory has :getTemperatureHistory) {
				temperature_c = SensorProvider.get(
					self.name,
					SensorHistory.getTemperatureHistory(SensorProvider.OPTIONS)
				);
			}
			self.icon = temperatureIcon(temperature_c);
			self.value = temperature_c == null
				? null
				: Units.convertTemperature(temperature_c);
		}
	}
} // module Data
