// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

module Label {

class Style {
	var font as WatchUi.FontResource;
	var color as Lang.Number;

	function initialize(
		_font as WatchUi.FontResource,
		_color as Lang.Number
	) {
		self.font = _font;
		self.color = _color;
	}

	function draw(
		_dc as Graphics.Dc,
		_pos_x as Lang.Number,
		_pos_y as Lang.Number,
		_str as Lang.String,
		_justify as Lang.Number
	) as Void {
		_dc.setColor(self.color, Graphics.COLOR_TRANSPARENT);
		_dc.drawText(_pos_x, _pos_y, self.font, _str, _justify);
	}
}

class Base {
	var pos_x as Lang.Number = 0;
	var pos_y as Lang.Number = 0;

	hidden var label_ as Lang.String = "";
	hidden var styles_ as Lang.Array<Style> = [];
	hidden var justify_ as Lang.Number = 0;

	function initialize() {
		self.styles_ = [
			new Label.Style(Font.DOT_REGULAR, 0x555555),
			new Label.Style(Font.DOT_REGULAR_THIN, 0xFFFFFF),
		];
		self.justify_ = Graphics.TEXT_JUSTIFY_LEFT;
	}

	function render(_dc as Graphics.Dc) as Void {
		if (self.label_.length() == 0) {
			self.refresh(_dc);
		}

		if (self.label_.length() == 0) {
			return;
		}

		var label = self.label_;

		var pos_x = self.pos_x;
		var pos_y = self.pos_y;

		var justify = self.justify_;
		var styles = self.styles_;
		var styles_size = styles.size();

		for (var i = 0; i < styles_size; ++i) {
			styles[i].draw(_dc, pos_x, pos_y, label, justify);
		}
	}

	function refresh(_dc as Graphics.Dc) as Void {
	}
}

} // module Label
