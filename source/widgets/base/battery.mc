// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Complications;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;

module Widgets {
	class Battery extends Base {
		hidden var color_ as Lang.Number = 0;

		hidden var value_ as Lang.String = "";
		hidden var frame_ as Lang.String = "";
		hidden var is_charging_ as Lang.Boolean = false;
		hidden var bar_all_count_ as Lang.Number = 0;
		hidden var last_value_ as Lang.Number = -1;
		hidden var last_value_suffix_ as Lang.Char = ' ';

		hidden var data_ as Lang.Number;

		function initialize(
			_properties as Properties.Widget,
			_on_top as Lang.Boolean
		) {
			Base.initialize(
				Toybox has :Complications
					? Complications.COMPLICATION_TYPE_BATTERY
					: null,
				RefreshRate.SEC
			);

			self.data_ = _properties.data;
		}

		function resize(
			_dc as Graphics.Dc,
			_size_x as Lang.Number,
			_size_y as Lang.Number
		) as Void {
			Base.resize(
				_dc,
				2 * Render.IconsWidth(_dc, Fonts.ICON_EMPTY),
				_size_y
			);
			self.pos_x += (_size_x - self.size_x) / 2;

			var borders_width = Render.IconsRawWidth(
				_dc,
				Fonts.ICON_BATTERY_BEGIN + Fonts.ICON_BATTERY_END
			);
			var bar_width = Render.IconsRawWidth(_dc, Fonts.ICON_BATTERY_EMPTY);

			self.bar_all_count_ = Render.BarCount(
				self.size_x - Render.SHADOW_OFFSET,
				borders_width,
				bar_width
			);
			self.frame_ =
				Fonts.ICON_BATTERY_BEGIN +
				Render.Repeat(Fonts.ICON_BATTERY_FRAME, self.bar_all_count_) +
				Fonts.ICON_BATTERY_END;
			self.is_dirty_ = true;
		}

		function refresh(_dc as Graphics.Dc) as Void {
			var system_stats = System.getSystemStats();

			var is_charging = system_stats.charging;

			var percentage = system_stats.battery;
			var value = percentage.toNumber();
			var value_suffix = ' ';

			switch (self.data_) {
				case Properties.DATA_BATTERY_DAYS_REMAINING:
					var days = system_stats.batteryInDays;
					if (1.0 <= days) {
						value = days.toNumber();
						value_suffix = 'd';
					} else {
						var hours = days * 24;
						if (1.0 <= hours) {
							value = hours.toNumber();
							value_suffix = 'h';
						} else {
							value = (hours * 60).toNumber();
							value_suffix = 'm';
						}
					}
					break;
				case Properties.DATA_BATTERY_ICON:
					value = Math.round(
						(percentage / 100) * self.bar_all_count_
					).toNumber();
					break;
			}

			var color = Render.foreground;
			if (percentage < 10) {
				color = Render.accent;
			} else if (100 <= percentage) {
				color = Render.accent;
			}

			if (self.is_charging_ != is_charging or self.color_ != color) {
				self.is_dirty_ = true;
			}
			self.is_charging_ = is_charging;
			self.color_ = color;

			if (
				self.last_value_ == value and
				self.last_value_suffix_ == value_suffix
			) {
				return;
			}

			self.last_value_ = value;
			self.last_value_suffix_ = value_suffix;
			self.is_dirty_ = true;

			switch (self.data_) {
				case Properties.DATA_BATTERY_DAYS_REMAINING:
					self.value_ = value.toString();
					if (self.value_.length() < 3 and value_suffix != ' ') {
						self.value_ += value_suffix;
					}
					break;
				case Properties.DATA_BATTERY_PERCENTAGE:
					self.value_ = value.toString();
					break;
				case Properties.DATA_BATTERY_ICON:
					self.value_ = self.chargeString_(value);
					break;
			}
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

			if (self.data_ == Properties.DATA_BATTERY_ICON) {
				Render.Icons(
					_dc,
					self.color_,
					center_x,
					center_y,
					self.value_,
					_charge_shade,
					Render.JUSTIFY_CENTER
				);
			} else {
				Render.Text(
					_dc,
					Render.foreground,
					center_x,
					center_y,
					Render.SIZE_SMALL,
					self.value_,
					Render.JUSTIFY_CENTER
				);
			}

			Render.Icons(
				_dc,
				Render.accent,
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
				self.value_
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
			Battery.initialize(_properties, _on_top);
		}
	}

	class BatteryPercentage extends Battery {
		function initialize(
			_properties as Properties.Widget,
			_on_top as Lang.Boolean
		) {
			Battery.initialize(_properties, _on_top);
		}
	}

	class BatteryDaysRemaining extends Battery {
		function initialize(
			_properties as Properties.Widget,
			_on_top as Lang.Boolean
		) {
			Battery.initialize(_properties, _on_top);
		}
	}
} // module Widgets
