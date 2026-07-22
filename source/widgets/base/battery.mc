// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Complications;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;

module Widgets {
	class Battery extends Base {
		var color_ as Lang.Number = 0;

		var value_ as Lang.String = "";
		var frame_ as Lang.String = "";
		var is_charging_ as Lang.Boolean = false;
		var bar_all_count_ as Lang.Number = 0;

		hidden var mode_ as Lang.Number;

		function initialize(_mode as Lang.Number) {
			Base.initialize(
				Toybox has :Complications
					? Complications.COMPLICATION_TYPE_BATTERY
					: null,
				RefreshRate.SEC
			);

			self.mode_ = _mode;
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
		}

		function refresh(_dc as Graphics.Dc) as Void {
			var system_stats = System.getSystemStats();

			self.is_charging_ = system_stats.charging;
			var percentage = system_stats.battery;

			self.value_ = "?";

			switch (self.mode_) {
				case Properties.BATTERY_DAYS_REMAINING:
					var days = system_stats.batteryInDays;
					if (1.0 <= days) {
						self.value_ = days.toNumber().toString();
						if (self.value_.length() < 3) {
							self.value_ += "d";
						}
					} else {
						var hours = days * 24;
						self.value_ = hours.toNumber().toString();
						if (self.value_.length() < 3) {
							self.value_ += "h";
						}
					}
					break;
				case Properties.BATTERY_PERCENTAGE:
					self.value_ = percentage.toNumber().toString();
					break;
				case Properties.BATTERY_ICON:
					self.value_ = self.chargeString_(Math.round(
						percentage / 100 * self.bar_all_count_
					).toNumber());
					break;
			}

			if (percentage < 10) {
				self.color_ = Render.accent;
			} else if (100 <= percentage) {
				self.color_ = Render.accent;
			} else {
				self.color_ = Render.foreground;
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

			if (self.mode_ == Properties.BATTERY_ICON) {
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
			Battery.initialize(Properties.BATTERY_ICON);
		}
	}

	class BatteryPercentage extends Battery {
		function initialize(
			_properties as Properties.Widget,
			_on_top as Lang.Boolean
		) {
			Battery.initialize(Properties.BATTERY_PERCENTAGE);
		}
	}

	class BatteryDaysRemaining extends Battery {
		function initialize(
			_properties as Properties.Widget,
			_on_top as Lang.Boolean
		) {
			Battery.initialize(Properties.BATTERY_DAYS_REMAINING);
		}
	}
} // module Widgets
