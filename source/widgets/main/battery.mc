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
		var is_charging_ as Lang.Boolean = false;
		var bar_all_count_ as Lang.Number = 0;

		var properties as Properties.Widget;

		function initialize(_properties as Properties.Widget) {
			Main.initialize(battery_impl_.type);

			self.properties = _properties;
			self.value_impl_ =
				_properties.data == Properties.BATTERY_DAYS_REMAINING
					? new Data.BatteryDaysRemaining()
					: self.battery_impl_;
		}

		function resize(
			_dc as Graphics.Dc,
			_size_x as Lang.Number,
			_size_y as Lang.Number
		) as Void {
			Base.resize(_dc, _size_x, _size_y);

			var borders_width = Render.IconsWidth(
				_dc,
				Fonts.ICON_BATTERY_BEGIN + Fonts.ICON_BATTERY_END
			);
			var bar_width = Render.IconsWidth(_dc, Fonts.ICON_BATTERY_EMPTY);

			self.bar_all_count_ = Render.BarCount(
				self.size_x,
				borders_width,
				bar_width
			);
			self.frame_ =
				Fonts.ICON_BATTERY_BEGIN +
				Render.Repeat(Fonts.ICON_BATTERY_FRAME, self.bar_all_count_) +
				Fonts.ICON_BATTERY_END;
		}

		function refresh(_dc as Graphics.Dc) as Void {
			self.battery_impl_.refresh();
			self.is_charging_ = System.getSystemStats().charging;
			if (self.properties.data == Properties.BATTERY_DAYS_REMAINING) {
				self.value_impl_.refresh();
			}

			var value_maybe = self.battery_impl_.value;
			var value_max_maybe = self.battery_impl_.value_max;
			var display_value_maybe = self.value_impl_.value;

			self.value_ = "";
			if (display_value_maybe != null) {
				self.value_ = display_value_maybe.toString();
				if (self.properties.data == Properties.BATTERY_DAYS_REMAINING) {
					self.value_ += "d";
				}
			}

			if (value_maybe == null or value_max_maybe == null) {
				self.color_ = Properties.general.accent;
				self.charge_ = self.chargeString_(0);
				return;
			}

			var value = value_maybe as Lang.Number;
			var value_max = value_max_maybe as Lang.Number;

			if (value < 10) {
				self.color_ = Properties.general.accent;
			} else if (100 <= value) {
				self.color_ = Properties.general.accent;
			} else {
				self.color_ = Properties.general.foreground;
			}

			var bar_charged_count =
				value_max == 0
					? 0
					: Math.round(
							(value.toFloat() / value_max) * self.bar_all_count_
						).toNumber();
			self.charge_ = self.chargeString_(bar_charged_count);
		}

		function chargeString_(_charged_count as Lang.Number) as Lang.String {
			var charged_count = _charged_count;
			if (charged_count < 0) {
				charged_count = 0;
			} else if (self.bar_all_count_ < charged_count) {
				charged_count = self.bar_all_count_;
			}

			return (
				Fonts.ICON_BATTERY_EMPTY +
				Render.Repeat(Fonts.ICON_BATTERY_CHARGE, charged_count) +
				Render.Repeat(
					Fonts.ICON_BATTERY_EMPTY,
					self.bar_all_count_ - charged_count
				) +
				Fonts.ICON_BATTERY_EMPTY
			);
		}

		function render_(
			_dc as Graphics.Dc,
			_frame as Lang.String,
			_charge_shade as Lang.String
		) as Void {
			var center_x = self.centerX();
			var center_y = self.centerY();

			if (self.properties.data == Properties.BATTERY_ICON) {
				Render.Icons(
					_dc,
					self.color_,
					center_x,
					center_y,
					self.charge_,
					_charge_shade,
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
				Properties.general.accent,
				center_x,
				center_y,
				_frame,
				self.frame_,
				Render.JUSTIFY_CENTER
			);
		}

		function render(_dc as Graphics.Dc) as Void {
			self.render_(
				_dc,
				self.is_charging_ ? self.frame_ : "",
				self.charge_
			);
		}

		function renderMinimal(_dc as Graphics.Dc) as Void {
			self.render_(_dc, "", "");
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
