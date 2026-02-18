// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Complications;
import Toybox.Graphics;
import Toybox.Lang;

module Complication {

const TEXT_SMALL = true;
const TEXT_REGULAR = false;

class Text extends Base {
	var small as Lang.Boolean = false;

	hidden var spacing_ as Lang.Number = Render.SPACING;

	hidden var label_ as Lang.String = "";
	hidden var value_ as Lang.String = "";
	hidden var value_bg_ as Lang.String = "";
	hidden var justify_ as Lang.Number = Graphics.TEXT_JUSTIFY_LEFT;

	function initialize(_type as Complications.Type) {
		Base.initialize(_type);
	}

	function width(_dc as Graphics.Dc) as Lang.Number {
		if (self.small) {
			return Render.textSmallWidth(_dc, self.value_);
		}
		return Render.textWidth(_dc, self.value_);
	}

	function height(_dc as Graphics.Dc) as Lang.Number {
		if (self.small) {
			if (self.label_.length() == 0) {
				return Render.textSmallHeight(_dc);
			}
			return Render.labelHeight(_dc) + self.spacing_ + Render.textSmallHeight(_dc);
		}

		if (self.label_.length() == 0) {
			return Render.textHeight(_dc);
		}
		return Render.labelHeight(_dc) + self.spacing_ + Render.textHeight(_dc);
	}

	function contains(_x as Lang.Number, _y as Lang.Number) as Lang.Boolean {
		var pos_x = self.pos_x;
		var pos_y = self.pos_y;

		if (self.justify_ & Graphics.TEXT_JUSTIFY_LEFT) {
		} else if (self.justify_ & Graphics.TEXT_JUSTIFY_CENTER) {
			pos_x -= self.size_x / 2;
		} else if (self.justify_ & Graphics.TEXT_JUSTIFY_RIGHT) {
			pos_x -= self.size_x;
		}

		if (self.justify_ & Graphics.TEXT_JUSTIFY_VCENTER) {
			pos_y -= self.size_y / 2;
		}

		var end_x = self.pos_x + self.size_x;
		var end_y = self.pos_y + self.size_y;

		return
			pos_x <= _x && _x <= end_x &&
			pos_y <= _y && _y <= end_y;
	}


	function refresh(_dc as Graphics.Dc) as Void {
		self.value_ = self.getValue();
	}

	function render(_dc as Graphics.Dc) as Void {
		// ---- prepare ----

		if (self.value_.length() == 0) {
			self.refresh(_dc);
		}

		var pos_x = self.pos_x;
		var pos_y = self.pos_y;

		// ---- label ----

		if (self.label_.length() != 0) {
			Render.label(_dc, pos_x, pos_y, self.label_, self.justify_);
			pos_y += Render.labelHeight(_dc) + self.spacing_;
		}

		// ---- value ----

		if (self.value_.length() != 0) {
			if (self.small) {
				Render.textSmall(_dc, pos_x, pos_y, self.value_, self.justify_);
			} else {
				Render.text(_dc, pos_x, pos_y, self.value_, self.justify_);
			}
		} else if (self.value_bg_.length() != 0) {
			if (self.small) {
				Render.textSmallBg(_dc, pos_x, pos_y, self.value_bg_, self.justify_);
			} else {
				Render.textBg(_dc, pos_x, pos_y, self.value_bg_, self.justify_);
			}
		}
	}

	function getValue() as Lang.String {
		return "";
	}
}

} // module Complication
