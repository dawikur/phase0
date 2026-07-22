// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

module Render {
	// Font

	const FONT_REGULAR =
		Application.loadResource(Rez.Fonts.DOT_REGULAR) as WatchUi.FontResource;
	const FONT_REGULAR_THIN =
		Application.loadResource(Rez.Fonts.DOT_REGULAR_THIN) as
		WatchUi.FontResource;
	const FONT_SMALL =
		Application.loadResource(Rez.Fonts.DOT_SMALL) as WatchUi.FontResource;
	const FONT_TINY =
		Application.loadResource(Rez.Fonts.DOT_TINY) as WatchUi.FontResource;

	// Icons

	const ICONS =
		Application.loadResource(Rez.Fonts.ICONS) as WatchUi.FontResource;

	// Settings

	const COLOR_NONE as Lang.Number = -1;

	const SPACING as Lang.Number = Fonts.SPACING_SMALL;
	const SHADOW_OFFSET as Lang.Number = 1;

	const SIZE_SMALL as Lang.Boolean = true;
	const SIZE_REGULAR as Lang.Boolean = false;

	const JUSTIFY_LEFT as Lang.Number = Graphics.TEXT_JUSTIFY_LEFT;
	const JUSTIFY_CENTER as Lang.Number =
		Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
	const JUSTIFY_RIGHT as Lang.Number = Graphics.TEXT_JUSTIFY_RIGHT;

	const TOP as Lang.Boolean = true;
	const BOTTOM as Lang.Boolean = false;

	const NUMBER_BACKGROUNDS as Lang.Array<Lang.String> = [
		"",
		"0",
		"00",
		"000",
		"0000",
		"00000",
		"000000",
		"0000000",
	];
	const NUMBER_SUFFIXES as Lang.Array<Lang.String> = [
		"k",
		"M",
		"G",
		"T",
		"P",
		"E",
		"Z",
		"Y",
	];

	var accent as Lang.Number = 0;
	var foreground as Lang.Number = 0;
	var shade as Lang.Number = 0;
	var background as Lang.Number = 0;

	function fontFg_(_is_small as Lang.Boolean) as WatchUi.FontResource {
		return _is_small ? FONT_SMALL : FONT_REGULAR;
	}

	function fontBg_(_is_small as Lang.Boolean) as WatchUi.FontResource {
		return _is_small ? FONT_SMALL : FONT_REGULAR_THIN;
	}

	function clear(_dc as Graphics.Dc) as Void {
		_dc.clearClip();
		_dc.setColor(
			Render.background,
			Render.background
		);
		_dc.clear();
	}

	function Clock(
		_dc as Graphics.Dc,
		_color as Lang.Number,
		_background as Lang.Number,
		_pos_x as Lang.Number,
		_pos_y as Lang.Number,
		_font_fg as WatchUi.FontResource,
		_font_bg as WatchUi.FontResource,
		_clock as Lang.String,
		_shade as Lang.String
	) as Void {
		if (_clock.length() != 0) {
			_dc.setColor(_color, Graphics.COLOR_TRANSPARENT);
			_dc.drawText(
				_pos_x,
				_pos_y,
				_font_fg,
				_clock,
				Render.JUSTIFY_CENTER
			);
		}

		if (_shade.length() != 0) {
			_dc.setColor(_background, Graphics.COLOR_TRANSPARENT);
			_dc.drawText(
				_pos_x + SHADOW_OFFSET,
				_pos_y + SHADOW_OFFSET,
				_font_bg,
				_shade,
				Render.JUSTIFY_CENTER
			);
		}
	}

	function ClockWidth(
		_dc as Graphics.Dc,
		_label as Lang.String,
		_font as WatchUi.FontResource
	) as Lang.Number {
		return (
			_dc.getTextWidthInPixels(_label, _font) +
			(_label.length() == 0 ? 0 : SHADOW_OFFSET)
		);
	}

	function ClockHeight(
		_dc as Graphics.Dc,
		_font as WatchUi.FontResource
	) as Lang.Number {
		return _dc.getFontHeight(_font) + SHADOW_OFFSET;
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
		_dc.drawText(_pos_x, _pos_y, FONT_TINY, _label, _justify);
	}

	function LabelWidth(
		_dc as Graphics.Dc,
		_label as Lang.String
	) as Lang.Number {
		return _dc.getTextWidthInPixels(_label, FONT_TINY);
	}

	function LabelHeight(_dc as Graphics.Dc) as Lang.Number {
		return _dc.getFontHeight(FONT_TINY);
	}

	function Text(
		_dc as Graphics.Dc,
		_color as Lang.Number,
		_pos_x as Lang.Number,
		_pos_y as Lang.Number,
		_is_small as Lang.Boolean,
		_text as Lang.String,
		_justify as Lang.Number
	) as Void {
		if (_text.length() != 0) {
			_dc.setColor(_color, Graphics.COLOR_TRANSPARENT);
			_dc.drawText(_pos_x, _pos_y, fontFg_(_is_small), _text, _justify);
			_dc.setColor(Render.shade, Graphics.COLOR_TRANSPARENT);
			_dc.drawText(
				_pos_x + SHADOW_OFFSET,
				_pos_y + SHADOW_OFFSET,
				fontBg_(_is_small),
				_text,
				_justify
			);
		}
	}

	function TextWidth(
		_dc as Graphics.Dc,
		_text as Lang.String,
		_is_small as Lang.Boolean
	) as Lang.Number {
		return (
			_dc.getTextWidthInPixels(_text, fontFg_(_is_small)) +
			(_text.length() == 0 ? 0 : SHADOW_OFFSET)
		);
	}

	function TextHeight(
		_dc as Graphics.Dc,
		_is_small as Lang.Boolean
	) as Lang.Number {
		return _dc.getFontHeight(fontFg_(_is_small)) + SHADOW_OFFSET;
	}

	function numberBg_(_width as Lang.Number) as Lang.String {
		if (_width <= 0) {
			return NUMBER_BACKGROUNDS[0];
		}

		if (_width < NUMBER_BACKGROUNDS.size()) {
			return NUMBER_BACKGROUNDS[_width];
		}

		var result = NUMBER_BACKGROUNDS[NUMBER_BACKGROUNDS.size() - 1];
		for (var i = result.length(); i < _width; ++i) {
			result += "0";
		}
		return result;
	}

	function Number(
		_dc as Graphics.Dc,
		_pos_x as Lang.Number,
		_pos_y as Lang.Number,
		_number as Lang.Number?,
		_width as Lang.Number,
		_is_small as Lang.Boolean
	) as Void {
		var fg = NumberFormat(_width, _number);
		var bg = numberBg_(_width - fg.length());
		var bg_width = NumberBgWidth(_dc, bg, _is_small);

		NumberPrepared(_dc, _pos_x, _pos_y, bg, bg_width, fg, _is_small);
	}

	function NumberPrepared(
		_dc as Graphics.Dc,
		_pos_x as Lang.Number,
		_pos_y as Lang.Number,
		_bg as Lang.String,
		_bg_width as Lang.Number,
		_fg as Lang.String,
		_is_small as Lang.Boolean
	) as Void {
		if (_bg.length() != 0) {
			var font_shade = fontBg_(_is_small);
			_dc.setColor(Render.shade, Graphics.COLOR_TRANSPARENT);
			_dc.drawText(_pos_x, _pos_y, font_shade, _bg, JUSTIFY_LEFT);
		}

		if (_fg.length() != 0) {
			Text(
				_dc,
				Render.foreground,
				_pos_x + _bg_width,
				_pos_y,
				_is_small,
				_fg,
				JUSTIFY_LEFT
			);
		}
	}

	function NumberBgForText(
		_width as Lang.Number,
		_fg as Lang.String
	) as Lang.String {
		return numberBg_(_width - _fg.length());
	}

	function NumberBgWidth(
		_dc as Graphics.Dc,
		_bg as Lang.String,
		_is_small as Lang.Boolean
	) as Lang.Number {
		return _dc.getTextWidthInPixels(_bg, fontBg_(_is_small));
	}

	function NumberWidth(
		_dc as Graphics.Dc,
		_width as Lang.Number,
		_is_small as Lang.Boolean
	) as Lang.Number {
		return (
			_dc.getTextWidthInPixels(numberBg_(_width), fontFg_(_is_small)) +
			SHADOW_OFFSET
		);
	}

	function NumberHeight(
		_dc as Graphics.Dc,
		_is_small as Lang.Boolean
	) as Lang.Number {
		return _dc.getFontHeight(fontFg_(_is_small)) + SHADOW_OFFSET;
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

		var suffixes_size = NUMBER_SUFFIXES.size();

		var value = _number.toFloat();
		for (var i = 0; i < suffixes_size; ++i) {
			value /= 1000;

			var suffix = NUMBER_SUFFIXES[i];

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

	function Gauge(
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

		_dc.setColor(Render.shade, Graphics.COLOR_TRANSPARENT);
		for (var i = 0; i < _height; i += 2 * SPACING) {
			_dc.fillRectangle(_pos_x, _pos_y + i, 1, 1);
		}
	}

	function Ratio(
		_value as Lang.Number?,
		_value_max as Lang.Number?
	) as Lang.Float? {
		if (_value == null or _value_max == null or _value_max == 0) {
			return null;
		}

		var ratio =
			(_value as Lang.Number).toFloat() / (_value_max as Lang.Number);
		if (ratio < 0.0) {
			return 0.0;
		}
		if (1.0 < ratio) {
			return 1.0;
		}
		return ratio;
	}

	function BarCount(
		_size_x as Lang.Number,
		_borders_width as Lang.Number,
		_bar_width as Lang.Number
	) as Lang.Number {
		if (_bar_width <= 0) {
			return 0;
		}

		var count = (_size_x - _borders_width) / _bar_width;
		return count < 0 ? 0 : count;
	}

	function Icons(
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
			_dc.drawText(_pos_x, _pos_y, ICONS, _icons, _justify);
		}

		if (_shade.length() != 0) {
			_dc.setColor(Render.shade, Graphics.COLOR_TRANSPARENT);
			_dc.drawText(
				_pos_x + SHADOW_OFFSET,
				_pos_y + SHADOW_OFFSET,
				ICONS,
				_shade,
				_justify
			);
		}
	}

	function IconsRawWidth(
		_dc as Graphics.Dc,
		_icons as Lang.String
	) as Lang.Number {
		return _dc.getTextWidthInPixels(_icons, ICONS);
	}

	function IconsWidth(
		_dc as Graphics.Dc,
		_icons as Lang.String
	) as Lang.Number {
		return (
			IconsRawWidth(_dc, _icons) +
			(_icons.length() == 0 ? 0 : SHADOW_OFFSET)
		);
	}

	function IconsHeight(_dc as Graphics.Dc) as Lang.Number {
		return _dc.getFontHeight(ICONS) + SHADOW_OFFSET;
	}

	function Repeat(
		_value as Lang.String,
		_count as Lang.Number
	) as Lang.String {
		var result = "";
		for (var i = 0; i < _count; ++i) {
			result += _value;
		}
		return result;
	}
} // module Render
