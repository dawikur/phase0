// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;

module Complication {

class Gauge {
	hidden var impl_ as Data.Base;

	hidden var value_ as Lang.Float or Null = null;

	function initialize(_impl as Data.Base) {
		self.impl_ = _impl;
	}

	function refresh() as Void {
		self.value_ = self.getValue();
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
				self.impl_.category
			);
		}
	}

	function getValue() as Lang.Float or Null {
		var value = self.impl_.get();
		if (value == null) {
			return null;
		}

		var value_max = self.impl_.getMax();
		if (value_max == null) {
			return null;
		}
		if (value_max == 0) {
			return null;
		}

		return value.toFloat() / value_max;
	}
}

class Gauges extends Base {
	hidden var data_ as Lang.Array<Gauge> = [];

	function initialize() {
		Base.initialize(Complications.COMPLICATION_TYPE_INVALID);
	}

	function add(_gauge as Gauge) as Void {
		self.data_.add(_gauge);
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
