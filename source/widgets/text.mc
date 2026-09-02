// Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

import Toybox.Complications;
import Toybox.Graphics;
import Toybox.Lang;

module Widgets {
	class Text extends Base {
		hidden var label_ as Lang.String = "";
		hidden var value_ as Lang.String = "";
		hidden var justify_ as Lang.Number = Render.JUSTIFY_LEFT;
		hidden var is_small_ as Lang.Boolean = false;
		hidden var label_offset_y_ as Lang.Number = 0;
		hidden var show_label_ as Lang.Boolean = true;

		function initialize(
			_type as Complications.Type?,
			_refresh_rate as Lang.Number
		) {
			Base.initialize(_type, _refresh_rate);
		}

		function resize(
			_dc as Graphics.Dc,
			_size_x as Lang.Number,
			_size_y as Lang.Number
		) as Void {
			self.size_x = _size_x;
			self.size_y = _size_y;

			if (
				self.tryApplyCandidate_(
					_dc,
					self.is_small_,
					self.show_label_,
					_size_x,
					_size_y
				) or
				self.tryApplyCandidate_(
					_dc,
					Render.SIZE_SMALL,
					self.show_label_,
					_size_x,
					_size_y
				) or
				self.tryApplyCandidate_(
					_dc,
					Render.SIZE_REGULAR,
					false,
					_size_x,
					_size_y
				) or
				self.tryApplyCandidate_(
					_dc,
					Render.SIZE_SMALL,
					false,
					_size_x,
					_size_y
				)
			) {
			}

			self.is_dirty_ = true;
		}

		function refresh(_dc as Graphics.Dc) as Void {
			var value = self.getValue();
			if (self.value_ != value) {
				self.value_ = value;
				self.is_dirty_ = true;
			}
		}

		function render(_dc as Graphics.Dc) as Void {
			// ---- header ----

			var pos_x = self.anchorX_();
			var pos_y = self.anchorY_();

			// ---- label ----

			if (self.show_label_) {
				Render.Label(
					_dc,
					Render.accent,
					pos_x,
					pos_y,
					self.label_,
					self.justify_
				);
				pos_y += self.label_offset_y_;
			}

			// ---- value ----

			if (self.value_ != null) {
				Render.Text(
					_dc,
					Render.foreground,
					pos_x,
					pos_y,
					self.is_small_,
					self.value_,
					self.justify_
				);
			}
		}

		function getValue() as Lang.String {
			return "";
		}

		hidden function anchorX_() as Lang.Number {
			if (self.justify_ & Render.JUSTIFY_CENTER) {
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

		hidden function tryApplyCandidate_(
			_dc as Graphics.Dc,
			_is_small as Lang.Boolean,
			_show_label as Lang.Boolean,
			_available_x as Lang.Number,
			_available_y as Lang.Number
		) as Lang.Boolean {
			var text_size_x = Render.TextWidth(_dc, self.value_, _is_small);
			var text_size_y = Render.TextHeight(_dc, _is_small);
			var label_offset_y =
				_show_label and self.label_.length() != 0
					? Render.LabelHeight(_dc) + Render.SPACING
					: 0;
			var size_x = text_size_x;
			var size_y = text_size_y + label_offset_y;

			self.is_small_ = _is_small;
			self.label_offset_y_ = label_offset_y;
			self.show_label_ = label_offset_y != 0;

			return Fits(size_x, size_y, _available_x, _available_y);
		}
	}
} // module Widgets
