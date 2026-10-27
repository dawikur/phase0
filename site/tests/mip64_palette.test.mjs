import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import test from "node:test";
import vm from "node:vm";
import { Element } from "./dom_helpers.mjs";

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

function harness(mode = "hue") {
	const palette = new Element();
	const buttons = ["hue", "lightness", "rgb"].map((sortMode) => new Element({ sortMode }));
	const root = new Element({ paletteSort: mode });
	const copied = [];
	vm.runInNewContext(paletteApp, {
		window: {
			PHASE_SETTINGS: { groups: [{ id: "Global", settings: [{ key: "GlobalAccent", options: [
				{ value: 0xffaa00, label: "Orange from settings" },
				{ value: -1, label: "Invalid" },
			] }] }] },
			phaseTheme: { updateTransferLinks() {} },
			SiteUi: { copy: { withFeedback: async (_button, text) => copied.push(text) } },
		},
		document: {
			documentElement: root,
			getElementById: () => palette,
			querySelectorAll: () => buttons,
			createElement: () => new Element(),
		},
	});
	return { palette, buttons, root, copied, hexes: () => palette.children.map((card) => card.children[1].textContent) };
}

test("renders 64 distinct colors and uses names from settings", async () => {
	const page = harness();
	assert.equal(page.palette.children.length, 64);
	assert.equal(new Set(page.hexes()).size, 64);
	const orange = page.palette.children.find((card) => card.children[1].textContent === "#FFAA00");
	assert.equal(orange.children[2].textContent, "Orange from settings");
	const black = page.palette.children.find((card) => card.children[1].textContent === "#000000");
	assert.equal(black.children[2].textContent, "");
	await orange.children[0].listeners.click();
	assert.deepEqual(page.copied, ["0xFFAA00"]);
});

test("sort controls reorder cards and update selection", () => {
	const page = harness();
	const hueOrder = page.hexes();
	page.buttons[2].listeners.click();
	assert.deepEqual(page.hexes(), [...hueOrder].sort());
	assert.equal(page.root.dataset.paletteSort, "rgb");
	assert.equal(page.buttons[2].attributes["aria-pressed"], "true");
	assert.equal(page.buttons[0].attributes["aria-pressed"], "false");
	page.buttons[1].listeners.click();
	const lightness = page.hexes().map((hex) => {
		const rgb = hex.slice(1).match(/../g).map((part) => Number.parseInt(part, 16));
		return Math.min(...rgb) + Math.max(...rgb);
	});
	assert.deepEqual(lightness, [...lightness].sort((a, b) => a - b));
	page.buttons[0].listeners.click();
	assert.deepEqual(page.hexes(), hueOrder);
	assert.equal(page.palette.children.length, 64);
});

test("restores sort mode and falls back for unknown modes", () => {
	assert.deepEqual(harness("rgb").hexes(), [...harness().hexes()].sort());
	assert.deepEqual(harness("invalid").hexes(), harness("hue").hexes());
	assert.equal(harness("invalid").root.dataset.paletteSort, "hue");
});
