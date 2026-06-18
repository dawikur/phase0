// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Complications;
import Toybox.Graphics;
import Toybox.Lang;

module Widgets {

class Text extends Base {
	hidden var small_ as Lang.Boolean = false;

	hidden var label_ as Lang.String = "";
	hidden var value_ as Lang.String = "";
	hidden var value_bg_ as Lang.String = "";
	hidden var justify_ as Lang.Number = Graphics.TEXT_JUSTIFY_LEFT;

	function initialize(_type as Complications.Type, _small as Lang.Boolean) {
		Base.initialize(_type);
		self.small_ = _small;
	}

	function width(_dc as Graphics.Dc) as Lang.Number {
		return Render.textWidth(_dc, self.value_, self.small_);
	}

	function height(_dc as Graphics.Dc) as Lang.Number {
		if (self.small_) {
			if (self.label_.length() == 0) {
				return Render.textHeight(_dc, true);
			}
			return Render.labelHeight(_dc) + Render.SPACING + Render.textHeight(_dc, true);
		}

		if (self.label_.length() == 0) {
			return Render.textHeight(_dc, false);
		}
		return Render.labelHeight(_dc) + Render.SPACING + Render.textHeight(_dc, false);
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

		var end_x = pos_x + self.size_x;
		var end_y = pos_y + self.size_y;

		return
			pos_x <= _x and _x <= end_x and
			pos_y <= _y and _y <= end_y;
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
			pos_y += Render.labelHeight(_dc) + Render.SPACING;
		}

		// ---- value ----

		if (self.value_.length() != 0) {
			Render.text(_dc, pos_x, pos_y, self.value_, self.justify_, self.small_);
		} else if (self.value_bg_.length() != 0) {
			Render.textBg(_dc, pos_x, pos_y, self.value_bg_, self.justify_, self.small_);
		}
	}

	function getValue() as Lang.String {
		return "";
	}
}

} // module Widgets
