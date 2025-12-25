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

		for (var i = 0; i < chars.size(); ++i) {
			var glyph = self.getOrEmpty(chars[i]);

			glyph.render(_dc, _pos_x, _pos_y, _style);
			_pos_x += _style.size * (glyph.width + 1);
		}
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
