import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import test from "node:test";
import vm from "node:vm";

class ClassList {
	constructor(initial = []) {
		this.items = new Set(initial);
	}

	add(name) {
		this.items.add(name);
	}

	contains(name) {
		return this.items.has(name);
	}

	toggle(name, force) {
		const enabled = force ?? !this.items.has(name);
		if (enabled) {
			this.items.add(name);
		} else {
			this.items.delete(name);
		}
		return enabled;
	}
}

class Element {
	constructor({ id = "", classes = [], dataset = {}, rect = {} } = {}) {
		this.id = id;
		this.classList = new ClassList(classes);
		this.dataset = { ...dataset };
		this.style = {};
		this.attributes = {};
		this.eventListeners = {};
		this.innerHTML = "";
		this.textContent = "";
		this.tabIndex = 0;
		this.src = "";
		this.alt = "";
		this.rect = {
			left: 0,
			top: 0,
			right: 100,
			bottom: 100,
			width: 100,
			height: 100,
			...rect,
		};
	}

	setAttribute(name, value) {
		this.attributes[name] = String(value);
	}

	getAttribute(name) {
		return this.attributes[name];
	}

	addEventListener(name, handler) {
		this.eventListeners[name] = handler;
	}

	focus() {
		this.ownerDocument.activeElement = this;
		this.eventListeners.focus?.({ currentTarget: this });
	}

	blur() {
		if (this.ownerDocument.activeElement === this) {
			this.ownerDocument.activeElement = null;
		}
	}

	getBoundingClientRect() {
		return this.rect;
	}
}

function makeElement(options) {
	return new Element(options);
}

function createHarness({ hash = "", search = "", prefersDark = false } = {}) {
	const ids = new Map();
	const all = [];

	const documentElement = makeElement();
	const document = {
		activeElement: null,
		documentElement,
		getElementById(id) {
			return ids.get(id);
		},
		querySelectorAll(selector) {
			const className = selector.startsWith(".") ? selector.slice(1) : selector;
			return all.filter((element) => element.classList.contains(className));
		},
	};

	const register = (element) => {
		element.ownerDocument = document;
		all.push(element);
		if (element.id) {
			ids.set(element.id, element);
		}
		return element;
	};

	register(makeElement({ id: "detailPanel", rect: { left: -260, top: 20, right: -20, bottom: 360, width: 240, height: 340 } }));
	register(makeElement({ id: "watchStage", rect: { left: 0, top: 0, right: 400, bottom: 400, width: 400, height: 400 } }));
	register(makeElement({ id: "guideLayer" }));
	register(makeElement({ id: "guideLine" }));
	register(makeElement({ id: "faceRing" }));
	const watchFace = register(makeElement({ id: "watchFace" }));
	const pageLede = register(makeElement({ id: "pageLede" }));
	const supportedDevices = register(makeElement({ id: "supportedDevices" }));
	const supportedLanguages = register(makeElement({ id: "supportedLanguages" }));

	for (const feature of ["general", "top", "status", "clock", "gauges", "bottom", "battery"]) {
		register(makeElement({
			classes: ["hotspot"],
			dataset: { feature },
			rect: { left: 100, top: 100, right: 140, bottom: 140, width: 40, height: 40 },
		}));
	}

	for (const mode of ["auto", "light", "dark"]) {
		register(makeElement({ classes: ["theme-option"], dataset: { themeMode: mode } }));
	}

	for (const view of ["normal", "aod"]) {
		register(makeElement({ classes: ["view-option"], dataset: { watchView: view } }));
	}

	const mediaListeners = [];
	const context = {
		console,
		document,
		HTMLElement: Element,
		Number,
		URLSearchParams,
		window: {
			location: { hash, search },
			matchMedia(query) {
				return {
					matches: query.includes("prefers-color-scheme") ? prefersDark : false,
					addEventListener(_event, handler) {
						mediaListeners.push(handler);
					},
				};
			},
			addEventListener() {},
			PHASE_SETTINGS: {
				supportedDevices: ["Forerunner 255", "Fenix 7X / tactix 7 / quatix 7X / Enduro 2"],
				supportedLanguages: [
					{ code: "eng", name: "English" },
					{ code: "pol", name: "Polish" },
				],
				groups: [
					{
						region: "clock",
						title: "Clock",
						settings: [{ title: "Foreground", type: "list", options: [{ label: "White", value: 16777215 }] }],
					},
					{
						region: "top",
						title: "Top",
						settings: [
							{ title: "Data", type: "list", options: [{ label: "Rain", value: 18 }] },
							{ title: "Accent", type: "list", options: [{ label: "Orange", value: 11162880 }] },
							{ title: "Width", type: "numeric", min: "1", max: "5" },
						],
					},
					{
						region: "bottom",
						title: "Bottom",
						settings: [
							{ title: "Data", type: "list", options: [{ label: "Steps", value: 23 }] },
							{ title: "Accent", type: "list", options: [{ label: "Orange", value: 11162880 }] },
							{ title: "Width", type: "numeric", min: "1", max: "5" },
						],
					},
				],
			},
		},
		requestAnimationFrame(callback) {
			callback();
		},
	};

	for (const element of all) {
		element.ownerDocument = document;
	}

	vm.createContext(context);
	vm.runInContext(readFileSync(new URL("../app.js", import.meta.url), "utf8"), context);

	return {
		all,
		context,
		document,
		mediaListeners,
		pageLede,
		supportedDevices,
		supportedLanguages,
		watchFace,
	};
}

test("computes stable hotspot geometry from watch face regions", () => {
	const { context } = createHarness();

	const boxes = context.computedHotspots();
	const rounded = (value) => Number(value.toFixed(1));

	assert.deepEqual(Object.keys(boxes), ["general", "top", "status", "clock", "gauges", "bottom", "battery"]);
	assert.equal(rounded(boxes.clock.left), 23.8);
	assert.equal(rounded(boxes.clock.width), 52.7);
	assert.equal(rounded(boxes.top.top), 26.6);
	assert.equal(rounded(boxes.top.height), 17.4);
});

test("converts numeric color values to padded css hex values", () => {
	const { context } = createHarness();

	assert.equal(context.colorFromValue(0), "#000000");
	assert.equal(context.colorFromValue(255), "#0000ff");
	assert.equal(context.colorFromValue(16777215), "#ffffff");
	assert.equal(context.colorFromValue("not-a-number"), null);
});

test("applies theme mode and resolves auto from system preference", () => {
	const { all, context, document } = createHarness({ prefersDark: true });

	context.applyTheme("auto");

	assert.equal(document.documentElement.dataset.themeMode, "auto");
	assert.equal(document.documentElement.dataset.theme, "dark");
	assert.equal(
		all.find((element) => element.dataset.themeMode === "auto").getAttribute("aria-pressed"),
		"true",
	);

	context.applyTheme("light");

	assert.equal(document.documentElement.dataset.themeMode, "light");
	assert.equal(document.documentElement.dataset.theme, "light");
	assert.equal(
		all.find((element) => element.dataset.themeMode === "dark").getAttribute("aria-pressed"),
		"false",
	);
});

test("switches to always-on view and hides unsupported hotspots", () => {
	const { all, context, pageLede, watchFace } = createHarness();

	context.applyWatchView("aod");

	assert.equal(watchFace.src, "assets/aod.png");
	assert.equal(watchFace.alt, "phase0 always-on watch face on a Garmin watch");
	assert.match(pageLede.textContent, /only the essentials/);
	assert.match(pageLede.textContent, /battery state/);

	const byFeature = Object.fromEntries(
		all
			.filter((element) => element.classList.contains("hotspot"))
			.map((element) => [element.dataset.feature, element]),
	);

	assert.equal(byFeature.clock.classList.contains("is-hidden"), false);
	assert.equal(byFeature.battery.tabIndex, 0);
	assert.equal(byFeature.top.classList.contains("is-hidden"), true);
	assert.equal(byFeature.top.tabIndex, -1);
	assert.equal(byFeature.top.getAttribute("aria-hidden"), "true");
	assert.equal(byFeature.bottom.classList.contains("is-hidden"), true);
});

test("falls back to normal view for unknown view names", () => {
	const { all, context, pageLede, watchFace } = createHarness();

	context.applyWatchView("missing");

	assert.equal(watchFace.src, "assets/normal.png");
	assert.match(pageLede.textContent, /fast human scanning/);
	assert.match(pageLede.textContent, /unified retro style/);
	assert.equal(
		all.find((element) => element.dataset.watchView === "normal").getAttribute("aria-pressed"),
		"true",
	);
});

test("renders setting option markup for boolean numeric and color settings", () => {
	const { context } = createHarness();

	assert.match(context.optionsMarkup({ type: "boolean" }), /boolean-toggle/);
	assert.match(context.optionsMarkup({ type: "numeric", min: "2", max: "8" }), /Range 2-8/);
	assert.match(
		context.optionsMarkup({
			title: "Accent",
			type: "list",
			options: [{ label: "Red", value: 16711680 }],
		}),
		/background:#ff0000/,
	);
});

test("renders alternative setting guidance for middle metric regions", () => {
	const { context, document } = createHarness();

	context.renderPanel("top");
	const topHtml = document.getElementById("detailPanel").innerHTML;

	assert.match(topHtml, /panel-note/);
	assert.match(topHtml, /alternative top middle metrics/);

	context.renderPanel("bottom");
	const bottomHtml = document.getElementById("detailPanel").innerHTML;

	assert.match(bottomHtml, /panel-note/);
	assert.match(bottomHtml, /alternative bottom middle metrics/);
});

test("middle metric feature copy matches exposed settings", () => {
	const { context, document } = createHarness();

	for (const feature of ["top", "bottom"]) {
		context.renderPanel(feature);
		const html = document.getElementById("detailPanel").innerHTML;

		assert.match(html, /Data/);
		assert.match(html, /Accent/);
		assert.match(html, /Width/);
		assert.doesNotMatch(html, /\bicon\b/i);
		assert.doesNotMatch(html, /\bpadding\b/i);
		assert.doesNotMatch(html, /\bgauge behavior\b/i);
	}
});

test("renders supported devices and languages from generated docs data", () => {
	const { supportedDevices, supportedLanguages } = createHarness();

	assert.match(supportedDevices.innerHTML, /Forerunner 255/);
	assert.match(supportedDevices.innerHTML, /Fenix 7X/);
	assert.match(supportedLanguages.innerHTML, /English/);
	assert.match(supportedLanguages.innerHTML, /support-code/);
	assert.match(supportedLanguages.innerHTML, /eng/);
});
