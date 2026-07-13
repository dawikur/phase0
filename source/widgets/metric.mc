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
		hidden var value_bg_ as Lang.String = "";
		hidden var value_bg_width_ as Lang.Number = 0;
		hidden var icon_ as Lang.String = "";
		hidden var show_label_ as Lang.Boolean = true;
		hidden var style_ as Lang.Number = Properties.NONE;
		hidden var body_width_ as Lang.Number = 0;
		hidden var icon_width_ as Lang.Number = 0;
		hidden var label_offset_y_ as Lang.Number = 0;
		hidden var number_width_ as Lang.Number = 0;
		hidden var number_height_ as Lang.Number = 0;
		hidden var gauge_height_ as Lang.Number = 0;
		hidden var value_offset_y_ as Lang.Number = 0;

		var properties as Properties.Metric;

		static function PreferredIsSmall(
			_properties as Properties.Metric,
			_is_small as Lang.Boolean
		) as Lang.Boolean {
			return (
				_properties.height == Properties.SMALL or
				(_properties.height == Properties.AUTO and _is_small)
			);
		}

		static function HasIcon(_style as Lang.Number) as Lang.Boolean {
			return _style == Properties.ICON;
		}

		static function HasGauge(_style as Lang.Number) as Lang.Boolean {
			return _style == Properties.GAUGE;
		}

		function initialize(
			_properties as Properties.Metric,
			_impl as Data.Base
		) {
			Base.initialize(_impl.type);

			self.impl_ = _impl;
			self.properties = _properties;
		}

		function applyCandidate_(
			_dc as Graphics.Dc,
			_is_small as Lang.Boolean,
			_show_label as Lang.Boolean,
			_style as Lang.Number,
			_available_x as Lang.Number,
			_available_y as Lang.Number,
			_force as Lang.Boolean
		) as Lang.Boolean {
			var number_width = Render.NumberWidth(
				_dc,
				self.properties.width,
				_is_small
			);
			var number_height = Render.NumberHeight(_dc, _is_small);
			var icon_width = Metric.HasIcon(_style)
				? Render.IconsWidth(_dc, Fonts.ICON_EMPTY) + Render.SPACING
				: 0;
			var gauge_height = number_height - 2 * Render.SPACING;

			var body_width = number_width + icon_width;
			if (Metric.HasGauge(_style)) {
				body_width += Render.SPACING / 2 + Render.SPACING;
			}

			var has_label = _show_label and self.impl_.name.length() != 0;
			var label_offset_y = has_label
				? Render.LabelHeight(_dc) + Render.SPACING
				: 0;
			var label_width = has_label
				? Render.LabelWidth(_dc, self.impl_.name)
				: 0;
			var size_x = body_width < label_width ? label_width : body_width;
			var size_y = number_height + label_offset_y;
			var value_offset_y =
				Metric.HasIcon(_style) and _is_small
					? Base.AlignCenter(
							0,
							Render.IconsHeight(_dc),
							number_height
						)
					: 0;

			if (
				!_force and
				!Base.Fits(size_x, size_y, _available_x, _available_y)
			) {
				return false;
			}

			self.is_small = _is_small;
			self.show_label_ = has_label;
			self.style_ = _style;
			self.size_x = size_x;
			self.size_y = size_y;
			self.body_width_ = body_width;
			self.icon_width_ = icon_width;
			self.label_offset_y_ = label_offset_y;
			self.number_width_ = number_width;
			self.number_height_ = number_height;
			self.gauge_height_ = gauge_height;
			self.value_offset_y_ = value_offset_y;

			return true;
		}

		function resize(
			_dc as Graphics.Dc,
			_size_x as Lang.Number,
			_size_y as Lang.Number,
			_is_small as Lang.Boolean
		) as Void {
			self.is_small = Metric.PreferredIsSmall(self.properties, _is_small);
			self.show_label_ = self.properties.accent != Render.COLOR_NONE;
			self.style_ = self.properties.style;

			if (
				self.applyCandidate_(
					_dc,
					self.is_small,
					self.show_label_,
					self.style_,
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
					self.style_,
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
					Render.SIZE_SMALL,
					self.show_label_,
					Properties.NONE,
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
				Properties.NONE,
				_size_x,
				_size_y,
				true
			);
		}

		function refresh(_dc as Graphics.Dc) as Void {
			self.impl_.refresh();

			self.value_ = self.impl_.value;
			self.value_max_ = self.impl_.value_max;
			self.value_text_ = Render.NumberFormat(
				self.properties.width,
				self.value_
			);
			self.value_bg_ = Render.NumberBgForText(
				self.properties.width,
				self.value_text_
			);
			self.value_bg_width_ = Render.NumberBgWidth(
				_dc,
				self.value_bg_,
				self.is_small
			);

			if (Metric.HasIcon(self.style_)) {
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

			var center_x = self.centerX();
			var pos_x = self.pos_x + (self.size_x - self.body_width_) / 2;
			var pos_y = self.pos_y + self.label_offset_y_;
			var value_pos_y = pos_y + self.value_offset_y_;

			// ---- icon ----

			if (Metric.HasIcon(self.style_)) {
				Render.Icons(
					_dc,
					Properties.general.foreground,
					pos_x,
					pos_y,
					self.icon_,
					self.icon_,
					Render.JUSTIFY_LEFT
				);
				pos_x += self.icon_width_;
			}

			// ---- value ----

			Render.NumberPrepared(
				_dc,
				pos_x,
				value_pos_y,
				self.value_bg_,
				self.value_bg_width_,
				self.value_text_,
				self.is_small
			);
			pos_x += self.number_width_;

			// ---- gauge ----

			if (Metric.HasGauge(self.style_)) {
				var value = Render.Ratio(self.value_, self.value_max_);
				if (value != null and 0 < self.gauge_height_) {
					pos_x += Render.SPACING / 2;

					Render.Gauge(
						_dc,
						value >= 1.0
							? self.properties.accent
							: Properties.general.foreground,
						pos_x,
						value_pos_y + Render.SPACING,
						self.gauge_height_,
						value
					);

					pos_x += Render.SPACING / 2;
				}
			}

			// ---- label ----

			if (self.show_label_) {
				Render.Label(
					_dc,
					self.properties.accent,
					center_x,
					self.pos_y,
					self.impl_.name,
					Graphics.TEXT_JUSTIFY_CENTER
				);
			}
		}
	}
} // module Widgets
