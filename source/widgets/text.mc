// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Complications;
import Toybox.Graphics;
import Toybox.Lang;

module Widgets {
	class Text extends Base {
		var small as Lang.Boolean = false;

		hidden var label_ as Lang.String = "";
		hidden var value_ as Lang.String = "";
		hidden var justify_ as Lang.Number = Render.JUSTIFY_LEFT;

		function initialize(_type as Complications.Type) {
			Base.initialize(_type);
		}

		function width(_dc as Graphics.Dc) as Lang.Number {
			return Render.TextWidth(_dc, self.value_, self.small);
		}

		function height(_dc as Graphics.Dc) as Lang.Number {
			if (self.small) {
				if (self.label_.length() == 0) {
					return Render.TextHeight(_dc, true);
				}
				return (
					Render.LabelHeight(_dc) +
					Render.SPACING +
					Render.TextHeight(_dc, true)
				);
			}

			if (self.label_.length() == 0) {
				return Render.TextHeight(_dc, false);
			}
			return (
				Render.LabelHeight(_dc) +
				Render.SPACING +
				Render.TextHeight(_dc, false)
			);
		}

		function contains(
			_x as Lang.Number,
			_y as Lang.Number
		) as Lang.Boolean {
			var pos_x = self.pos_x;
			var pos_y = self.pos_y;

			if (self.justify_ & Render.JUSTIFY_LEFT) {
			} else if (self.justify_ & Render.JUSTIFY_CENTER) {
				pos_x -= self.size_x / 2;
			} else if (self.justify_ & Render.JUSTIFY_RIGHT) {
				pos_x -= self.size_x;
			}

			if (self.justify_ & Graphics.TEXT_JUSTIFY_VCENTER) {
				pos_y -= self.size_y / 2;
			}

			var end_x = pos_x + self.size_x;
			var end_y = pos_y + self.size_y;

			return pos_x <= _x and _x <= end_x and pos_y <= _y and _y <= end_y;
		}

		function refresh(_dc as Graphics.Dc) as Void {
			self.value_ = self.getValue();
		}

		function render(_dc as Graphics.Dc) as Void {
			// ---- prepare ----

			var pos_x = self.pos_x;
			var pos_y = self.pos_y;

			// ---- label ----

			if (self.label_.length() != 0) {
				Render.Label(
					_dc,
					Render.COLOR_ORANGE,
					pos_x,
					pos_y,
					self.label_,
					self.justify_
				);
				pos_y += Render.LabelHeight(_dc) + Render.SPACING;
			}

			// ---- value ----

			if (self.value_.length() != 0) {
				Render.Text(
					_dc,
					pos_x,
					pos_y,
					self.small,
					self.value_,
					self.justify_
				);
			}
		}

		function getValue() as Lang.String {
			return "";
		}
	}
} // module Widgets
