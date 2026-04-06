// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Lang;
import Toybox.UserProfile;
import Toybox.Complications;

module Data {

class RecoveryTime extends Base {
	function initialize() {
		Base.initialize(
			Complications.COMPLICATION_TYPE_RECOVERY_TIME,
			Resources.load(Rez.Strings.LABEL_RECOVERY_TIME),
			CATEGORY_RECOVERY,
			Fonts.ICON_NONE
		);
	}

	function get_() as Lang.Number or Null {
		return ActivityMonitor.getInfo().timeToRecovery;
	}
}

} // module Data
