import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import test from "node:test";
import vm from "node:vm";

const palettePage = readFileSync(new URL("../mip64-palette/index.html", import.meta.url), "utf8");
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
	assert.match(palettePage, /SETTING_COLOR_NAMES\.get\(hex\) \|\| ""/);
});

test("palette page offers accessible in-session sorting controls", () => {
	assert.match(palettePage, /aria-label="Palette sort order"/);
	assert.match(palettePage, /class="view-option" type="button" data-sort-mode="hue"/);
	assert.doesNotMatch(palettePage, /class="theme-option" type="button" data-sort-mode=/);
	assert.match(palettePage, /data-sort-mode="hue" aria-pressed="true">Hue/);
	assert.match(palettePage, /data-sort-mode="lightness" aria-pressed="false">Lightness/);
	assert.match(palettePage, /data-sort-mode="rgb" aria-pressed="false">RGB/);
	assert.match(palettePage, /sortPalette\("hue"\)/);
});

test("palette page keeps deterministic ordering for each sort mode", () => {
	assert.match(palettePage, /a\.h - b\.h \|\| a\.s - b\.s \|\| a\.l - b\.l/);
	assert.match(palettePage, /a\.l - b\.l \|\| a\.h - b\.h \|\| a\.s - b\.s/);
	assert.match(palettePage, /a\.r - b\.r \|\| a\.g - b\.g \|\| a\.b - b\.b/);
	assert.match(palettePage, /palette\.appendChild\(color\.card\)/);
});
