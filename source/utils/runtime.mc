// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Lang;
import Toybox.System;
import Toybox.Time;

module Runtime {
	var clock as System.ClockTime = System.getClockTime();
	var now as Time.Moment = Time.now();
	var today as Time.Moment = Time.today();
	var now_info as Time.Gregorian.Info = Time.Gregorian.info(
		now,
		Time.FORMAT_SHORT
	);
	var since_midnight as Time.Duration = now.subtract(today) as Time.Duration;
	var day_seconds as Lang.Number =
		now_info.hour * 3600 + now_info.min * 60 + now_info.sec;

	function refresh() as Void {
		clock = System.getClockTime();
		now = Time.now();
		today = Time.today();
		now_info = Time.Gregorian.info(now, Time.FORMAT_SHORT);
		since_midnight = now.subtract(today) as Time.Duration;
		day_seconds = now_info.hour * 3600 + now_info.min * 60 + now_info.sec;
	}

	function partialRefresh() as Void {
		clock = System.getClockTime();
	}
} // module Runtime
