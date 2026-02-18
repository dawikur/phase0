// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

module Complication {

class BarStress extends Bar {
	function initialize() {
		Bar.initialize();

		self.color_ = Render.COLOR_YELLOW;
		self.impl_ = new Stress();
	}
}

} // module Complication
