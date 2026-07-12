// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;

module Widgets {
	class Status extends Main {
		hidden var enabled_ as Lang.String = "";
		hidden var all_ as Lang.String;

		var properties as Lang.Array<Properties.Status>;

		function initialize(_properties as Lang.Array<Properties.Status>) {
			Main.initialize(Complications.COMPLICATION_TYPE_INVALID);

			self.properties = _properties;

			self.all_ = "";
			var properties_size = self.properties.size();
			for (var i = 0; i < properties_size; ++i) {
				var property = self.properties[i];

				var icon = self.getIcon_(property.data);
				if (icon.length() != 0) {
					self.all_ += i == 0 ? "" : "\n";
					self.all_ += icon;
				}
			}
		}

		function refresh(_dc as Graphics.Dc) as Void {
			var device_settings = System.getDeviceSettings();

			self.enabled_ = "";
			var properties_size = self.properties.size();
			for (var i = 0; i < properties_size; ++i) {
				var property = self.properties[i];

				var icon = self.getStatus_(property.data, device_settings);
				if (icon.length() != 0) {
					self.enabled_ += i == 0 ? "" : "\n";
					self.enabled_ += icon;
				}
			}
		}

		function render(_dc as Graphics.Dc) as Void {
			Render.Icons(
				_dc,
				Properties.general.foreground,
				self.pos_x,
				self.pos_y,
				self.enabled_,
				self.all_,
				Render.JUSTIFY_CENTER
			);
		}

		function renderMinimal(_dc as Graphics.Dc) as Void {
			Render.Icons(
				_dc,
				Properties.general.foreground,
				self.pos_x,
				self.pos_y,
				self.enabled_,
				"",
				Render.JUSTIFY_CENTER
			);
		}

		static function getIcon_(_id as Lang.Number) as Lang.String {
			switch (_id) {
				case Properties.ALARM:
					return Fonts.ICON_ALARM;
				case Properties.BLUETOOTH_CONNECTED:
					return Fonts.ICON_BLUETOOTH;
				case Properties.BLUETOOTH_DISCONNECTED:
					return Fonts.ICON_BLUETOOTH;
				case Properties.NOTIFICATIONS:
					return Fonts.ICON_NOTIFICATION;

				default:
					break;
			}

			return "";
		}

		static function getStatus_(
			_id as Lang.Number,
			_device_settings as System.DeviceSettings
		) as Lang.String {
			switch (_id) {
				case Properties.ALARM:
					if (0 < _device_settings.alarmCount) {
						return Fonts.ICON_ALARM;
					}
					return Fonts.ICON_EMPTY;

				case Properties.BLUETOOTH_CONNECTED:
					if (_device_settings.phoneConnected) {
						return Fonts.ICON_BLUETOOTH;
					}
					return Fonts.ICON_EMPTY;

				case Properties.BLUETOOTH_DISCONNECTED:
					if (!_device_settings.phoneConnected) {
						return Fonts.ICON_BLUETOOTH_OFF;
					}
					return Fonts.ICON_EMPTY;

				case Properties.NOTIFICATIONS:
					if (
						_device_settings has :doNotDisturb and
						_device_settings.doNotDisturb
					) {
						return Fonts.ICON_DO_NOT_DISTURB;
					}
					if (0 < _device_settings.notificationCount) {
						return Fonts.ICON_NOTIFICATION;
					}
					return Fonts.ICON_EMPTY;

				default:
					break;
			}

			return "";
		}
	}
} // module Widgets
