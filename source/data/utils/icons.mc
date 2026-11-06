// Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

import Toybox.Lang;

module Data {
	(:memory_low)
	function temperatureIcon(_temperature_c as Lang.Number?) as Lang.String? {
		return null;
	}

	(:memory_not_low)
	function temperatureIcon(_temperature_c as Lang.Number?) as Lang.String? {
		if (_temperature_c == null) {
			return Fonts.ICON_NONE;
		}
		if (_temperature_c < -25) {
			return Fonts.ICON_TEMPERATURE_0;
		}
		if (_temperature_c < -15) {
			return Fonts.ICON_TEMPERATURE_1;
		}
		if (_temperature_c < -5) {
			return Fonts.ICON_TEMPERATURE_2;
		}
		if (_temperature_c < 5) {
			return Fonts.ICON_TEMPERATURE_3;
		}
		if (_temperature_c < 15) {
			return Fonts.ICON_TEMPERATURE_4;
		}
		if (_temperature_c < 25) {
			return Fonts.ICON_TEMPERATURE_5;
		}
		return Fonts.ICON_TEMPERATURE_6;
	}

	(:memory_low)
	function humidityIcon(_humidity as Lang.Number?) as Lang.String? {
		return null;
	}

	(:memory_not_low)
	function humidityIcon(_humidity as Lang.Number?) as Lang.String? {
		if (_humidity == null) {
			return Fonts.ICON_NONE;
		}
		if (_humidity < 25) {
			return Fonts.ICON_HUMIDITY_0;
		}
		if (_humidity < 30) {
			return Fonts.ICON_HUMIDITY_1;
		}
		if (_humidity < 60) {
			return Fonts.ICON_HUMIDITY_2;
		}
		if (_humidity < 70) {
			return Fonts.ICON_HUMIDITY_3;
		}
		return Fonts.ICON_HUMIDITY_4;
	}

	(:memory_low)
	function moveBarIcon(_level as Lang.Number?) as Lang.String? {
		return null;
	}

	(:memory_not_low)
	function moveBarIcon(_level as Lang.Number?) as Lang.String? {
		if (_level == null) {
			return Fonts.ICON_NONE;
		}
		switch (_level) {
			case 0:
				return Fonts.ICON_MOVE_BAR_0;
			case 1:
				return Fonts.ICON_MOVE_BAR_1;
			case 2:
				return Fonts.ICON_MOVE_BAR_2;
			case 3:
				return Fonts.ICON_MOVE_BAR_3;
			case 4:
				return Fonts.ICON_MOVE_BAR_4;
			case 5:
				return Fonts.ICON_MOVE_BAR_5;
		}
		return Fonts.ICON_NONE;
	}

	(:memory_low)
	function batteryIcon(_percentage as Lang.Number?) as Lang.String? {
		return null;
	}

	(:memory_not_low)
	function batteryIcon(_percentage as Lang.Number?) as Lang.String? {
		if (_percentage == null) {
			return Fonts.ICON_NONE;
		}
		if (_percentage < 10) {
			return Fonts.ICON_BATTERY_0;
		}
		if (_percentage < 37) {
			return Fonts.ICON_BATTERY_1;
		}
		if (_percentage < 64) {
			return Fonts.ICON_BATTERY_2;
		}
		if (_percentage <= 90) {
			return Fonts.ICON_BATTERY_3;
		}
		return Fonts.ICON_BATTERY_4;
	}

	(:memory_low)
	function solarIntensityIcon(_intensity as Lang.Number?) as Lang.String? {
		return null;
	}

	(:memory_not_low)
	function solarIntensityIcon(_intensity as Lang.Number?) as Lang.String? {
		if (_intensity == null or _intensity < 0) {
			return Fonts.ICON_NONE;
		}
		if (_intensity < 20) {
			return Fonts.ICON_SOLAR_0;
		}
		if (_intensity < 40) {
			return Fonts.ICON_SOLAR_1;
		}
		if (_intensity < 60) {
			return Fonts.ICON_SOLAR_2;
		}
		if (_intensity < 80) {
			return Fonts.ICON_SOLAR_3;
		}
		return Fonts.ICON_SOLAR_4;
	}

	(:memory_low)
	function rainIcon(_chance as Lang.Number?) as Lang.String? {
		return null;
	}

	(:memory_not_low)
	function rainIcon(_chance as Lang.Number?) as Lang.String? {
		if (_chance == null) {
			return Fonts.ICON_NONE;
		} else if (_chance <= 20) {
			return Fonts.ICON_RAIN_0;
		} else if (_chance <= 50) {
			return Fonts.ICON_RAIN_1;
		} else if (_chance <= 80) {
			return Fonts.ICON_RAIN_2;
		} else {
			return Fonts.ICON_RAIN_3;
		}
	}

	(:memory_low)
	function uvIcon(_index as Lang.Number?) as Lang.String? {
		return null;
	}

	(:memory_not_low)
	function uvIcon(_index as Lang.Number?) as Lang.String? {
		if (_index == null) {
			return Fonts.ICON_NONE;
		}

		if (_index < 2) {
			return Fonts.ICON_SOLAR_0;
		} else if (_index < 5) {
			return Fonts.ICON_SOLAR_1;
		} else if (_index < 7) {
			return Fonts.ICON_SOLAR_2;
		} else if (_index < 9) {
			return Fonts.ICON_SOLAR_3;
		} else {
			return Fonts.ICON_SOLAR_4;
		}
	}

	(:memory_low)
	function windIcon(
		_bearing as Lang.Number?,
		_speed as Lang.Number?
	) as Lang.String? {
		return null;
	}

	(:memory_not_low)
	function windIcon(
		_bearing as Lang.Number?,
		_speed as Lang.Number?
	) as Lang.String? {
		// Missing direction has no glyph to adjust for wind speed.
		if (_bearing == null) {
			return Fonts.ICON_NONE;
		}

		var icon = Fonts.ICON_WIND_N_0;
		if (_bearing < 0 + 22.5) {
			icon = Fonts.ICON_WIND_N_0;
		} else if (_bearing < 45 + 22.5) {
			icon = Fonts.ICON_WIND_NE_0;
		} else if (_bearing < 90 + 22.5) {
			icon = Fonts.ICON_WIND_E_0;
		} else if (_bearing < 135 + 22.5) {
			icon = Fonts.ICON_WIND_SE_0;
		} else if (_bearing < 180 + 22.5) {
			icon = Fonts.ICON_WIND_S_0;
		} else if (_bearing < 225 + 22.5) {
			icon = Fonts.ICON_WIND_SW_0;
		} else if (_bearing < 270 + 22.5) {
			icon = Fonts.ICON_WIND_W_0;
		} else if (_bearing < 315 + 22.5) {
			icon = Fonts.ICON_WIND_NW_0;
		} else {
			icon = Fonts.ICON_WIND_N_0;
		}
		if (_speed != null) {
			var direction = (icon as Lang.String).toCharArray()[0];
			if (2 < _speed) {
				if (_speed <= 6) {
					icon = (direction + 1).toString();
				} else {
					icon = (direction + 2).toString();
				}
			}
		}
		return icon;
	}
} // module Data
