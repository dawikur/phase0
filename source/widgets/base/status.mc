// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;

module Widgets {
	class Status extends Base {
		hidden var enabled_ as Lang.String = "";
		hidden var all_ as Lang.String;
		hidden var slots_ as Lang.Array<Lang.Number> = [];

		function initialize(_properties as Lang.Array<Properties.Status>) {
			Base.initialize(null, RefreshRate.SEC);

			self.all_ = "";
			self.slots_ = [];
			var properties_size = _properties.size();
			for (var i = 0; i < properties_size; ++i) {
				var property = _properties[i];

				var icon = self.getIcon_(property.data);
				if (icon.length() != 0) {
					self.slots_.add(property.data);
					self.all_ = self.appendIcon_(self.all_, icon);
				}
			}
		}

		function refresh(_dc as Graphics.Dc) as Void {
			var device_settings = System.getDeviceSettings();

			self.enabled_ = "";
			var slot_size = self.slots_.size();
			for (var i = 0; i < slot_size; ++i) {
				var slot = self.slots_[i];

				var icon = self.getStatus_(slot, device_settings);
				if (icon.length() != 0) {
					self.enabled_ = self.appendIcon_(self.enabled_, icon);
				}
			}
		}

		function render(_dc as Graphics.Dc) as Void {
			var center_x = self.centerX();
			var center_y = self.centerY() + Render.SHADOW_OFFSET;

			Render.Icons(
				_dc,
				Render.foreground,
				center_x,
				center_y,
				self.enabled_,
				self.all_,
				Render.JUSTIFY_CENTER
			);
		}

		function renderMinimal(_dc as Graphics.Dc) as Void {
			var center_x = self.centerX();
			var center_y = self.centerY() + Render.SHADOW_OFFSET;

			Render.Icons(
				_dc,
				Render.foreground,
				center_x,
				center_y,
				self.enabled_,
				"",
				Render.JUSTIFY_CENTER
			);
		}

		static function appendIcon_(
			_icons as Lang.String,
			_icon as Lang.String
		) as Lang.String {
			return _icons.length() == 0 ? _icon : _icons + "\n" + _icon;
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
