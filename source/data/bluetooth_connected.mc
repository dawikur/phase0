// Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

import Toybox.Lang;
import Toybox.System;

module Data {
	(:data_icon,:data_status)
	class BluetoothConnected extends Base {
		function initialize() {
			Base.initialize(
				null,
				Resources.get(Rez.Strings.LABEL_BLUETOOTH_CONNECTED),
				RefreshRate.SEC
			);
			self.icon = Fonts.ICON_BLUETOOTH_ON;
		}

		function defaultWidth() as Lang.Number {
			return 0;
		}

		function refresh() as Void {
			var settings = System.getDeviceSettings();
			self.icon = settings.phoneConnected ? Fonts.ICON_BLUETOOTH_ON : Fonts.ICON_EMPTY;
		}
	}
} // module Data
