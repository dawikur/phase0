// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Complications;
import Toybox.Graphics;
import Toybox.Lang;

module Widgets {
	class Text extends Base {
		hidden var label_ as Lang.String = "";
		hidden var value_ as Lang.String = "";
		hidden var justify_ as Lang.Number = Render.JUSTIFY_LEFT;
		hidden var show_label_ as Lang.Boolean = true;
		hidden var label_offset_y_ as Lang.Number = 0;

		function initialize(_type as Complications.Type?) {
			Base.initialize(_type);
		}

		hidden function applyCandidate_(
			_dc as Graphics.Dc,
			_is_small as Lang.Boolean,
			_show_label as Lang.Boolean,
			_available_x as Lang.Number,
			_available_y as Lang.Number,
			_force as Lang.Boolean
		) as Lang.Boolean {
			var size_x = Render.TextWidth(_dc, self.value_, _is_small);
			var label_offset_y =
				_show_label and self.label_.length() != 0
					? Render.LabelHeight(_dc) + Render.SPACING
					: 0;
			var size_y = Render.TextHeight(_dc, _is_small) + label_offset_y;

			if (
				!_force and
				!Base.Fits(size_x, size_y, _available_x, _available_y)
			) {
				return false;
			}

			self.is_small = _is_small;
			self.show_label_ = label_offset_y != 0;
			self.label_offset_y_ = label_offset_y;

			return true;
		}

		function resize(
			_dc as Graphics.Dc,
			_size_x as Lang.Number,
			_size_y as Lang.Number,
			_is_small as Lang.Boolean
		) as Void {
			self.size_x = _size_x;
			self.size_y = _size_y;
			self.is_small = _is_small;
			self.show_label_ = true;
			self.label_offset_y_ = 0;

			if (
				self.applyCandidate_(
					_dc,
					self.is_small,
					self.show_label_,
					_size_x,
					_size_y,
					false
				)
			) {
				return;
			}
			if (
				!self.is_small and
				self.applyCandidate_(
					_dc,
					Render.SIZE_SMALL,
					self.show_label_,
					_size_x,
					_size_y,
					false
				)
			) {
				return;
			}

			if (
				self.applyCandidate_(
					_dc,
					Render.SIZE_REGULAR,
					false,
					_size_x,
					_size_y,
					false
				)
			) {
				return;
			}

			self.applyCandidate_(
				_dc,
				Render.SIZE_SMALL,
				false,
				_size_x,
				_size_y,
				true
			);
		}

		hidden function anchorX_() as Lang.Number {
			if (self.justify_ & Render.JUSTIFY_LEFT) {
				return self.pos_x;
			} else if (self.justify_ & Render.JUSTIFY_CENTER) {
				return self.centerX();
			} else if (self.justify_ & Render.JUSTIFY_RIGHT) {
				return self.pos_x + self.size_x;
			}

			return self.pos_x;
		}

		hidden function anchorY_() as Lang.Number {
			if (self.justify_ & Graphics.TEXT_JUSTIFY_VCENTER) {
				return self.centerY();
			}

			return self.pos_y;
		}

		function refresh(_dc as Graphics.Dc) as Void {
			self.value_ = self.getValue();
		}

		function render(_dc as Graphics.Dc) as Void {
			// ---- header ----

			var pos_x = self.anchorX_();
			var pos_y = self.anchorY_();

			// ---- label ----

			if (self.show_label_ and self.label_.length() != 0) {
				Render.Label(
					_dc,
					Properties.general.accent,
					pos_x,
					pos_y,
					self.label_,
					self.justify_
				);
				pos_y += self.label_offset_y_;
			}

			// ---- value ----

			if (self.value_.length() != 0) {
				Render.Text(
					_dc,
					Properties.general.foreground,
					pos_x,
					pos_y,
					self.is_small,
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
