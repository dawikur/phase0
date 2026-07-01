// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Complications;
import Toybox.Graphics;
import Toybox.Lang;

module Widgets {

class Metric extends Base {
	hidden var impl_ as Data.Base;
	hidden var count_ as Lang.Number;
	hidden var small_ as Lang.Boolean;
	hidden var label_ as Lang.String = "";
	hidden var value_ as Lang.Number or Null = null;
	hidden var value_max_ as Lang.Number or Null = null;
	hidden var value_text_ as Lang.String = "";
	hidden var icon_ as Lang.String = "";

	var show_icon as Lang.Boolean = false;
	var show_label as Lang.Boolean = false;
	var show_gauge as Lang.Boolean = false;
	var show_padding as Lang.Boolean = false;

	static function Width(
		_dc as Graphics.Dc,
		_count as Lang.Number,
		_small as Lang.Boolean,
		_show_icon as Lang.Boolean,
		_show_gauge as Lang.Boolean,
		_show_padding as Lang.Boolean
	) as Lang.Number {
		var size_x = _show_padding ?
			Render.numberWidth(_dc, _count, _small) :
			Render.textWidth(_dc, Render.numberFormat(_count, 0), _small);

		if (_show_icon) {
			size_x += Render.iconsWidth(_dc, Fonts.ICON_EMPTY) + Render.SPACING;
		}

		if (_show_gauge) {
			size_x += (Render.SPACING / 2) + Render.SPACING;
		}

		return size_x;
	}

	static function Height(
		_dc as Graphics.Dc,
		_small as Lang.Boolean,
		_show_label as Lang.Boolean,
		_has_label as Lang.Boolean
	) as Lang.Number {
		var size_y = Render.numberHeight(_dc, _small);

		if (_show_label and _has_label) {
			size_y += Render.labelHeight(_dc) + Render.SPACING;
		}

		return size_y;
	}

	function initialize(
		_dc as Graphics.Dc,
		_impl as Data.Base,
		_count as Lang.Number,
		_small as Lang.Boolean
	) {
		Base.initialize(_impl.type);

		self.impl_ = _impl;
		self.count_ = _count;
		self.small_ = _small;
		self.label_ = _impl.name;

		self.resize(_dc);
	}

	function resize(_dc as Graphics.Dc) as Void {
		self.size_x = Metric.Width(
			_dc,
			self.count_,
			self.small_,
			self.show_icon,
			self.show_gauge,
			self.show_padding
		);

		self.size_y = Metric.Height(
			_dc,
			self.small_,
			self.show_label,
			self.label_.length() != 0
		);
	}

	function refresh(_dc as Graphics.Dc) as Void {
		self.impl_.refresh();

		self.label_ = self.impl_.name;
		self.value_ = self.impl_.value;
		self.value_max_ = self.impl_.value_max;
		if (self.value_ != null) {
			self.value_text_ = self.show_padding ?
				"" :
				self.value_.format("%d");
		} else {
			self.value_text_ = "";
		}

		if (self.show_icon) {
			var icon = self.impl_.icon;
			if (icon != null) {
				self.icon_ = icon;
			} else {
				self.icon_ = "";
			}
		}
	}

	function render(_dc as Graphics.Dc) as Void {
		// ---- prepare ----

		if (self.value_ == null) {
			self.refresh(_dc);
		}

		var icon_width = self.show_icon
			? Render.iconsWidth(_dc, self.icon_) + Render.SPACING
			: 0;

		var pos_x = self.pos_x;
		var pos_y = self.pos_y + (self.show_label
			? (Render.labelHeight(_dc) + Render.SPACING)
			: 0);

		// ---- icon ----

		if (self.show_icon) {
			Render.icons(
				_dc,
				pos_x,
				pos_y,
				self.icon_,
				self.icon_,
				Render.JUSTIFY_LEFT
			);
			pos_x += icon_width;
		}

		// ---- value ----

		if (self.show_padding) {
			Render.number(
				_dc,
				pos_x,
				pos_y,
				self.value_,
				self.count_,
				self.small_
			);
			pos_x += Render.numberWidth(_dc, self.count_, self.small_);
		} else if (self.value_text_.length() != 0) {
			Render.text(
				_dc,
				pos_x,
				pos_y,
				self.small_,
				self.value_text_,
				Render.JUSTIFY_LEFT
			);
			pos_x += Render.textWidth(_dc, self.value_text_, self.small_);
		}

		// ---- gauge ----

		if (self.show_gauge) {
			if (self.value_ != null and self.value_max_ != null) {
				var value = self.value_ as Lang.Number;
				var value_max = self.value_max_ as Lang.Number;
				if (value_max != 0) {
					var gauge_height = Render.numberHeight(_dc, self.small_) - 2 * Render.SPACING;

					if (0 < gauge_height) {
						pos_x += Render.SPACING / 2;

						Render.gauge(
							_dc,
							pos_x,
							pos_y + Render.SPACING,
							gauge_height,
							value.toFloat() / value_max,
							Render.GAUGE_BOTTOM
						);

						pos_x += Render.SPACING / 2;
					}
				}
			}
		}

		// ---- label ----

		if (self.show_label) {
			Render.label(
				_dc,
				self.pos_x + (pos_x - self.pos_x) / 2,
				self.pos_y,
				self.label_,
				Graphics.TEXT_JUSTIFY_CENTER
			);
		}
	}
}

} // module Widgets
