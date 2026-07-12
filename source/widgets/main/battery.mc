// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;

module Widgets {
	class Battery extends Main {
		var battery_impl_ as Data.BatteryPercentage =
			new Data.BatteryPercentage();
		var value_impl_ as Data.Base = new Data.BatteryPercentage();

		var color_ as Lang.Number = 0;

		var value_ as Lang.String = "";
		var charge_ as Lang.String = "";
		var frame_ as Lang.String = "";

		var properties as Properties.Widget;

		function initialize(_properties as Properties.Widget) {
			Main.initialize(battery_impl_.type);

			self.properties = _properties;
			self.value_impl_ =
				_properties.data == Properties.BATTERY_DAYS_REMAINING
					? new Data.BatteryDaysRemaining()
					: self.battery_impl_;
		}

		function refresh(_dc as Graphics.Dc) as Void {
			self.battery_impl_.refresh();
			if (self.properties.data == Properties.BATTERY_DAYS_REMAINING) {
				self.value_impl_.refresh();
			}

			var value = self.battery_impl_.value as Lang.Number;
			var value_max = self.battery_impl_.value_max as Lang.Number;
			var display_value = self.value_impl_.value as Lang.Number;

			self.value_ = display_value.toString();
			if (self.properties.data == Properties.BATTERY_DAYS_REMAINING) {
				self.value_ += "d";
			}

			if (value < 10) {
				self.color_ = self.properties.accent;
			} else if (100 <= value) {
				self.color_ = self.properties.accent;
			} else {
				self.color_ = Properties.general.foreground;
			}

			var borders_width = Render.IconsWidth(
				_dc,
				Fonts.ICON_BATTERY_BEGIN + Fonts.ICON_BATTERY_END
			);
			var bar_width = Render.IconsWidth(_dc, Fonts.ICON_BATTERY_EMPTY);

			var bar_all_count = 0;
			if (0 < bar_width) {
				bar_all_count = (self.size_x - borders_width) / bar_width;
				if (bar_all_count < 0) {
					bar_all_count = 0;
				}
			}
			var bar_charged_count = Math.round(
				(value.toFloat() / value_max) * bar_all_count
			).toNumber();
			if (bar_charged_count < 0) {
				bar_charged_count = 0;
			} else if (bar_all_count < bar_charged_count) {
				bar_charged_count = bar_all_count;
			}

			self.frame_ = Fonts.ICON_BATTERY_BEGIN;
			for (var i = 0; i < bar_all_count; ++i) {
				self.frame_ += Fonts.ICON_BATTERY_FRAME;
			}
			self.frame_ += Fonts.ICON_BATTERY_END;

			self.charge_ = Fonts.ICON_BATTERY_EMPTY;
			for (var i = 0; i < bar_charged_count; ++i) {
				self.charge_ += Fonts.ICON_BATTERY_CHARGE;
			}
			for (var i = bar_charged_count; i < bar_all_count; ++i) {
				self.charge_ += Fonts.ICON_BATTERY_EMPTY;
			}
			self.charge_ += Fonts.ICON_BATTERY_EMPTY;
		}

		function render(_dc as Graphics.Dc) as Void {
			var center_x = self.pos_x + self.size_x / 2;
			var center_y = self.pos_y + self.size_y / 2;

			if (self.properties.data == Properties.BATTERY_ICON) {
				Render.Icons(
					_dc,
					self.color_,
					center_x,
					center_y,
					self.charge_,
					self.charge_,
					Render.JUSTIFY_CENTER
				);
			} else {
				Render.Text(
					_dc,
					Properties.general.foreground,
					center_x,
					center_y,
					Render.SIZE_SMALL,
					self.value_,
					Render.JUSTIFY_CENTER
				);
			}

			Render.Icons(
				_dc,
				self.properties.accent,
				center_x,
				center_y,
				System.getSystemStats().charging ? self.frame_ : "",
				self.frame_,
				Render.JUSTIFY_CENTER
			);
		}

		function renderMinimal(_dc as Graphics.Dc) as Void {
			var center_x = self.pos_x + self.size_x / 2;
			var center_y = self.pos_y + self.size_y / 2;

			if (self.properties.data == Properties.BATTERY_ICON) {
				Render.Icons(
					_dc,
					self.color_,
					center_x,
					center_y,
					self.charge_,
					"",
					Render.JUSTIFY_CENTER
				);
			} else {
				Render.Text(
					_dc,
					Properties.general.foreground,
					center_x,
					center_y,
					Render.SIZE_SMALL,
					self.value_,
					Render.JUSTIFY_CENTER
				);
			}

			Render.Icons(
				_dc,
				self.properties.accent,
				center_x,
				center_y,
				"",
				self.frame_,
				Render.JUSTIFY_CENTER
			);
		}
	}

	class BatteryIcon extends Battery {
		function initialize(
			_properties as Properties.Widget,
			_on_top as Lang.Boolean
		) {
			_properties.data = Properties.BATTERY_ICON;
			Battery.initialize(_properties);
		}
	}

	class BatteryPercentage extends Battery {
		function initialize(
			_properties as Properties.Widget,
			_on_top as Lang.Boolean
		) {
			_properties.data = Properties.BATTERY_PERCENTAGE;
			Battery.initialize(_properties);
		}
	}

	class BatteryDaysRemaining extends Battery {
		function initialize(
			_properties as Properties.Widget,
			_on_top as Lang.Boolean
		) {
			_properties.data = Properties.BATTERY_DAYS_REMAINING;
			Battery.initialize(_properties);
		}
	}
} // module Widgets
