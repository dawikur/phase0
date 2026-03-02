// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Application;
import Toybox.Complications;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Test;
import Toybox.Weather;

module Complication {

class Conditions extends Base {
	var icons_ as Lang.String = "";
	var text_ as Lang.String = "";

	function initialize() {
		Base.initialize(Complications.COMPLICATION_TYPE_CURRENT_WEATHER);
	}

	function refresh(_dc as Graphics.Dc) as Void {
		var weather = Weather.getCurrentConditions();
		if (weather != null) {
			self.icons_ = "";
			self.text_ = "    ";

			var rain_icon = Font.ICON_EMPTY;

			if (weather.precipitationChance != null) {
				var precipitation_chance = weather.precipitationChance as Lang.Number;
				if (precipitation_chance <= 20) {
					rain_icon = Font.ICON_RAIN_0;
				} else if (precipitation_chance <= 50) {
					rain_icon = Font.ICON_RAIN_1;
				} else if (precipitation_chance <= 80) {
					rain_icon = Font.ICON_RAIN_2;
				} else {
					rain_icon = Font.ICON_RAIN_3;
				}

				self.text_ += precipitation_chance.format("%3d");
				self.text_ += "   ";
				self.icons_ += rain_icon;
				self.icons_ += Font.ICON_EMPTY;
			}

			var uv_icon = Font.ICON_EMPTY;

			if (weather.uvIndex != null) {
				var uv_index = weather.uvIndex as Lang.Float;
				if (uv_index == 0) {
					uv_icon = Font.ICON_UV_0;
				} else if (uv_index <= 2) {
					uv_icon = Font.ICON_UV_1;
				} else if (uv_index <= 7) {
					uv_icon = Font.ICON_UV_2;
				} else if (uv_index <= 10) {
					uv_icon = Font.ICON_UV_3;
				} else {
					uv_icon = Font.ICON_UV_4;
				}

				self.text_ += uv_index.format("%3d");
				self.text_ += "   ";
				self.icons_ += uv_icon;
				self.icons_ += Font.ICON_EMPTY;
			}

			var wind_icon = Font.ICON_EMPTY;

			if (weather.windBearing != null) {
				var wind_bearing = weather.windBearing as Lang.Number;
				if (wind_bearing < 0 + 22.5) {
					wind_icon = Font.ICON_WIND_N_0;
				} else if (wind_bearing < 45 + 22.5) {
					wind_icon = Font.ICON_WIND_NE_0;
				} else if (wind_bearing < 90 + 22.5) {
					wind_icon = Font.ICON_WIND_E_0;
				} else if (wind_bearing < 135 + 22.5) {
					wind_icon = Font.ICON_WIND_SE_0;
				} else if (wind_bearing < 180 + 22.5) {
					wind_icon = Font.ICON_WIND_S_0;
				} else if (wind_bearing < 225 + 22.5) {
					wind_icon = Font.ICON_WIND_SW_0;
				} else if (wind_bearing < 270 + 22.5) {
					wind_icon = Font.ICON_WIND_W_0;
				} else if (wind_bearing < 315 + 22.5) {
					wind_icon = Font.ICON_WIND_NW_0;
				} else {
					wind_icon = Font.ICON_WIND_N_0;
				}

				if (weather.windSpeed != null) {
					var wind_speed = weather.windSpeed as Lang.Float;
					if (wind_speed <= 2) {
						wind_icon += 0;
					} else if (wind_speed <= 6) {
						wind_icon += 1;
					} else {
						wind_icon += 2;
					}

					self.text_ += wind_speed.format("%3d");
					self.text_ += "   ";
					self.icons_ += wind_icon;
					self.icons_ += Font.ICON_EMPTY;
				}
			}
		}
	}

	function render(_dc as Graphics.Dc) as Void {
		Render.icons(_dc, self.pos_x, self.pos_y, self.icons_, "");

		Render.textSmall(_dc, self.pos_x, self.pos_y, self.text_, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
	}
}

} // module Complication
