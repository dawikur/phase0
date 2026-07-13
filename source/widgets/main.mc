// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Complications;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

module Widgets {
	class Main extends Base {
		function initialize(_type as Complications.Type?) {
			Base.initialize(_type);
		}

		function renderMinimal(_dc as Graphics.Dc) as Void {}
	}
} // module Widgets
