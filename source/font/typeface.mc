// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Graphics;
import Toybox.Lang;

module Font {

class Typeface {
	typedef Glyphs as Lang.Dictionary<Lang.Char, Glyph>;

	var name as Lang.String;
	var height as Lang.Number;

	var glyphs_ as Glyphs;

	static const empty_ as Glyph = new Glyph([], 0);

	function initialize(_name as Lang.String, _glyphs as Glyphs, _height as Lang.Number) {
		self.name = _name;
		self.height = _height;
		self.glyphs_ = _glyphs;
	}

	function render(
		_dc as Graphics.Dc, _pos_x as Lang.Number, _pos_y as Lang.Number, _str as Lang.String, _style as Style
	) as Void {
		var chars = _str.toCharArray();
		var chars_size = chars.size();
		if (chars_size == 0) {
			return;
		}

		var size = _style.size;

		for (var i = 0; i < chars_size; ++i) {
			var glyph = self.getOrEmpty(chars[i]);

			glyph.render(_dc, _pos_x, _pos_y, _style);
			_pos_x += size * glyph.advance_;
		}
	}

	function measure(_str as Lang.String, _style as Style) as Lang.Number {
		var chars = _str.toCharArray();
		var chars_size = chars.size();
		if (chars_size == 0) {
			return 0;
		}

		var size = _style.size;

		var width = size * self.getOrEmpty(chars[0]).width;

		for (var i = 1; i < chars_size; ++i) {
			var glyph = self.getOrEmpty(chars[i]);

			width += size * glyph.advance_;
		}

		return width;
	}

	function getOrEmpty(_char as Lang.Char) as Glyph {
		var glyph = self.glyphs_.get(_char);
		if (glyph == null) {
			Test.assertMessage(false, "Can't find glyph for " + self.name + " '" + _char + "'");
			return Typeface.empty_;
		}
		return glyph;
	}
}

} // module Font
