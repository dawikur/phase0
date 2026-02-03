// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

module Value {

class Base {
	var pos_x as Lang.Number = 0;
	var pos_y as Lang.Number = 0;

	var spacing as Lang.Number = 0;

	hidden var count_ as Lang.Number = 3;

	hidden var header_ as Lang.String or Null = null;
	hidden var header_style_ as Label.Style;

	hidden var fg_style_ as Label.Style;
	hidden var bg_style_ as Label.Style or Null;

	hidden var gauge_color_ as Lang.Number;
	hidden var gauge_max_color_ as Lang.Number;

	hidden var max_value_ as Lang.Number or Null = null;

	function initialize(_small as Lang.Boolean) {
		self.header_style_ = new Label.Style(Font.DOT_TINY, 0xFFAA00);

		if (_small) {
			self.fg_style_ = new Label.Style(Font.DOT_SMALL, 0xFFFFFF);
			self.bg_style_ = null;
		} else {
			self.fg_style_ = new Label.Style(Font.DOT_REGULAR, 0xAAAAAA);
			self.bg_style_ = new Label.Style(Font.DOT_REGULAR_THIN, 0x555555);
		}

		self.gauge_color_ = 0x555555;
		self.gauge_max_color_ = 0xAA5500;
	}

	function width(_dc as Graphics.Dc) as Lang.Number {
		return self.count_ *_dc.getTextWidthInPixels("8", self.fg_style_.font) + 3 * self.spacing;
	}

	function height(_dc as Graphics.Dc) as Lang.Number {
		if (self.header_ != null) {
			return _dc.getFontHeight(self.header_style_.font) + self.spacing + _dc.getFontHeight(self.fg_style_.font);
		}
		return _dc.getFontHeight(self.fg_style_.font);
	}

	function render(_dc as Graphics.Dc) as Void {
		var pos_x = self.pos_x;
		var pos_y = self.pos_y;

		// ---- header ----

		if (self.header_ != null) {
			self.header_style_.draw(_dc, pos_x, pos_y, self.header_, Graphics.TEXT_JUSTIFY_LEFT);

			pos_y += _dc.getFontHeight(self.header_style_.font) + self.spacing;
		}

		// ---- value ----

		var bg = self.getBg_();
		var bg_size = _dc.getTextDimensions(bg, self.fg_style_.font);
		pos_x += bg_size[0];

		var value = self.getValue_();
		if (value == null) {
			if (self.bg_style_ != null) {
				self.bg_style_.draw(_dc, pos_x, pos_y, bg, Graphics.TEXT_JUSTIFY_RIGHT);
			}

			return;
		}

		var str = self.formatValue_(value.toFloat());
		self.fg_style_.draw(_dc, pos_x, pos_y, str, Graphics.TEXT_JUSTIFY_RIGHT);

		if (self.bg_style_ != null) {
			self.bg_style_.draw(_dc, pos_x, pos_y, bg, Graphics.TEXT_JUSTIFY_RIGHT);
		}

		// ---- gauge ----

		if (self.max_value_ == null) {
			return;
		}

		var gauge_height = 0;

		if (value < self.max_value_) {
			_dc.setColor(self.gauge_color_, Graphics.COLOR_TRANSPARENT);

			gauge_height = ((value.toFloat() / self.max_value_) * bg_size[1]).toNumber();
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

	function getValue_() as Lang.Number or Null {
		return null;
	}

	function refresh(_dc as Graphics.Dc) as Void {
	}

	function getBg_() as Lang.String {
		switch (self.count_) {
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
				for (var i = 7; i < self.count_; ++i) {
					result += "█";
				}
				return result;
			}
		}
	}

	function formatValue_(_value as Lang.Float) as Lang.String {
		var str = _value.format("%d");
		if (str.length() <= self.count_) {
			return str;
		}

		var suffixes = ["k", "M", "G", "T", "P", "E", "Z", "Y"];
		var suffixes_size = suffixes.size();
		for (var i = 0; i < suffixes_size; ++i) {
			_value /= 1000;

			var suffix = suffixes[i];

			str = _value.format("%.1f") + suffix;
			if (str.length() <= self.count_) {
				return str;
			}

			if (str.find("0") == 0) {
				str = str.substring(1, null) as Lang.String;
				if (str.length() <= self.count_) {
					return str;
				}
			}

			str = _value.format("%d") + suffix;
			if (str.length() <= self.count_) {
				return str;
			}
		}

		return "";
	}
}

} // module Value
