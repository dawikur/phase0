// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Complications;
import Toybox.Graphics;
import Toybox.Lang;

module Widgets {
	class Metric extends Base {
		hidden var impl_ as Data.Base;
		hidden var value_ as Lang.Number? = null;
		hidden var value_max_ as Lang.Number? = null;
		hidden var value_text_ as Lang.String = "";
		hidden var icon_ as Lang.String = "";

		var is_small as Lang.Boolean = false;

		var properties as Properties.Metric;

		static function Width(
			_dc as Graphics.Dc,
			_width as Lang.Number,
			_is_small as Lang.Boolean,
			_show_icon as Lang.Boolean,
			_show_gauge as Lang.Boolean,
			_show_padding as Lang.Boolean
		) as Lang.Number {
			var size_x = _show_padding
				? Render.NumberWidth(_dc, _width, _is_small)
				: Render.TextWidth(
						_dc,
						Render.NumberFormat(_width, 0),
						_is_small
					);

			if (_show_icon) {
				size_x +=
					Render.IconsWidth(_dc, Fonts.ICON_EMPTY) + Render.SPACING;
			}

			if (_show_gauge) {
				size_x += Render.SPACING / 2 + Render.SPACING;
			}

			return size_x;
		}

		static function Height(
			_dc as Graphics.Dc,
			_is_small as Lang.Boolean,
			_show_label as Lang.Boolean,
			_has_label as Lang.Boolean
		) as Lang.Number {
			var size_y = Render.NumberHeight(_dc, _is_small);

			if (_show_label and _has_label) {
				size_y += Render.LabelHeight(_dc) + Render.SPACING;
			}

			return size_y;
		}

		function initialize(
			_properties as Properties.Metric,
			_impl as Data.Base
		) {
			Base.initialize(_impl.type);

			self.impl_ = _impl;
			self.properties = _properties;
		}

		function resize(_dc as Graphics.Dc) as Void {
			self.size_x = Metric.Width(
				_dc,
				self.properties.width,
				self.is_small,
				self.properties.icon,
				self.properties.gauge,
				self.properties.padding
			);

			self.size_y = Metric.Height(
				_dc,
				self.is_small,
				self.properties.accent != Render.COLOR_NONE,
				self.impl_.name.length() != 0
			);
		}

		function refresh(_dc as Graphics.Dc) as Void {
			self.impl_.refresh();

			self.value_ = self.impl_.value;
			self.value_max_ = self.impl_.value_max;

			if (self.value_ != null) {
				self.value_text_ = self.properties.padding
					? ""
					: self.value_.format("%d");
			} else {
				self.value_text_ = "";
			}

			if (self.properties.icon) {
				var icon = self.impl_.icon;
				if (icon != null) {
					self.icon_ = icon;
				} else {
					self.icon_ = "";
				}
			}
		}

		function render(_dc as Graphics.Dc) as Void {
			// ---- header ----

			var icon_width = self.properties.icon
				? Render.IconsWidth(_dc, self.icon_) + Render.SPACING
				: 0;

			var pos_x = self.pos_x;
			var pos_y =
				self.pos_y +
				(self.properties.accent != Render.COLOR_NONE
					? Render.LabelHeight(_dc) + Render.SPACING
					: 0);

			// ---- icon ----

			if (self.properties.icon) {
				Render.Icons(
					_dc,
					Properties.general.foreground,
					pos_x,
					pos_y,
					self.icon_,
					self.icon_,
					Render.JUSTIFY_LEFT
				);
				pos_x += icon_width;
			}

			// ---- value ----

			if (self.properties.padding) {
				Render.Number(
					_dc,
					pos_x,
					pos_y,
					self.value_,
					self.properties.width,
					self.is_small
				);
				pos_x += Render.NumberWidth(
					_dc,
					self.properties.width,
					self.is_small
				);
			} else if (self.value_text_.length() != 0) {
				Render.Text(
					_dc,
					Properties.general.foreground,
					pos_x,
					pos_y,
					self.is_small,
					self.value_text_,
					Render.JUSTIFY_LEFT
				);
				pos_x += Render.TextWidth(_dc, self.value_text_, self.is_small);
			}

			// ---- gauge ----

			if (self.properties.gauge) {
				if (self.value_ != null and self.value_max_ != null) {
					var value_max = self.value_max_ as Lang.Number;
					if (value_max != 0) {
						var value = self.value_.toFloat() / value_max;
						var max_height =
							Render.NumberHeight(_dc, self.is_small) -
							2 * Render.SPACING;

						if (0 < max_height) {
							pos_x += Render.SPACING / 2;

							Render.Gauge(
								_dc,
								value == 1.0
									? self.properties.accent
									: Properties.general.foreground,
								pos_x,
								pos_y + Render.SPACING,
								max_height,
								value
							);

							pos_x += Render.SPACING / 2;
						}
					}
				}
			}

			// ---- label ----

			if (self.properties.accent != Render.COLOR_NONE) {
				Render.Label(
					_dc,
					self.properties.accent,
					self.pos_x + (pos_x - self.pos_x) / 2,
					self.pos_y,
					self.impl_.name,
					Graphics.TEXT_JUSTIFY_CENTER
				);
			}
		}
	}
} // module Widgets
