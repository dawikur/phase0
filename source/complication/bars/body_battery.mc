// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

module Complication {

class BarBodyBattery extends Bar {
	function initialize() {
		Bar.initialize();

		self.name_ = "bar_body_battery";
		self.color_ = Render.COLOR_CYAN;
		self.impl_ = new BodyBattery();
	}
}

} // module Complication
