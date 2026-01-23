// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Lang;
import Toybox.Graphics;

module Element {

class Value {
	var label as Lang.String = "";

	var pos_x as Lang.Number = 0;
	var pos_y as Lang.Number = 0;

	var field_count as Lang.Number = 0;
	var field_width as Lang.Number = 0;
	var field_height as Lang.Number = 0;

	var label_height as Lang.Number = 0;
	var gauge_width as Lang.Number = 0;

	hidden var max_ as Lang.Number or Null = null;

	function initialize() {
	}

	function render(_dc as Graphics.Dc) as Void {
		var pos_x = self.pos_x;
		var pos_y = self.pos_y;

		_dc.setColor(0xAA5500, Graphics.COLOR_TRANSPARENT);
		Font.TYPEFACE_DOT.render(
			_dc,
			pos_x,
			pos_y,
			self.label,
			Font.STYLE_MICRO
		);

		pos_y += self.label_height;

		_dc.setColor(0x555555, Graphics.COLOR_TRANSPARENT);
		Font.TYPEFACE_DOT.render(
			_dc,
			pos_x,
			pos_y,
			self.bg_(),
			Font.STYLE_SMALL
		);

		// ---- value ----

		var value = self.get_();
		if (value == null) {
			return;
		}

		// TODO: handle values which will not fit
		var str = value.toString();

		pos_x += (self.field_count - str.length()) * self.field_width;

		_dc.setColor(0xAAAAAA, Graphics.COLOR_TRANSPARENT);
		Font.TYPEFACE_DOT.render(
			_dc,
			pos_x,
			pos_y,
			str,
			Font.STYLE_SMALL
		);

		pos_x += str.length() * self.field_width;

		// ---- gauge ----

		if (self.max_ == null) {
			return;
		}

		var gauge_height = 0;

		if (value < self.max_) {
			_dc.setColor(0x555555, Graphics.COLOR_TRANSPARENT);

			gauge_height = ((value.toFloat() / self.max_) * self.field_height).toNumber();
		} else {
			_dc.setColor(0xAA5500, Graphics.COLOR_TRANSPARENT);

			gauge_height = self.field_height;
		}

		if (0 < gauge_height) {
			_dc.fillRectangle(
				pos_x,
				pos_y + self.field_height - gauge_height,
				self.gauge_width,
				gauge_height
			);
		}
	}

	function refresh() as Void {
		self.max_ = self.getMax_();
	}

	function get_() as Lang.Number or Null {
		return null;
	}

	function getMax_() as Lang.Number or Null {
		return null;
	}

	function bg_() as Lang.String {
		switch (self.field_count) {
			case 0: return "";
			case 1: return "█";
			case 2: return "██";
			case 3: return "███";
			case 4: return "████";
			case 5: return "█████";
			default: return Utils.repeatStr("█", self.field_count);
		}
	}
}

} // module Element
