import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import test from "node:test";
import vm from "node:vm";

const palettePage = readFileSync(new URL("../mip64-palette/index.html", import.meta.url), "utf8");
const paletteApp = readFileSync(new URL("../mip64-palette/app.js", import.meta.url), "utf8");
const context = { window: {} };
vm.createContext(context);
vm.runInContext(
	readFileSync(new URL("../mip64-palette/color-names.js", import.meta.url), "utf8"),
	context,
);

test("exports all 64 Garmin MIP color names", () => {
	const names = context.window.MIP64_COLOR_NAMES;

	assert.equal(Object.keys(names).length, 64);
	assert.equal(names["#000000"], "Black");
	assert.equal(names["#FFAA00"], "Pure Orange");
	assert.equal(names["#FFFFFF"], "White");
});

test("palette page shows only color names supplied by settings data", () => {
	assert.doesNotMatch(palettePage, /color-names\.js/);
	assert.match(palettePage, /<script src="app\.js"><\/script>/);
	assert.match(paletteApp, /settingColorNamesByHex\.get\(hex\) \|\| ""/);
});

test("palette page offers accessible in-session sorting controls", () => {
	assert.match(palettePage, /aria-label="Palette sort order"/);
	assert.match(palettePage, /class="ui-segmented-option ui-sort-option" type="button" data-sort-mode="hue"/);
	assert.doesNotMatch(palettePage, /class="ui-theme-option" type="button" data-sort-mode=/);
	assert.match(palettePage, /data-sort-mode="hue" aria-pressed="true">Hue/);
	assert.match(palettePage, /data-sort-mode="lightness" aria-pressed="false">Lightness/);
	assert.match(palettePage, /data-sort-mode="rgb" aria-pressed="false">RGB/);
	assert.match(paletteApp, /sortPalette\(document\.documentElement\.dataset\.paletteSort \|\| "hue"\)/);
});

test("palette page keeps deterministic ordering for each sort mode", () => {
	assert.match(paletteApp, /first\.hue - second\.hue \|\| first\.saturation - second\.saturation \|\| first\.lightness - second\.lightness/);
	assert.match(paletteApp, /first\.lightness - second\.lightness \|\| first\.hue - second\.hue \|\| first\.saturation - second\.saturation/);
	assert.match(paletteApp, /first\.red - second\.red \|\| first\.green - second\.green \|\| first\.blue - second\.blue/);
	assert.match(paletteApp, /palette\.appendChild\(color\.card\)/);
});
