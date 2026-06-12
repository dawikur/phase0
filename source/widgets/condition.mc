// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Complications;
import Toybox.Graphics;
import Toybox.Lang;

module Widget {

class Condition extends Base {
	hidden var impl_ as Data.Base;
	hidden var small_ as Lang.Boolean;

	hidden var icon_ as Lang.String = "";
	hidden var text_ as Lang.String = "";

	function initialize(
		_dc as Graphics.Dc,
		_impl as Data.Base,
		_small as Lang.Boolean
	) {
		Base.initialize(_impl.type);

		self.impl_ = _impl;
		self.small_ = _small;

		self.resize(_dc);
	}

	function resize(_dc as Graphics.Dc) as Void {
		self.size_x =
			Render.iconsWidth(_dc, Fonts.ICON_EMPTY) +
			Render.numberWidth(_dc, 2, self.small_);
		self.size_y = Render.numberHeight(_dc, self.small_);

		if (self.impl_.name.length() != 0) {
			self.size_y += Render.labelHeight(_dc) + Render.SPACING;
		}
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
			self.icon_ = icon;
		} else {
			self.icon_ = "";
		}
	}

	function render(_dc as Graphics.Dc) as Void {
		// ---- prepare ----

		if (self.icon_.length() == 0 or self.text_.length() == 0) {
			self.refresh(_dc);
		}

		var pos_x = self.pos_x + self.size_x / 2;
		var pos_y = self.pos_y;

		// ---- label ----

		if (self.impl_.name.length() != 0) {
			Render.label(_dc, pos_x, pos_y, self.impl_.name, Graphics.TEXT_JUSTIFY_CENTER);
			pos_y += Render.labelHeight(_dc) + Render.SPACING;
		}

		var icon_size_2 = Render.iconsWidth(_dc, self.icon_) / 2;

		pos_y += icon_size_2;

		if (self.text_.length() != 0) {
			// ---- text ----

			Render.text(
				_dc, pos_x, pos_y, self.text_,
				Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER,
				self.small_
			);

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

} // module Widget
