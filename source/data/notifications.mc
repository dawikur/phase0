// Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

import Toybox.Lang;
import Toybox.System;

module Data {
	(:data_icon,:data_status)
	class Notifications extends Base {
		function initialize() {
			Base.initialize(
				null,
				Resources.get(Rez.Strings.LABEL_NOTIFICATIONS),
				RefreshRate.SEC
			);
			self.icon = Fonts.ICON_NOTIFICATION;
		}

		function defaultWidth() as Lang.Number {
			return 2;
		}

		function refresh() as Void {
			var settings = System.getDeviceSettings();
			self.value = settings.notificationCount;
			self.icon = settings has :doNotDisturb and settings.doNotDisturb
				? Fonts.ICON_DO_NOT_DISTURB
				: (0 < settings.notificationCount ? Fonts.ICON_NOTIFICATION : Fonts.ICON_EMPTY);
		}
	}
} // module Data
