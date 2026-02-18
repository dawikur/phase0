// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

module Complication {

class BarHeartRate extends Bar {
	function initialize() {
		Bar.initialize();

		self.color_ = Render.COLOR_RED;
		self.impl_ = new HeartRate();
	}
}

} // module Complication
