// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Complications;
import Toybox.Graphics;
import Toybox.Lang;

module Complication {

class Condition extends Base {
	hidden var spacing_ as Lang.Number = Render.SPACING;

	hidden var impl_ as Data.Base;

	hidden var icon_ as Lang.String = "";
	hidden var text_ as Lang.String = "";

	function initialize(_impl as Data.Base) {
		Base.initialize(_impl.type);

		self.impl_ = _impl;
	}

	function refresh(_dc as Graphics.Dc) as Void {
		self.impl_.refresh();

		var value = self.impl_.value;
		if (value != null) {
			self.text_ = value.format("%d");
		} else {
			self.text_ = "";
		}

		var icon = self.impl_.icon;
		if (icon != null) {
			self.icon_ = "" + icon;
		} else {
			self.icon_ = "";
		}
	}

	function render(_dc as Graphics.Dc) as Void {
		// ---- prepare ----

		if (self.icon_.length() == 0 or self.text_.length() == 0) {
			self.refresh(_dc);
		}

		var icon_size_2 = Render.iconsWidth(_dc, self.icon_) / 2;

		var pos_x = self.pos_x + self.size_x / 2;
		var pos_y = self.pos_y;

		// ---- label ----

		if (self.impl_.name.length() != 0) {
			Render.label(_dc, pos_x, pos_y, self.impl_.name, Graphics.TEXT_JUSTIFY_CENTER);
			pos_y += Render.labelHeight(_dc) + self.spacing_;
		}

		pos_y += icon_size_2;

		if (self.text_.length() != 0) {
			// ---- text ----
			Render.textSmall(_dc, pos_x, pos_y, self.text_, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

			// ---- icon ----
			pos_x -= icon_size_2;
			Render.icons(_dc, pos_x, pos_y, self.icon_, self.icon_);
		} else {
			// ---- icon ----
			pos_x -= icon_size_2;
			Render.icons(_dc, pos_x, pos_y, "", self.icon_);
		}
	}
}

} // module Complication
