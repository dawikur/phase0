// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Lang;

module Utils {

function joinStr(
	_separator as Lang.String, _tokens as Lang.Array<Lang.String>
) as Lang.String {
	var result = "";

	var i = 0;
	var tokens_size = _tokens.size();
	for (; i < tokens_size; ++i) {
		var token = _tokens[i];

		if (token.length() != 0) {
			result += token;
			++i;
			break;
		}
	}

	for (; i < tokens_size; ++i) {
		var token = _tokens[i];

		if (token.length() != 0) {
			result += _separator;
			result += token;
		}
	}

	return result;
}

function repeatStr(_str as Lang.String, _count as Lang.Number) as Lang.String {
	var result = "";

	for (var i = 0; i < _count; ++i) {
		result += _str;
	}

	return result;
}

} // module Utils
