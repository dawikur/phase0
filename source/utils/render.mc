// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

module Render {
	const COLOR_NONE as Lang.Number = -1;

	const COLOR_BLACK as Lang.Number = 0x000000;
	const COLOR_CHARCOAL as Lang.Number = 0x555555; // Background
	const COLOR_SILVER as Lang.Number = 0xaaaaaa;
	const COLOR_WHITE as Lang.Number = 0xffffff; // Foreground

	const COLOR_RED as Lang.Number = 0xaa0000; // Physiological Intensity
	const COLOR_GREEN as Lang.Number = 0x00aa00; // Movement / Activity
	const COLOR_BLUE as Lang.Number = 0x0000aa; // System Resources

	const COLOR_CYAN as Lang.Number = 0x00aaaa; // Recovery / Balance
	const COLOR_MAGENTA as Lang.Number = 0xaa00aa; // Vertical Dimension
	const COLOR_YELLOW as Lang.Number = 0xaaaa00; // Tension / Metabolic Energy

	const COLOR_ORANGE as Lang.Number = 0xaa5500; // Weather / UI Accent
	const COLOR_PINK as Lang.Number = 0xaa0055;
	const COLOR_LIME as Lang.Number = 0x55aa00;
	const COLOR_TEAL as Lang.Number = 0x00aa55;
	const COLOR_INDIGO as Lang.Number = 0x5500aa;
	const COLOR_SKY_BLUE as Lang.Number = 0x0055aa;

	const COLOR_LIGHT_RED as Lang.Number = 0xff5555;
	const COLOR_LIGHT_GREEN as Lang.Number = 0x55ff55;
	const COLOR_LIGHT_BLUE as Lang.Number = 0x5555ff;

	const COLOR_LIGHT_CYAN as Lang.Number = 0x55ffff;
	const COLOR_LIGHT_MAGENTA as Lang.Number = 0xff55ff;
	const COLOR_LIGHT_YELLOW as Lang.Number = 0xffff55;

	const COLOR_LIGHT_ORANGE as Lang.Number = 0xffaa00;
	const COLOR_LIGHT_PINK as Lang.Number = 0xff55aa;
	const COLOR_LIGHT_LIME as Lang.Number = 0xaaff00;
	const COLOR_LIGHT_TEAL as Lang.Number = 0x00ffaa;
	const COLOR_LIGHT_INDIGO as Lang.Number = 0xaa55ff;
	const COLOR_LIGHT_SKY_BLUE as Lang.Number = 0x55aaff;

	const SPACING as Lang.Number = Fonts.SPACING_SMALL;

	const FONT_ICONS as WatchUi.FontResource = Fonts.ICONS;

	const SIZE_SMALL as Lang.Boolean = true;
	const SIZE_REGULAR as Lang.Boolean = false;

	const JUSTIFY_LEFT as Lang.Number = Graphics.TEXT_JUSTIFY_LEFT;
	const JUSTIFY_CENTER as Lang.Number =
		Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
	const JUSTIFY_RIGHT as Lang.Number = Graphics.TEXT_JUSTIFY_RIGHT;

	function fontClockFg_(_small as Lang.Boolean) as WatchUi.FontResource {
		return _small ? Fonts.DIGITS_SMALL : Fonts.DIGITS_REGULAR;
	}

	function fontClockBg_(_small as Lang.Boolean) as WatchUi.FontResource {
		return _small ? Fonts.DIGITS_SMALL_THIN : Fonts.DIGITS_REGULAR_THIN;
	}

	function fontFg_(_small as Lang.Boolean) as WatchUi.FontResource {
		return _small ? Fonts.DOT_SMALL : Fonts.DOT_REGULAR;
	}

	function fontBg_(_small as Lang.Boolean) as WatchUi.FontResource {
		return _small ? Fonts.DOT_SMALL : Fonts.DOT_REGULAR_THIN;
	}

	function Clock(
		_dc as Graphics.Dc,
		_color as Lang.Number,
		_background as Lang.Number,
		_pos_x as Lang.Number,
		_pos_y as Lang.Number,
		_small as Lang.Boolean,
		_clock as Lang.String,
		_shade as Lang.String
	) as Void {
		if (_clock.length() != 0) {
			_dc.setColor(_color, Graphics.COLOR_TRANSPARENT);
			_dc.drawText(
				_pos_x,
				_pos_y,
				fontClockFg_(_small),
				_clock,
				Render.JUSTIFY_CENTER
			);
		}

		if (_shade.length() != 0) {
			_dc.setColor(_background, Graphics.COLOR_TRANSPARENT);
			_dc.drawText(
				_pos_x + 1,
				_pos_y + 1,
				fontClockBg_(_small),
				_shade,
				Render.JUSTIFY_CENTER
			);
		}
	}

	function ClockWidth(
		_dc as Graphics.Dc,
		_label as Lang.String,
		_small as Lang.Boolean
	) as Lang.Number {
		return _dc.getTextWidthInPixels(_label, fontClockFg_(_small));
	}

	function ClockHeight(
		_dc as Graphics.Dc,
		_small as Lang.Boolean
	) as Lang.Number {
		return _dc.getFontHeight(fontClockFg_(_small));
	}

	function Label(
		_dc as Graphics.Dc,
		_color as Lang.Number,
		_pos_x as Lang.Number,
		_pos_y as Lang.Number,
		_label as Lang.String,
		_justify as Lang.Number
	) as Void {
		_dc.setColor(_color, Graphics.COLOR_TRANSPARENT);
		_dc.drawText(_pos_x, _pos_y, Fonts.DOT_TINY, _label, _justify);
	}

	function LabelWidth(
		_dc as Graphics.Dc,
		_label as Lang.String
	) as Lang.Number {
		return _dc.getTextWidthInPixels(_label, Fonts.DOT_TINY);
	}

	function LabelHeight(_dc as Graphics.Dc) as Lang.Number {
		return _dc.getFontHeight(Fonts.DOT_TINY);
	}

	function Text(
		_dc as Graphics.Dc,
		_pos_x as Lang.Number,
		_pos_y as Lang.Number,
		_small as Lang.Boolean,
		_text as Lang.String,
		_justify as Lang.Number
	) as Void {
		TextColor(_dc, COLOR_WHITE, _pos_x, _pos_y, _small, _text, _justify);
	}

	function TextColor(
		_dc as Graphics.Dc,
		_color as Lang.Number,
		_pos_x as Lang.Number,
		_pos_y as Lang.Number,
		_small as Lang.Boolean,
		_text as Lang.String,
		_justify as Lang.Number
	) as Void {
		if (_text.length() != 0) {
			_dc.setColor(_color, Graphics.COLOR_TRANSPARENT);
			_dc.drawText(_pos_x, _pos_y, fontFg_(_small), _text, _justify);
			_dc.setColor(COLOR_CHARCOAL, Graphics.COLOR_TRANSPARENT);
			_dc.drawText(
				_pos_x + 1,
				_pos_y + 1,
				fontBg_(_small),
				_text,
				_justify
			);
		}
	}

	function TextWidth(
		_dc as Graphics.Dc,
		_text as Lang.String,
		_small as Lang.Boolean
	) as Lang.Number {
		return _dc.getTextWidthInPixels(_text, fontFg_(_small));
	}

	function TextHeight(
		_dc as Graphics.Dc,
		_small as Lang.Boolean
	) as Lang.Number {
		return _dc.getFontHeight(fontFg_(_small));
	}

	function numberBg_(_width as Lang.Number) as Lang.String {
		switch (_width) {
			case 0:
				return "";
			case 1:
				return "0";
			case 2:
				return "00";
			case 3:
				return "000";
			case 4:
				return "0000";
			case 5:
				return "00000";
			case 6:
				return "000000";
			case 7:
				return "0000000";
			default: {
				var result = "0000000";
				for (var i = 7; i < _width; ++i) {
					result += "0";
				}
				return result;
			}
		}
	}

	function Number(
		_dc as Graphics.Dc,
		_pos_x as Lang.Number,
		_pos_y as Lang.Number,
		_number as Lang.Number?,
		_width as Lang.Number,
		_small as Lang.Boolean
	) as Void {
		var fg = NumberFormat(_width, _number);
		var bg = numberBg_(_width - fg.length());

		// padding
		var font_shade = fontBg_(_small);
		_dc.setColor(COLOR_CHARCOAL, Graphics.COLOR_TRANSPARENT);
		_dc.drawText(_pos_x, _pos_y, font_shade, bg, JUSTIFY_LEFT);

		Text(
			_dc,
			_pos_x + _dc.getTextWidthInPixels(bg, font_shade),
			_pos_y,
			_small,
			fg,
			JUSTIFY_LEFT
		);
	}

	function NumberWidth(
		_dc as Graphics.Dc,
		_width as Lang.Number,
		_small as Lang.Boolean
	) as Lang.Number {
		return _dc.getTextWidthInPixels(numberBg_(_width), fontFg_(_small));
	}

	function NumberHeight(
		_dc as Graphics.Dc,
		_small as Lang.Boolean
	) as Lang.Number {
		return _dc.getFontHeight(fontFg_(_small));
	}

	function NumberFormat(
		_width as Lang.Number,
		_number as Lang.Number?
	) as Lang.String {
		if (_number == null) {
			return "";
		}

		var str = _number.format("%d");
		if (str.length() <= _width) {
			return str;
		}

		var suffixes = ["k", "M", "G", "T", "P", "E", "Z", "Y"];
		var suffixes_size = suffixes.size();

		var value = _number.toFloat();
		for (var i = 0; i < suffixes_size; ++i) {
			value /= 1000;

			var suffix = suffixes[i];

			str = value.format("%.1f") + suffix;
			if (str.length() <= _width) {
				return str;
			}

			if (str.find("0") == 0) {
				str = str.substring(1, null) as Lang.String;
				if (str.length() <= _width) {
					return str;
				}
			}

			str = value.format("%d") + suffix;
			if (str.length() <= _width) {
				return str;
			}
		}

		return "";
	}

	const GAUGE_TOP as Lang.Boolean = false;
	const GAUGE_BOTTOM as Lang.Boolean = true;

	function Gauge(
		_dc as Graphics.Dc,
		_pos_x as Lang.Number,
		_pos_y as Lang.Number,
		_height as Lang.Number,
		_value as Lang.Float
	) as Void {
		GaugeColor(
			_dc,
			_value == 1.0 ? Render.COLOR_ORANGE : Render.COLOR_WHITE,
			_pos_x,
			_pos_y,
			_height,
			_value
		);
	}

	function GaugeColor(
		_dc as Graphics.Dc,
		_color as Lang.Number,
		_pos_x as Lang.Number,
		_pos_y as Lang.Number,
		_height as Lang.Number,
		_value as Lang.Float
	) as Void {
		_dc.setColor(_color, Graphics.COLOR_TRANSPARENT);

		if (_value <= 0.0) {
		} else if (_value < 1.0) {
			var height = (_value * _height).toNumber();

			_dc.fillRectangle(
				_pos_x,
				_pos_y + _height - height,
				SPACING,
				height
			);
		} else {
			// == 1.0
			_dc.fillRectangle(_pos_x, _pos_y, SPACING, _height);
		}

		_dc.setColor(COLOR_CHARCOAL, Graphics.COLOR_TRANSPARENT);
		for (var i = 0; i < _height; i += 2 * SPACING) {
			_dc.fillRectangle(_pos_x, _pos_y + i, 1, 1);
		}
	}

	function Icons(
		_dc as Graphics.Dc,
		_pos_x as Lang.Number,
		_pos_y as Lang.Number,
		_icons as Lang.String,
		_shade as Lang.String,
		_justify as Lang.Number
	) as Void {
		IconsColor(_dc, COLOR_WHITE, _pos_x, _pos_y, _icons, _shade, _justify);
	}

	function IconsColor(
		_dc as Graphics.Dc,
		_color as Lang.Number,
		_pos_x as Lang.Number,
		_pos_y as Lang.Number,
		_icons as Lang.String,
		_shade as Lang.String,
		_justify as Lang.Number
	) as Void {
		if (_icons.length() != 0) {
			_dc.setColor(_color, Graphics.COLOR_TRANSPARENT);
			_dc.drawText(_pos_x, _pos_y, FONT_ICONS, _icons, _justify);
		}

		if (_shade.length() != 0) {
			_dc.setColor(COLOR_CHARCOAL, Graphics.COLOR_TRANSPARENT);
			_dc.drawText(_pos_x + 1, _pos_y + 1, FONT_ICONS, _shade, _justify);
		}
	}

	function IconsWidth(
		_dc as Graphics.Dc,
		_icons as Lang.String
	) as Lang.Number {
		return _dc.getTextWidthInPixels(_icons, FONT_ICONS);
	}
} // module Render
