// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.ActivityMonitor;
import Toybox.Complications;
import Toybox.Lang;

module Data {
	class Base {
		var type as Complications.Type?;
		var name as Lang.String;

		var icon as Lang.String? = null;
		var value as Lang.Number? = null;
		var value_max as Lang.Number? = null;

		function initialize(
			_type as Complications.Type?,
			_name as Lang.String
		) {
			self.type = _type;
			self.name = _name;
		}

		function refresh() as Void {
			self.value = self.get_();
		}

		function get_() as Lang.Number? {
			return null;
		}

		static function Complication(
			_name as Lang.Symbol
		) as Complications.Type? {
			if (!(Toybox has :Complications)) {
				return null;
			}

			switch (_name) {
				case :active_minutes_per_week:
					return Complications.COMPLICATION_TYPE_INTENSITY_MINUTES;
				case :altitude:
					return Complications.COMPLICATION_TYPE_ALTITUDE;
				case :battery:
					return Complications.COMPLICATION_TYPE_BATTERY;
				case :body_battery:
					return Complications.COMPLICATION_TYPE_BODY_BATTERY;
				case :calories:
					return Complications.COMPLICATION_TYPE_CALORIES;
				case :floors_climbed:
					return Complications.COMPLICATION_TYPE_FLOORS_CLIMBED;
				case :heart_rate:
					return Complications.COMPLICATION_TYPE_HEART_RATE;
				case :pressure:
					return Complications.COMPLICATION_TYPE_SEA_LEVEL_PRESSURE;
				case :pushes:
					return Complications.COMPLICATION_TYPE_WHEELCHAIR_PUSHES;
				case :recovery_time:
					return Complications.COMPLICATION_TYPE_RECOVERY_TIME;
				case :respiration_rate:
					return Complications.COMPLICATION_TYPE_RESPIRATION_RATE;
				case :saturation:
					return Complications.COMPLICATION_TYPE_PULSE_OX;
				case :solar_intensity:
					return Complications.COMPLICATION_TYPE_SOLAR_INPUT;
				case :steps:
					return Complications.COMPLICATION_TYPE_STEPS;
				case :stress:
					return Complications.COMPLICATION_TYPE_STRESS;
				case :temperature:
					return Complications.COMPLICATION_TYPE_CURRENT_TEMPERATURE;
				case :vo2_bike:
					return Complications.COMPLICATION_TYPE_VO2MAX_BIKE;
				case :vo2_run:
					return Complications.COMPLICATION_TYPE_VO2MAX_RUN;
			}

			return null;
		}
	}
} // module Data
