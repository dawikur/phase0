// Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

import Toybox.Graphics;
import Toybox.Lang;

module Widgets {
	class Status extends Base {
		hidden var enabled_ as Lang.String = "";
		hidden var all_ as Lang.String;
		hidden var slots_ as Lang.Array<Data.Base> = [];
		hidden var icons_ as Lang.Array<Lang.String> = [];

		function initialize(_properties as Lang.Array<Properties.Status>) {
			Base.initialize(null, Data.RefreshRate.SEC);

			self.all_ = "";
			self.slots_ = [];
			var properties_size = _properties.size();
			for (var i = 0; i < properties_size; ++i) {
				var property = _properties[i];

				var data = Data.get(property.data);
				if (data != null and data.icon != null) {
					self.slots_.add(data);
					self.icons_.add(Fonts.ICON_EMPTY);
					self.all_ = self.AppendIcon_(self.all_, data.icon as Lang.String);
					self.enabled_ = self.AppendIcon_(self.enabled_, Fonts.ICON_EMPTY);
				}
			}
		}

		function refresh(_dc as Graphics.Dc) as Void {
			var changed = false;
			var size = self.slots_.size();
			for (var i = 0; i < size; ++i) {
				var data = self.slots_[i];
				if (data.refresh_rate == Data.RefreshRate.NONE) {
					continue;
				}
				data.refresh();
				var icon = data.icon as Lang.String;
				if (self.icons_[i] != icon) {
					self.icons_[i] = icon;
					changed = true;
				}
			}
			if (!changed) {
				return;
			}
			self.enabled_ = "";
			for (var i = 0; i < size; ++i) {
				self.enabled_ = self.AppendIcon_(self.enabled_, self.icons_[i]);
			}
			self.is_dirty_ = true;
		}

		function render(_dc as Graphics.Dc) as Void {
			if (self.size_x <= 0 or self.size_y <= 0) {
				return;
			}
			var center_x = self.centerX();
			var center_y = self.centerY() + Render.SHADOW_OFFSET;

			Render.Icons(
				_dc,
				Render.foreground,
				center_x,
				center_y,
				self.enabled_,
				self.all_,
				Render.JUSTIFY_CENTER
			);
		}

		function renderMinimal(_dc as Graphics.Dc) as Void {
			if (self.size_x <= 0 or self.size_y <= 0) {
				return;
			}
			var center_x = self.centerX();
			var center_y = self.centerY() + Render.SHADOW_OFFSET;

			Render.Icons(
				_dc,
				Render.foreground,
				center_x,
				center_y,
				self.enabled_,
				"",
				Render.JUSTIFY_CENTER
			);
		}

		static function AppendIcon_(
			_icons as Lang.String,
			_icon as Lang.String
		) as Lang.String {
			return _icons.length() == 0 ? _icon : _icons + "\n" + _icon;
		}

	}
} // module Widgets
