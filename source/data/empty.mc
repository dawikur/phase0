// Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

module Data {
	(:data_icon,:data_status)
	class Empty extends Base {
		function initialize() {
			Base.initialize(
				null,
				Resources.get(Rez.Strings.LABEL_EMPTY),
				RefreshRate.NONE
			);
			self.icon = Fonts.ICON_EMPTY;
		}
	}
} // module Data
