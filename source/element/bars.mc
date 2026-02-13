// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;

module Element {

class Bars {
	var pos_x as Lang.Number = 0;
	var pos_y as Lang.Number = 0;

	var size_x as Lang.Number = 0;
	var size_y as Lang.Number = 0;

	hidden var body_battery_ as Lang.Float or Null = null;
	hidden var stress_ as Lang.Float or Null = null;
	hidden var move_ as Lang.Float or Null = null;

	function initialize() {
	}

	function render(_dc as Graphics.Dc) as Void {
		var pos_x = self.pos_x;
		var pos_y = self.pos_y;
		var size_y = self.size_y;

		var spacing = self.size_x / 3;

		if (self.body_battery_ != null) {
			Render.gaugeColor(
				_dc,
				pos_x,
				pos_y,
				self.body_battery_,
				size_y,
				Render.GAUGE_BOTTOM,
				0x005555
			);
		}

		pos_x += spacing;

		if (self.stress_ != null) {
			Render.gaugeColor(
				_dc,
				pos_x,
				pos_y,
				self.stress_,
				size_y,
				Render.GAUGE_BOTTOM,
				0x555500
			);
		}

		pos_x += spacing;

		if (self.move_ != null) {
			Render.gaugeColor(
				_dc,
				pos_x,
				pos_y,
				self.move_,
				size_y,
				Render.GAUGE_BOTTOM,
				0xAA0000
			);
		}
	}

	function refresh(_dc as Graphics.Dc) as Void {
		var activity_monitor = ActivityMonitor.getInfo();

		// body battery

		var body_battery_maybe = null;

		var body_battery_iterator = Toybox.SensorHistory.getBodyBatteryHistory({:period => 1});
		if (body_battery_iterator != null) {
			var body_battery_value = body_battery_iterator.next();

			if (body_battery_value != null) {
				body_battery_maybe = body_battery_value.data as Lang.Number;
			}
		}

		if (body_battery_maybe != null) {
			Cache.setValue("body_battery", body_battery_maybe as Lang.Number);
		} else {
			body_battery_maybe = Cache.getValue("body_battery", 1);
		}

		if (body_battery_maybe != null) {
			self.body_battery_ = (body_battery_maybe as Lang.Number).toFloat() / 100;
		} else {
			self.body_battery_ = null;
		}

		// stress

		var stress_maybe = activity_monitor.stressScore;

		if (stress_maybe != null) {
			Cache.setValue("stress", stress_maybe as Lang.Number);
		} else {
			stress_maybe = Cache.getValue("stress", 1);
		}

		if (stress_maybe != null) {
			self.stress_ = (stress_maybe as Lang.Number).toFloat() / 100;
		} else {
			self.stress_ = null;
		}

		// move bar

		var move_bar_maybe = null;

		if (activity_monitor.moveBarLevel != null) {
			move_bar_maybe = activity_monitor.moveBarLevel as Lang.Number;
		}

		if (move_bar_maybe != null) {
			Cache.setValue("move_bar", move_bar_maybe as Lang.Number);
		} else {
			move_bar_maybe = Cache.getValue("move_bar", 1);
		}

		if (move_bar_maybe != null) {
			self.move_ = (move_bar_maybe as Lang.Number).toFloat() / 5;
		} else {
			self.move_ = null;
		}
	}
}

} // module Element
