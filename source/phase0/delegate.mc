// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.WatchUi;

import Toybox.Lang;
import Toybox.Application;

module Phase0 {

class Delegate extends WatchUi.WatchFaceDelegate {
	hidden var view_ as View;

	function initialize(_view as View) {
		WatchFaceDelegate.initialize();

		view_ = _view;
	}

	// Get a Drawable for highlighting purposes.
	//function getComplicationDrawable(complication as Application.WatchFaceConfig.ComplicationRef) as WatchUi.Drawable or WatchUi.ComplicationDrawableRef or Null {
	//}

	// Handle a partial update exceeding the power budget.
	//function onPowerBudgetExceeded(powerInfo as WatchUi.WatchFacePowerInfo) as Void {
	//}

	// Called when user does a touch and hold.
	//function onPress(clickEvent as WatchUi.ClickEvent) as Lang.Boolean {
	//}

	// A screen tap event has occurred.
	//function onTap(clickEvent as WatchUi.ClickEvent) as Lang.Boolean {
	//}

	// A watchface config change has occurred.
	//function onWatchFaceConfigEdited(options as { :configId as Application.WatchFaceConfig.Id, :type as WatchUi.WatchFaceConfigType or Null, :committed as Lang.Boolean }) as Void {
	//}

	// Set the selected complication field.
	//function setSelectedComplication(complicationIdentifier as Lang.Number) as Void {
	//}

}

} // module Phase0
