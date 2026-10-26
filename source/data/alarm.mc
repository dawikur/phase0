// Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

import Toybox.Lang;
import Toybox.System;

module Data {
	(:data_icon,:data_status)
	class Alarm extends Base {
		function initialize() {
			Base.initialize(
				null,
				Resources.get(Rez.Strings.LABEL_ALARM),
				RefreshRate.SEC
			);
			self.icon = Fonts.ICON_ALARM;
		}

		function defaultWidth() as Lang.Number {
			return 1;
		}

		function refresh() as Void {
			var settings = System.getDeviceSettings();
			self.value = settings.alarmCount;
			self.icon = 0 < settings.alarmCount ? Fonts.ICON_ALARM : Fonts.ICON_EMPTY;
		}
	}
} // module Data
