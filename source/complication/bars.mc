// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.SensorHistory;

module Complication {

class Bar {
	hidden var name_ as Lang.String = "";
	hidden var color_ as Lang.Number = 0;
	hidden var impl_ as Metric or Null;

	hidden var value_ as Lang.Float or Null = null;

	function initialize() {
	}

	function refresh() as Void {
		var value_maybe = self.getValue();

		if (self.name_.length() != 0) {
			if (value_maybe != null) {
				Cache.setValue(self.name_, value_maybe as Lang.Float);
			} else {
				value_maybe = Cache.getValue(self.name_, 1);
			}
		}

		if (value_maybe != null) {
			self.value_ = value_maybe as Lang.Float;
		} else {
			self.value_ = null;
		}
	}

	function render(
		_dc as Graphics.Dc,
		_pos_x as Lang.Number,
		_pos_y as Lang.Number,
		_size_y as Lang.Number
	) as Void {
		if (self.value_ != null) {
			Render.gaugeColor(
				_dc,
				_pos_x,
				_pos_y,
				self.value_,
				_size_y,
				Render.GAUGE_BOTTOM,
				self.color_
			);
		}
	}

	function getValue() as Lang.Float or Null {
		if (self.impl_ == null) {
			return null;
		}

		var impl = self.impl_ as Metric;

		var value = impl.getValue();
		if (value == null) {
			return null;
		}

		var value_max = impl.getValueMax();
		if (value_max == null) {
			return null;
		}
		if (value_max == 0) {
			return null;
		}

		return value.toFloat() / value_max;
	}
}

class Bars extends Base {
	hidden var body_battery_ as Lang.Float or Null = null;
	hidden var stress_ as Lang.Float or Null = null;
	hidden var move_ as Lang.Float or Null = null;

	hidden var data_ as Lang.Array<Bar> = [];

	function initialize() {
		Base.initialize(Complications.COMPLICATION_TYPE_INVALID);
	}

	function add(_bar as Bar) as Void {
		self.data_.add(_bar);
	}

	function refresh(_dc as Graphics.Dc) as Void {
		var data_size = self.data_.size();
		for (var i = 0; i < data_size; ++i) {
			self.data_[i].refresh();
		}
	}

	function render(_dc as Graphics.Dc) as Void {
		var pos_x = self.pos_x;
		var pos_y = self.pos_y;
		var size_y = self.size_y;

		var data_size = self.data_.size();
		var spacing = self.size_x / data_size;

		for (var i = 0; i < data_size; ++i) {
			self.data_[i].render(_dc, pos_x, pos_y, size_y);
			pos_x += spacing;
		}
	}
}

} // module Complication
