// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

module Complication {

class BarMemory extends Bar {
	function initialize() {
		Bar.initialize();

		self.color_ = Render.COLOR_BLUE;
		self.impl_ = new Memory();
	}
}

} // module Complication
