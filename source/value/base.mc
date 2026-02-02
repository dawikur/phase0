// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

module Value {

class Base {
	var label as Lang.String = "";

	var pos_x as Lang.Number = 0;
	var pos_y as Lang.Number = 0;

	var count as Lang.Number = 0;

	var spacing as Lang.Number = 0;

	hidden var label_font_ as WatchUi.FontResource;
	hidden var label_color_ as Lang.Number;

	hidden var bg_font_ as WatchUi.FontResource;
	hidden var bg_color_ as Lang.Number;

	hidden var value_font_ as WatchUi.FontResource;
	hidden var value_color_ as Lang.Number;

	hidden var gauge_color_ as Lang.Number;
	hidden var gauge_max_color_ as Lang.Number;

	hidden var max_ as Lang.Number or Null = null;

	function initialize() {
		self.label_font_ = Font.DOT_TINY;
		self.label_color_ = 0xAA5500;

		self.bg_font_ = Font.DOT_SMALL;
		self.bg_color_ = 0x555555;

		self.value_font_ = Font.DOT_SMALL;
		self.value_color_ = 0xAAAAAA;

		self.gauge_color_ = 0x555555;
		self.gauge_max_color_ = 0xAA5500;
	}

	function width(_dc as Graphics.Dc) as Lang.Number {
		return (self.count + 1) *_dc.getTextWidthInPixels("8", self.value_font_);
	}

	function render(_dc as Graphics.Dc) as Void {
		// ---- label ----

		var pos_x = self.pos_x;
		var pos_y = self.pos_y;

		_dc.setColor(self.label_color_, Graphics.COLOR_TRANSPARENT);
		_dc.drawText(pos_x, pos_y, self.label_font_, self.label, Graphics.TEXT_JUSTIFY_LEFT);

		pos_y += _dc.getFontHeight(self.label_font_) + self.spacing;

		// ---- value ----

		var bg = self.bg_();
		var bg_size = _dc.getTextDimensions(bg, self.value_font_);
		pos_x += bg_size[0];

		_dc.setColor(self.bg_color_, Graphics.COLOR_TRANSPARENT);
		_dc.drawText(pos_x, pos_y, self.bg_font_, bg, Graphics.TEXT_JUSTIFY_RIGHT);

		var value = self.get_();
		if (value == null) {
			return;
		}

		var str = self.formatValue_(value.toFloat());
		_dc.setColor(self.value_color_, Graphics.COLOR_TRANSPARENT);
		_dc.drawText(pos_x, pos_y, self.value_font_, str, Graphics.TEXT_JUSTIFY_RIGHT);

		// ---- gauge ----

		if (self.max_ == null) {
			return;
		}

		var gauge_height = 0;

		if (value < self.max_) {
			_dc.setColor(self.gauge_color_, Graphics.COLOR_TRANSPARENT);

			gauge_height = ((value.toFloat() / self.max_) * bg_size[1]).toNumber();
		} else {
			_dc.setColor(self.gauge_max_color_, Graphics.COLOR_TRANSPARENT);

			gauge_height = bg_size[1];
		}

		if (0 < gauge_height) {
			_dc.fillRectangle(
				pos_x + self.spacing,
				pos_y + bg_size[1] - gauge_height,
				self.spacing,
				gauge_height - self.spacing
			);
		}
	}

	function refresh(_dc as Graphics.Dc) as Void {
		self.max_ = self.getMax_();
	}

	function get_() as Lang.Number or Null {
		return null;
	}

	function getMax_() as Lang.Number or Null {
		return null;
	}

	function bg_() as Lang.String {
		switch (self.count) {
			case 0: return "";
			case 1: return "█";
			case 2: return "██";
			case 3: return "███";
			case 4: return "████";
			case 5: return "█████";
			case 6: return "██████";
			case 7: return "███████";
			default: {
				var result = "███████";
				for (var i = 7; i < self.count; ++i) {
					result += "█";
				}
				return result;
			}
		}
	}

	function formatValue_(_value as Lang.Float) as Lang.String {
		var str = _value.format("%d");
		if (str.length() <= self.count) {
			return str;
		}

		var suffixes = ["k", "M", "G", "T", "P", "E", "Z", "Y"];
		var suffixes_size = suffixes.size();
		for (var i = 0; i < suffixes_size; ++i) {
			_value /= 1000;

			var suffix = suffixes[i];

			str = _value.format("%.1f") + suffix;
			if (str.length() <= self.count) {
				return str;
			}

			if (str.find("0") == 0) {
				str = str.substring(1, null) as Lang.String;
				if (str.length() <= self.count) {
					return str;
				}
			}

			str = _value.format("%d") + suffix;
			if (str.length() <= self.count) {
				return str;
			}
		}

		return "";
	}
}

} // module Value
