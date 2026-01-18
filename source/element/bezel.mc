// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Lang;
import Toybox.Graphics;
import Toybox.Time;
import Toybox.System;

module Element {

class Bezel {
	var size_x as Lang.Numeric = 0;
	var size_y as Lang.Numeric = 0;

	var is_night_mode_ as Lang.Boolean = false;

	var palette as Lang.Dictionary<Lang.Symbol, Lang.Dictionary> = {
		:normal => {
			:normal        => 0xAA5500,
			:connected     => 0x005555,
			:notifications => 0x005500,
			:alarm         => 0xAA0000,
		},
		:charging => {
			:normal        => 0xFFAA00,
			:connected     => 0x00AAAA,
			:notifications => 0x00AA00,
			:alarm         => 0xFF0000,
		},
		:nightMode => {
			:normal        => 0x555555,
			:connected     => 0x555555,
			:notifications => 0x555555,
			:alarm         => 0xAAAAAA,
		}
	};

	function initialize() {
	}

	function render(_dc as Graphics.Dc) as Void {
		var systemStats = System.getSystemStats();
		var deviceSettings = System.getDeviceSettings();

		var styleSymbol =
			self.is_night_mode_ ?
			:nightMode :
			systemStats.charging ?
			:charging :
			:normal;
		var style = self.palette[styleSymbol] as Lang.Dictionary<Lang.Symbol, Lang.Number>;

		var color_symbol =
			(0 < deviceSettings.notificationCount) ?
			:notifications :
			deviceSettings.phoneConnected ?
			:connected :
			:normal;

		self.drawArc_(
			_dc,
			style[color_symbol] as Lang.Number,
			systemStats.battery
		);

		if (0 < deviceSettings.alarmCount) {
			self.drawArc_(
				_dc,
				style[:alarm] as Lang.Number,
				systemStats.battery / 9
			);
		}
	}

	function drawArc_(_dc as Graphics.Dc, _color as Lang.Number, _percent as Lang.Float) as Void {
		_dc.setColor(_color, Graphics.COLOR_TRANSPARENT);

		var degree = (90 - _percent * 3.6).toNumber() % 360;
		_dc.drawArc(
			self.size_x / 2,
			self.size_y / 2,
			self.size_x / 2,
			Graphics.ARC_COUNTER_CLOCKWISE,
			degree,
			90
		);
	}

	function onNightMode(_is_night_mode as Lang.Boolean) as Void {
		self.is_night_mode_ = _is_night_mode;
	}
}

} // module Element
