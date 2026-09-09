// Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

import Toybox.Complications;
import Toybox.Graphics;
import Toybox.Lang;

module Widgets {
	class Metric extends Base {
		hidden var body_width_ as Lang.Number = 0;
		hidden var gauge_height_ as Lang.Number = 0;
		hidden var icon_ as Lang.String = "";
		hidden var icon_width_ as Lang.Number = 0;
		hidden var impl_ as Data.Base;
		hidden var label_offset_y_ as Lang.Number = 0;
		hidden var number_height_ as Lang.Number = 0;
		hidden var number_width_ as Lang.Number = 0;
		hidden var show_gauge_ as Lang.Boolean = false;
		hidden var show_icon_ as Lang.Boolean = false;
		hidden var show_label_ as Lang.Boolean = true;
		hidden var style_ as Lang.Number = Properties.NONE;
		hidden var value_ as Lang.Number? = null;
		hidden var value_bg_ as Lang.String = "";
		hidden var value_bg_width_ as Lang.Number = 0;
		hidden var value_max_ as Lang.Number? = null;
		hidden var value_offset_y_ as Lang.Number = 0;
		hidden var value_text_ as Lang.String = "";
		hidden var is_value_prepared_ as Lang.Boolean = false;
		hidden var refresh_revision_ as Lang.Number? = null;

		hidden var width_ as Lang.Number;

		function initialize(
			_properties as Properties.Metric,
			_style as Lang.Number,
			_impl as Data.Base
		) {
			Base.initialize(_impl.type, _impl.refresh_rate);

			self.impl_ = _impl;
			self.width_ = _properties.width;
			self.style_ = _style;
		}
		function resize(
			_dc as Graphics.Dc,
			_size_x as Lang.Number,
			_size_y as Lang.Number
		) as Void {
			var show_label = Render.accent != Render.COLOR_NONE;
			var show_icon = self.style_ == Properties.ICON;
			var show_gauge = self.style_ == Properties.GAUGE;

			if (
				self.tryApplyCandidate_(
					_dc,
					Render.SIZE_REGULAR,
					show_label,
					show_icon,
					show_gauge,
					_size_x,
					_size_y
				) or
				self.tryApplyCandidate_(
					_dc,
					Render.SIZE_SMALL,
					show_label,
					show_icon,
					show_gauge,
					_size_x,
					_size_y
				) or
				self.tryApplyCandidate_(
					_dc,
					Render.SIZE_SMALL,
					show_label,
					false,
					false,
					_size_x,
					_size_y
				) or
				self.tryApplyCandidate_(
					_dc,
					Render.SIZE_SMALL,
					false,
					false,
					false,
					_size_x,
					_size_y
				)
			) {
			}

			self.is_dirty_ = true;
		}

		function refresh(_dc as Graphics.Dc) as Void {
			self.impl_.refresh();
			self.refresh_revision_ = self.impl_.refreshRevision();

			var value = self.impl_.value;
			var is_value_changed =
				!self.is_value_prepared_ or self.value_ != value;
			if (is_value_changed) {
				self.value_ = value;
				self.value_text_ = Render.NumberFormat(
					self.width_,
					self.value_
				);
				self.value_bg_ = Render.NumberBgForText(
					self.width_,
					self.value_text_
				);
				self.value_bg_width_ = Render.NumberBgWidth(
					_dc,
					self.value_bg_,
					self.is_small
				);
				self.is_value_prepared_ = true;
			}

			var value_max = self.impl_.value_max;
			var is_value_max_changed = self.value_max_ != value_max;
			self.value_max_ = value_max;

			var is_icon_changed = false;
			if (self.show_icon_) {
				var icon = self.impl_.icon;
				var value_icon = "";
				if (icon != null) {
					value_icon = icon as Lang.String;
				}
				is_icon_changed = self.icon_ != value_icon;
				self.icon_ = value_icon;
			}

			if (
				is_value_changed or
				(self.show_gauge_ and is_value_max_changed) or
				is_icon_changed
			) {
				self.is_dirty_ = true;
			}
		}

		function needsRefresh() as Lang.Boolean {
			var revision = self.impl_.refreshRevision();
			return revision != null and self.refresh_revision_ != revision;
		}

		function render(_dc as Graphics.Dc) as Void {
			// ---- header ----

			var center_x = self.centerX();
			var pos_x = self.pos_x + (self.size_x - self.body_width_) / 2;
			var pos_y = self.pos_y + self.label_offset_y_;
			var value_pos_y = pos_y + self.value_offset_y_;

			// ---- icon ----

			if (self.show_icon_) {
				Render.Icons(
					_dc,
					Render.foreground,
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

			if (self.show_gauge_) {
				var value = Render.Ratio(self.value_, self.value_max_);
				if (value != null and 0 < self.gauge_height_) {
					pos_x += Render.SPACING / 2;

					Render.Gauge(
						_dc,
						1.0 <= value ? Render.accent : Render.foreground,
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
					Render.accent,
					center_x,
					self.pos_y,
					self.impl_.name,
					Graphics.TEXT_JUSTIFY_CENTER
				);
			}
		}

		hidden function tryApplyCandidate_(
			_dc as Graphics.Dc,
			_is_small as Lang.Boolean,
			_show_label as Lang.Boolean,
			_show_icon as Lang.Boolean,
			_show_gauge as Lang.Boolean,
			_available_x as Lang.Number,
			_available_y as Lang.Number
		) as Lang.Boolean {
			var number_width = Render.NumberWidth(_dc, self.width_, _is_small);
			var number_height = Render.NumberHeight(_dc, _is_small);
			var icon_height = _show_icon ? Render.IconsHeight(_dc) : 0;
			var icon_width = _show_icon
				? Render.IconsWidth(_dc, Fonts.ICON_EMPTY) + Render.SPACING
				: 0;
			var gauge_height = number_height - 3 * Render.SPACING;

			var body_width = number_width + icon_width;
			if (_show_gauge) {
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
			var value_offset_y =
				_show_icon and _is_small
					? AlignCenter(0, Render.IconsHeight(_dc), number_height)
					: 0;
			var body_height = number_height + value_offset_y;
			if (body_height < icon_height) {
				body_height = icon_height;
			}
			var size_y = body_height + label_offset_y;

			self.body_width_ = body_width;
			self.gauge_height_ = gauge_height;
			self.icon_width_ = icon_width;
			self.label_offset_y_ = label_offset_y;
			self.number_height_ = number_height;
			self.number_width_ = number_width;
			self.show_gauge_ = _show_gauge;
			self.show_icon_ = _show_icon;
			self.show_label_ = has_label;
			self.size_x = size_x;
			self.size_y = size_y;
			self.value_offset_y_ = value_offset_y;
			self.is_value_prepared_ = false;

			self.is_small = _is_small;

			return Fits(size_x, size_y, _available_x, _available_y);
		}
	}
} // module Widgets
