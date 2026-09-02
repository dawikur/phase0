// Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

import Toybox.Lang;
import Toybox.System;
import Toybox.Time;

module Runtime {
	var clock as System.ClockTime = System.getClockTime();
	var day_minute as Lang.Number = clock.hour * 60 + clock.min;
	var day_seconds as Lang.Number = day_minute * 60 + clock.sec;

	var now as Time.Moment = Time.now();
	var today as Time.Moment = Time.today();
	var now_info as Time.Gregorian.Info = Time.Gregorian.info(
		now,
		Time.FORMAT_SHORT
	);

	// Called by every update. Keep this path allocation-free.
	function refreshClock() as Void {
		clock = System.getClockTime();
		day_minute = clock.hour * 60 + clock.min;
		day_seconds = day_minute * 60 + clock.sec;
	}

	// Calendar objects are required only by minute-or-slower consumers.
	function refreshCalendar() as Void {
		now = Time.now();
		today = Time.today();
		now_info = Time.Gregorian.info(now, Time.FORMAT_SHORT);
	}
} // module Runtime
