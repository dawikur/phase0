// Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

module Data {
	class Empty extends Base {
		function initialize() {
			Base.initialize(null, Resources.get(Rez.Strings.LABEL_EMPTY), RefreshRate.NONE);
		}
	}
} // module Data
