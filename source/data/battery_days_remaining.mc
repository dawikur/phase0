// Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

import Toybox.Complications;
import Toybox.Lang;
import Toybox.System;

module Data {
	class BatteryDaysRemaining extends Base {
		function initialize() {
			Base.initialize(
				Toybox has :Complications
					? Complications.COMPLICATION_TYPE_BATTERY
					: null,
				Resources.get(Rez.Strings.LABEL_BATTERY_DAYS_REMAINING),
				Data.RefreshRate.SEC
			);
			self.icon = Fonts.ICON_NONE;
		}

		function defaultWidth() as Lang.Number {
			return 2;
		}

		function refresh() as Void {
			var stats = System.getSystemStats();
			var days = stats has :batteryInDays ? stats.batteryInDays : null;
			self.value = days != null ? days.toNumber() : null;
			self.icon = batteryIcon(stats.battery.toNumber());
		}

		function refreshRate() as Lang.Number {
			return Data.RefreshRate.SEC;
		}
	}
} // module Data
