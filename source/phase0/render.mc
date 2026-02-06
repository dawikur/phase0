// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

module Render {

const COLOR_FG as Lang.Number = 0xFFFFFF;
const COLOR_BG as Lang.Number = 0x555555;
const COLOR_ACCENT as Lang.Number = 0xAA5500;

const FONT_FG as WatchUi.FontResource = Font.DOT_REGULAR;
const FONT_BG as WatchUi.FontResource = Font.DOT_REGULAR_THIN;

const FONT_SMALL as WatchUi.FontResource = Font.DOT_SMALL;
const FONT_TINY as WatchUi.FontResource = Font.DOT_TINY;

const SPACING as Lang.Number = Font.SPACING_SMALL;
const SPACING_SMALL as Lang.Number = Font.SPACING_TINY;

const ICONS_FG as WatchUi.FontResource = Font.ICONS_SMALL;
const ICONS_BG as WatchUi.FontResource = Font.ICONS_SMALL;

// ////////////////////////////////////////////////////////////////////////////
// Label

function label(
	_dc as Graphics.Dc,
	_pos_x as Lang.Number,
	_pos_y as Lang.Number,
	_label as Lang.String,
	_justify as Lang.Number
) as Void {
	_dc.setColor(COLOR_ACCENT, Graphics.COLOR_TRANSPARENT);
	_dc.drawText(_pos_x, _pos_y, FONT_TINY, _label, _justify);
}

function labelHeight(_dc as Graphics.Dc) as Lang.Number {
	return _dc.getFontHeight(FONT_TINY);
}

// ////////////////////////////////////////////////////////////////////////////
// Text

// regular

function text(
	_dc as Graphics.Dc,
	_pos_x as Lang.Number,
	_pos_y as Lang.Number,
	_text as Lang.String,
	_justify as Lang.Number
) as Void {
	// text
	_dc.setColor(COLOR_FG, Graphics.COLOR_TRANSPARENT);
	_dc.drawText(_pos_x, _pos_y, FONT_FG, _text, _justify);

	// shade
	_dc.setColor(COLOR_BG, Graphics.COLOR_TRANSPARENT);
	_dc.drawText(_pos_x, _pos_y, FONT_BG, _text, _justify);
}

function textBg(
	_dc as Graphics.Dc,
	_pos_x as Lang.Number,
	_pos_y as Lang.Number,
	_text as Lang.String,
	_justify as Lang.Number
) as Void {
	_dc.setColor(COLOR_BG, Graphics.COLOR_TRANSPARENT);
	_dc.drawText(_pos_x, _pos_y, FONT_BG, _text, _justify);
}

// small

function textSmall(
	_dc as Graphics.Dc,
	_pos_x as Lang.Number,
	_pos_y as Lang.Number,
	_text as Lang.String,
	_justify as Lang.Number
) as Void {
	// text
	_dc.setColor(COLOR_FG, Graphics.COLOR_TRANSPARENT);
	_dc.drawText(_pos_x, _pos_y, FONT_SMALL, _text, _justify);

	// shade
	_dc.setColor(COLOR_BG, Graphics.COLOR_TRANSPARENT);
	_dc.drawText(_pos_x +1, _pos_y +1, FONT_SMALL, _text, _justify);
}

function textSmallHeight(_dc as Graphics.Dc) as Lang.Number {
	return _dc.getFontHeight(FONT_SMALL);
}

// ////////////////////////////////////////////////////////////////////////////
// Number

// regular

function number(
	_dc as Graphics.Dc,
	_pos_x as Lang.Number,
	_pos_y as Lang.Number,
	_number as Lang.Number or Null,
	_size as Lang.Number
) as Void {
	if (_number == null) {
		var bg = numberBg(_size);

		_dc.setColor(COLOR_BG, Graphics.COLOR_TRANSPARENT);
		_dc.drawText(_pos_x, _pos_y, FONT_BG, bg, Graphics.TEXT_JUSTIFY_LEFT);

		return;
	}

	var str = numberFormat(_size, _number);
	var bg = numberBg(_size - str.length());

	// padding
	_dc.setColor(COLOR_BG, Graphics.COLOR_TRANSPARENT);
	_dc.drawText(_pos_x, _pos_y, FONT_BG, bg, Graphics.TEXT_JUSTIFY_LEFT);

	_pos_x += _dc.getTextWidthInPixels(bg, FONT_BG);

	// number
	_dc.setColor(COLOR_FG, Graphics.COLOR_TRANSPARENT);
	_dc.drawText(_pos_x, _pos_y, FONT_FG, str, Graphics.TEXT_JUSTIFY_LEFT);

	// shade
	_dc.setColor(COLOR_BG, Graphics.COLOR_TRANSPARENT);
	_dc.drawText(_pos_x, _pos_y, FONT_BG, str, Graphics.TEXT_JUSTIFY_LEFT);
}

function numberWidth(_dc as Graphics.Dc, _size as Lang.Number) as Lang.Number {
	return _dc.getTextWidthInPixels(numberBg(_size), FONT_FG);
}

function numberHeight(_dc as Graphics.Dc) as Lang.Number {
	return _dc.getFontHeight(FONT_FG);
}

// small

function numberSmall(
	_dc as Graphics.Dc,
	_pos_x as Lang.Number,
	_pos_y as Lang.Number,
	_number as Lang.Number or Null,
	_size as Lang.Number
) as Void {
	if (_number == null) {
		var bg = numberBg(_size);

		_dc.setColor(COLOR_BG, Graphics.COLOR_TRANSPARENT);
		_dc.drawText(_pos_x, _pos_y, FONT_SMALL, bg, Graphics.TEXT_JUSTIFY_LEFT);

		return;
	}

	var str = numberFormat(_size, _number);
	var bg = numberBg(_size - str.length());

	_dc.setColor(COLOR_BG, Graphics.COLOR_TRANSPARENT);
	_dc.drawText(_pos_x, _pos_y, FONT_SMALL, bg, Graphics.TEXT_JUSTIFY_LEFT);

	_pos_x += _dc.getTextWidthInPixels(bg, FONT_SMALL);

	_dc.setColor(COLOR_FG, Graphics.COLOR_TRANSPARENT);
	_dc.drawText(_pos_x, _pos_y, FONT_SMALL, str, Graphics.TEXT_JUSTIFY_LEFT);
}

function numberSmallWidth(_dc as Graphics.Dc, _size as Lang.Number) as Lang.Number {
	return _dc.getTextWidthInPixels(numberBg(_size), FONT_SMALL);
}

function numberSmallHeight(_dc as Graphics.Dc) as Lang.Number {
	return _dc.getFontHeight(FONT_SMALL);
}

// common

function numberBg(_size as Lang.Number) as Lang.String {
	switch (_size) {
		case 0: return "";
		case 1: return "0";
		case 2: return "00";
		case 3: return "000";
		case 4: return "0000";
		case 5: return "00000";
		case 6: return "000000";
		case 7: return "0000000";
		default: {
			var result = "0000000";
			for (var i = 7; i < _size; ++i) {
				result += "0";
			}
			return result;
		}
	}
}

function numberFormat(_size as Lang.Number, _number as Lang.Number) as Lang.String {
	var str = _number.format("%d");
	if (str.length() <= _size) {
		return str;
	}

	var suffixes = ["k", "M", "G", "T", "P", "E", "Z", "Y"];
	var suffixes_size = suffixes.size();

	var value = _number.toFloat();
	for (var i = 0; i < suffixes_size; ++i) {
		value /= 1000;

		var suffix = suffixes[i];

		str = value.format("%.1f") + suffix;
		if (str.length() <= _size) {
			return str;
		}

		if (str.find("0") == 0) {
			str = str.substring(1, null) as Lang.String;
			if (str.length() <= _size) {
				return str;
			}
		}

		str = value.format("%d") + suffix;
		if (str.length() <= _size) {
			return str;
		}
	}

	return "";
}

// ////////////////////////////////////////////////////////////////////////////
// Gauge

const GAUGE_TOP as Lang.Boolean = false;
const GAUGE_BOTTOM as Lang.Boolean = true;

function gauge(
	_dc as Graphics.Dc,
	_pos_x as Lang.Number,
	_pos_y as Lang.Number,
	_value as Lang.Float,
	_max_height as Lang.Number,
	_from_bottom as Lang.Boolean
) as Void {
	if (_value <= 0.0) {
	} else if (_value < 1.0) {
		var height = (_value * _max_height).toNumber();

		var top_spacing = (_from_bottom ? _max_height - height : 0);

		_dc.setColor(COLOR_FG, Graphics.COLOR_TRANSPARENT);
		_dc.fillRectangle(
			_pos_x,
			_pos_y + top_spacing,
			SPACING,
			height
		);
	} else { // == 1.0
		_dc.setColor(COLOR_ACCENT, Graphics.COLOR_TRANSPARENT);
		_dc.fillRectangle(
			_pos_x,
			_pos_y,
			SPACING,
			_max_height
		);
	}

	_dc.setColor(COLOR_BG, Graphics.COLOR_TRANSPARENT);
	for (var i = 0; i < _max_height; i += 2 * SPACING) {
		_dc.fillRectangle(
			_pos_x,
			_pos_y + i,
			1,
			1
		);
	}
}

function gaugeSmall(
	_dc as Graphics.Dc,
	_pos_x as Lang.Number,
	_pos_y as Lang.Number,
	_value as Lang.Float,
	_max_height as Lang.Number,
	_from_bottom as Lang.Boolean
) as Void {
	if (_value <= 0.0) {
	} else if (_value < 1.0) {
		var height = (_value * _max_height).toNumber();

		var top_spacing = (_from_bottom ? _max_height - height : 0);

		_dc.setColor(COLOR_FG, Graphics.COLOR_TRANSPARENT);
		_dc.fillRectangle(
			_pos_x,
			_pos_y + top_spacing,
			SPACING_SMALL,
			height
		);
	} else { // == 1.0
		_dc.setColor(COLOR_ACCENT, Graphics.COLOR_TRANSPARENT);
		_dc.fillRectangle(
			_pos_x,
			_pos_y,
			SPACING_SMALL,
			_max_height
		);
	}

	_dc.setColor(COLOR_BG, Graphics.COLOR_TRANSPARENT);
	for (var i = 0; i < _max_height; i += 2 * SPACING_SMALL) {
		_dc.fillRectangle(
			_pos_x,
			_pos_y + i,
			1,
			1
		);
	}
}

// ////////////////////////////////////////////////////////////////////////////
// Icons

function icons(
	_dc as Graphics.Dc,
	_pos_x as Lang.Number,
	_pos_y as Lang.Number,
	_fg as Lang.String,
	_bg as Lang.String
) as Void {
	var justify = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;

	// bg
	if (_bg.length() != 0) {
		_dc.setColor(COLOR_BG, Graphics.COLOR_TRANSPARENT);
		_dc.drawText(_pos_x, _pos_y, ICONS_BG, _bg, justify);
	}

	// fg
	_dc.setColor(COLOR_FG, Graphics.COLOR_TRANSPARENT);
	_dc.drawText(_pos_x, _pos_y, ICONS_FG, _fg, justify);

	// shade
	_dc.setColor(COLOR_BG, Graphics.COLOR_TRANSPARENT);
	_dc.drawText(_pos_x +1, _pos_y +1, ICONS_BG, _fg, justify);
}

function iconsWidth(_dc as Graphics.Dc, _icons as Lang.String) as Lang.Number {
	return _dc.getTextWidthInPixels(_icons, ICONS_FG);
}

} // module Render
