// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Weather;

module Label {

class Weather extends Base {
	var size_x as Lang.Number = 0;

	hidden var unitsSystem_ as System.UnitsSystem;

	hidden var regular_styles_ as Lang.Array<Label.Style>;
	hidden var small_styles_ as Lang.Array<Label.Style>;
	hidden var tiny_styles_ as Lang.Array<Label.Style>;

	function initialize() {
		Base.initialize();

		self.regular_styles_ = [
			new Label.Style(Font.DOT_REGULAR, 0x555555),
		];
		self.small_styles_ = [
			new Label.Style(Font.DOT_SMALL, 0xAAAAAA),
		];
		self.tiny_styles_ = [
			new Label.Style(Font.DOT_TINY, 0xAAAAAA),
		];

		self.styles = self.regular_styles_;

		var deviceSettings = System.getDeviceSettings();

		self.unitsSystem_ = deviceSettings.distanceUnits;
	}

	function refresh(_dc as Graphics.Dc) as Void {
		var maybeCurrentConditions = Weather.getCurrentConditions();
		if (maybeCurrentConditions != null) {
			var currentConditions = maybeCurrentConditions;

			self.label_ = "";

			if (currentConditions.condition != null) {
				var condition = currentConditions.condition as Lang.Number;

				self.label_ += Application.loadResource(Resources.CONDITIONS[condition]) as Lang.String;
			}

			if (currentConditions.temperature != null) {
				var temperature = currentConditions.temperature as Lang.Numeric;
				var unit = "C";

				if (self.unitsSystem_ == System.UNIT_STATUTE) {
					temperature = (temperature * 1.8) + 32;
					unit = "F";
				}

				self.label_ += "  ";
				self.label_ += temperature.toNumber().format("%d");
				self.label_ += unit;
			}

			if (_dc.getTextWidthInPixels(self.label_, self.regular_styles_[0].font) <= self.size_x) {
				self.styles = self.regular_styles_;
			} else if (_dc.getTextWidthInPixels(self.label_, self.small_styles_[0].font) <= self.size_x) {
				self.styles = self.small_styles_;
			} else {
				self.styles = self.tiny_styles_;
			}
		}
	}
}

} // module Label
