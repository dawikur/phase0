// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;

module Main {

class Status {
	var center_x as Lang.Number = 0;
	var center_y as Lang.Number = 0;

	hidden var format_ as Lang.String = "$1$\n$2$\n$3$";
	hidden var enabled_ as Lang.String = "";
	hidden var all_ as Lang.String;

	function initialize() {
		self.all_ = Lang.format(self.format_, [
			Font.ICON_ALARM,
			Font.ICON_BLUETOOTH,
			Font.ICON_NOTIFICATION
		]);
	}

	function refresh(_dc as Graphics.Dc) as Void {
		var device_settings = System.getDeviceSettings();

		var icon_alarm = "";
		if (0 < device_settings.alarmCount) {
			icon_alarm = Font.ICON_ALARM;
		}

		var icon_bluetooth = "";
		if (device_settings.phoneConnected) {
			icon_bluetooth = Font.ICON_BLUETOOTH;
		}

		var icon_notification = "";
		if (device_settings has :doNotDisturb and device_settings.doNotDisturb) {
			icon_notification = Font.ICON_DO_NOT_DISTURB;
		} else if (0 < device_settings.notificationCount) {
			icon_notification = Font.ICON_NOTIFICATION;
		}

		self.enabled_ = Lang.format(self.format_, [
			icon_alarm,
			icon_bluetooth,
			icon_notification
		]);
	}

	function render(_dc as Graphics.Dc, _is_night_mode as Lang.Boolean) as Void {
		if (_is_night_mode) {
			Render.icons(
				_dc, center_x, center_y,
				self.enabled_,
				""
			);
		} else {
			Render.icons(
				_dc, center_x, center_y,
				self.enabled_,
				self.all_
			);
		}
	}
}

} // module Main
