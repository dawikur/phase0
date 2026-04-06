// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Lang;
import Toybox.UserProfile;
import Toybox.Complications;
import Toybox.SensorHistory;

module Data {

class BodyBattery extends Base {
	function initialize() {
		Base.initialize(
			Complications.COMPLICATION_TYPE_BODY_BATTERY,
			Resources.load(Rez.Strings.LABEL_BODY_BATTERY),
			CATEGORY_RECOVERY,
			Fonts.ICON_NONE
		);

		self.value_max = 100;
	}

	function getMaybe_() as Lang.Number or Null {
		return self.getSensorHistoryData_(
			SensorHistory.getBodyBatteryHistory({:period => 1})
		) as Lang.Number or Null;
	}
}

} // module Data
