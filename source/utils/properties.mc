// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Application;
import Toybox.Lang;

module Properties {

function get(_id as Lang.String) as Lang.Number {
	return Application.Properties.getValue(_id) as Lang.Number;
}

} // module Properties
