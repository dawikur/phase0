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
	constructor({ id = "", classes = [], dataset = {}, rect = {}, tagName = "div", href = "" } = {}) {
		this.id = id;
		this.tagName = tagName.toUpperCase();
		this.classList = new ClassList(classes);
		this.dataset = { ...dataset };
		this.style = {};
		this.attributes = {};
		this.eventListeners = {};
		this.innerHTML = "";
		this.textContent = "";
		this.hidden = false;
		this.tabIndex = 0;
		this.href = href;
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

function createHarness({ hash = "", search = "", prefersDark = false, pathname = "/", protocol = "http:" } = {}) {
	const ids = new Map();
	const all = [];

	const documentElement = makeElement({ dataset: { phaseViewControl: "" } });
	const document = {
		activeElement: null,
		documentElement,
		getElementById(id) {
			return ids.get(id);
		},
		querySelectorAll(selector) {
			if (selector === "a[data-state-transfer]") {
				return all.filter((element) => element.tagName === "A" && "stateTransfer" in element.dataset);
			}
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
	register(makeElement({ id: "faceRing" }));
	const watchFace = register(makeElement({ id: "watchFace" }));
	register(makeElement({ id: "watchFaceAod" }));
	const pageLede = register(makeElement({ id: "pageLede" }));
	pageLede.textContent = "Shared normal description";
	const supportedDevices = register(makeElement({ id: "supportedDevices" }));
	const supportedLanguages = register(makeElement({ id: "supportedLanguages" }));

	for (const feature of ["global", "top", "top_outer", "status", "clock", "gauges", "bottom", "bottom_outer"]) {
		register(makeElement({
			classes: ["hotspot"],
			dataset: { feature },
			rect: { left: 100, top: 100, right: 140, bottom: 140, width: 40, height: 40 },
		}));
	}

	for (const mode of ["auto", "light", "dark"]) {
		register(makeElement({ classes: ["ui-theme-option"], dataset: { themeMode: mode } }));
	}

	for (const view of ["normal", "aod"]) {
		register(makeElement({ classes: ["ui-view-option"], dataset: { watchView: view } }));
	}
	const stateTransferLink = register(makeElement({
		tagName: "a",
		dataset: { stateTransfer: "" },
		href: "http://example.test/mip64-palette/",
	}));

	const mediaListeners = [];
	const windowListeners = {};
	const historyCalls = [];
	const context = {
		console,
		document,
		HTMLElement: Element,
		Number,
		URL,
		URLSearchParams,
		window: {
			location: { hash, search, pathname, protocol, href: `http://example.test${pathname}` },
			history: {
				replaceState(...args) {
					historyCalls.push(args);
				},
			},
			matchMedia(query) {
				return {
					matches: query.includes("prefers-color-scheme") ? prefersDark : false,
					addEventListener(_event, handler) {
						mediaListeners.push(handler);
					},
				};
			},
			addEventListener(event, handler) {
				windowListeners[event] = handler;
			},
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
						id: "TopOuter",
						region: "top_outer",
						title: "Top",
						settings: [{ title: "Content", type: "list", options: [{ label: "Battery percentage", value: 1 }, { label: "Dawn or dusk with moon", value: 2 }] }],
					},
					{
						id: "TopMiddle",
						hasAlternative: true,
						region: "top",
						title: "Top Metrics",
						settings: [
							{ title: "Data", type: "list", options: [{ label: "Rain", value: 18 }] },
							{ title: "Accent", type: "list", options: [{ label: "Orange", value: 11162880 }] },
							{ title: "Width", type: "list", options: [{ label: "Auto", value: -1 }, { label: "1", value: 1 }, { label: "10", value: 10 }] },
						],
					},
					{
						id: "BottomOuter",
						region: "bottom_outer",
						title: "Bottom",
						settings: [{ title: "Content", type: "list", options: [{ label: "Battery percentage", value: 1 }, { label: "Dawn or dusk with sun", value: 2 }] }],
					},
					{
						id: "BottomMiddle",
						hasAlternative: false,
						region: "bottom",
						title: "Bottom Metrics",
						settings: [
							{ title: "Data", type: "list", options: [{ label: "Steps", value: 23 }] },
							{ title: "Accent", type: "list", options: [{ label: "Orange", value: 11162880 }] },
							{ title: "Width", type: "list", options: [{ label: "Auto", value: -1 }, { label: "1", value: 1 }, { label: "10", value: 10 }] },
						],
					},
				],
			},
		},
		requestAnimationFrame(callback) {
			callback();
		},
	};

	const updateStateTransferLinks = () => {
		for (const link of all.filter((element) => element.tagName === "A" && "stateTransfer" in element.dataset)) {
			const target = new URL(link.href, context.window.location.href);
			target.search = context.window.location.search;
			link.href = target.href;
		}
	};
	const setOwnedParameter = (name, value, defaultValue) => {
		const parameters = new URLSearchParams(context.window.location.search);
		if (value == null || value === defaultValue) parameters.delete(name);
		else parameters.set(name, value);
		context.window.location.search = parameters.toString() ? `?${parameters}` : "";
		updateStateTransferLinks();
	};
	const setOwnedParameters = (parameters) => {
		parameters.forEach(({ name, value, defaultValue }) => setOwnedParameter(name, value, defaultValue));
	};
	context.window.SiteUi = {
		theme: {
			applyTheme(mode, { updateUrl = true } = {}) {
				const nextMode = ["auto", "light", "dark"].includes(mode) ? mode : "auto";
				documentElement.dataset.themeMode = nextMode;
				documentElement.dataset.theme = nextMode === "auto" ? (prefersDark ? "dark" : "light") : nextMode;
				all.filter((element) => element.classList.contains("ui-theme-option")).forEach((button) => {
					button.setAttribute("aria-pressed", String(button.dataset.themeMode === nextMode));
				});
				if (updateUrl) setOwnedParameter("theme", nextMode, "auto");
			},
			resolveTheme(mode) {
				return mode === "auto" ? (prefersDark ? "dark" : "light") : mode;
			},
		},
		url: { setOwnedParameter, setOwnedParameters, updateTransferLinks: updateStateTransferLinks },
	};
	context.window.SiteUi.theme.applyTheme(new URLSearchParams(search).get("theme"), { updateUrl: false });

	for (const element of all) {
		element.ownerDocument = document;
	}

	vm.createContext(context);
	vm.runInContext(readFileSync(new URL("../theme.js", import.meta.url), "utf8"), context);
	vm.runInContext(readFileSync(new URL("../app.js", import.meta.url), "utf8"), context);

	return {
		all,
		context,
		document,
		mediaListeners,
		windowListeners,
		historyCalls,
		pageLede,
		supportedDevices,
		supportedLanguages,
		stateTransferLink,
		watchFace,
	};
}

test("computes stable hotspot geometry from watch face regions", () => {
	const { context } = createHarness();

	const boxes = context.computedHotspots();
	const rounded = (value) => Number(value.toFixed(1));

	assert.deepEqual(Object.keys(boxes), ["global", "top", "top_outer", "status", "clock", "gauges", "bottom", "bottom_outer"]);
	assert.equal(rounded(boxes.clock.left), 25.2);
	assert.equal(rounded(boxes.clock.width), 49.8);
	assert.equal(rounded(boxes.top.top), 32.9);
	assert.equal(rounded(boxes.top.width), rounded(boxes.bottom.width));
	assert.equal(rounded(boxes.top_outer.width), 16.4);
	assert.equal(rounded(boxes.bottom_outer.width), 13.1);
	assert.ok(boxes.top_outer.width > boxes.bottom_outer.width);
	assert.ok(boxes.top_outer.height > boxes.bottom_outer.height);
	assert.equal(rounded(boxes.top.top), rounded(boxes.top_outer.top + boxes.top_outer.height));
	assert.equal(rounded(boxes.bottom.top + boxes.bottom.height), rounded(boxes.bottom_outer.top));
	assert.equal(rounded(boxes.status.top), rounded(boxes.gauges.top));
	assert.equal(rounded(boxes.status.height), rounded(boxes.gauges.height));
	assert.equal(rounded(boxes.status.left + boxes.status.width), rounded(boxes.clock.left));
	assert.equal(rounded(boxes.clock.left + boxes.clock.width), rounded(boxes.gauges.left));
	assert.ok(boxes.status.top > boxes.clock.top);
	assert.ok(boxes.status.top + boxes.status.height < boxes.clock.top + boxes.clock.height);
});

test("converts numeric color values to padded css hex values", () => {
	const { context } = createHarness();

	assert.equal(context.colorFromValue(0), "#000000");
	assert.equal(context.colorFromValue(255), "#0000ff");
	assert.equal(context.colorFromValue(16777215), "#ffffff");
	assert.equal(context.colorFromValue("not-a-number"), null);
	assert.equal(context.colorFromValue(-1), null);
	assert.equal(context.colorFromValue(0x1000000), null);
	assert.equal(context.colorFromValue(1.5), null);
});

test("escapes generated text before inserting it as markup", () => {
	const { context } = createHarness();

	assert.equal(context.escapeHtml(`<phase0 & \"test\">`), "&lt;phase0 &amp; &quot;test&quot;&gt;");
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

test("keeps received parameters and removes defaults only from outgoing links", () => {
	const { document, historyCalls } = createHarness({ search: "?theme=dark" });

	assert.equal(document.documentElement.dataset.themeMode, "dark");
	assert.deepEqual(historyCalls, []);
});

test("updates the palette link without default state parameters", () => {
	const { context, stateTransferLink } = createHarness();

	context.applyTheme("dark");

	assert.equal(stateTransferLink.href, "http://example.test/mip64-palette/?theme=dark");
});

test("preserves unknown parameters while omitting phase defaults", () => {
	const { stateTransferLink } = createHarness({ search: "?contrast=soft&future=enabled&theme=auto&view=normal" });

	assert.equal(stateTransferLink.href, "http://example.test/mip64-palette/?contrast=soft&future=enabled");
});

test("switches to always-on view and hides unsupported hotspots", () => {
	const { all, context, document, pageLede } = createHarness();

	context.applyWatchView("aod");

	assert.equal(document.getElementById("watchFace").classList.contains("is-hidden"), true);
	assert.equal(document.getElementById("watchFaceAod").getAttribute("aria-hidden"), "false");
	assert.match(pageLede.textContent, /only the essentials/);
	assert.match(pageLede.textContent, /battery state/);

	const byFeature = Object.fromEntries(
		all
			.filter((element) => element.classList.contains("hotspot"))
			.map((element) => [element.dataset.feature, element]),
	);

	assert.equal(byFeature.clock.classList.contains("is-hidden"), false);
	assert.equal(byFeature.global.classList.contains("is-hidden"), false);
	assert.equal(byFeature.global.tabIndex, 0);
	assert.equal(byFeature.bottom_outer.tabIndex, 0);
	assert.equal(byFeature.top.classList.contains("is-hidden"), true);
	assert.equal(byFeature.top_outer.classList.contains("is-hidden"), true);
	assert.equal(byFeature.top.tabIndex, -1);
	assert.equal(byFeature.top.getAttribute("aria-hidden"), "true");
	assert.equal(byFeature.top.getAttribute("aria-pressed"), "false");
	assert.equal(byFeature.bottom.classList.contains("is-hidden"), true);
	assert.equal(byFeature.global.getAttribute("aria-pressed"), "true");
	assert.equal(byFeature.global.classList.contains("is-active"), false);
	assert.equal(byFeature.clock.getAttribute("aria-pressed"), "false");
	assert.equal(document.getElementById("faceRing").classList.contains("is-active"), false);
});

test("Escape opens global settings without highlighting the global hotspot", () => {
	const { all, document, windowListeners } = createHarness();
	const global = all.find((element) => element.dataset.feature === "global");
	const clock = all.find((element) => element.dataset.feature === "clock");
	let prevented = false;

	clock.focus();
	windowListeners.keydown({
		key: "Escape",
		preventDefault() {
			prevented = true;
		},
	});

	assert.equal(prevented, true);
	assert.equal(document.activeElement, null);
	assert.equal(global.getAttribute("aria-pressed"), "true");
	assert.equal(global.classList.contains("is-active"), false);
	assert.equal(document.getElementById("faceRing").classList.contains("is-active"), false);

	global.eventListeners.mouseenter({ currentTarget: global });

	assert.equal(global.classList.contains("is-active"), true);
	assert.equal(document.getElementById("faceRing").classList.contains("is-active"), true);
});

test("switching to AoD clears the global highlight when the active hotspot is unavailable", () => {
	const { all, context, document } = createHarness();
	const global = all.find((element) => element.dataset.feature === "global");

	context.activate("top");
	context.applyWatchView("aod");

	assert.equal(global.getAttribute("aria-pressed"), "true");
	assert.equal(global.classList.contains("is-active"), false);
	assert.equal(document.getElementById("faceRing").classList.contains("is-active"), false);
});

test("starts with global settings open but without a hotspot highlight", () => {
	const { all, document } = createHarness();
	const global = all.find((element) => element.dataset.feature === "global");

	assert.equal(global.getAttribute("aria-pressed"), "true");
	assert.equal(global.classList.contains("is-active"), false);
	assert.equal(document.getElementById("faceRing").classList.contains("is-active"), false);
});

test("falls back to normal view for unknown view names", () => {
	const { all, context, pageLede, watchFace } = createHarness();

	context.applyWatchView("missing");

	assert.equal(watchFace.classList.contains("is-hidden"), false);
	assert.equal(pageLede.textContent, "Shared normal description");
	assert.equal(
		all.find((element) => element.dataset.watchView === "normal").getAttribute("aria-pressed"),
		"true",
	);
});

test("renders setting option markup for boolean numeric and color settings", () => {
	const { context } = createHarness();

	assert.match(context.optionsMarkup({ type: "boolean" }), /ui-toggle/);
	assert.match(context.optionsMarkup({ type: "numeric", min: "2", max: "8" }), /Range 2-8/);
	assert.match(
		context.optionsMarkup({
			key: "GaugesAccent0",
			title: "Gauge N Accent",
			type: "list",
			options: [{ label: "Red", value: 16711680 }],
		}),
		/background:#ff0000/,
	);
	const globalColor = context.optionsMarkup({
		key: "ClockShade",
		type: "list",
		options: [{ label: "Global", value: -1 }],
	});
	assert.match(globalColor, />Global<\/span>/);
	assert.doesNotMatch(globalColor, /ui-color-dot/);
});

test("marks the representative setting index as a variable", () => {
	const { context } = createHarness();
	const markup = context.settingMarkup({ title: "Metric N Width", type: "list", options: [] });

	assert.match(markup, /Metric <var>N<\/var> Width/);
	assert.match(context.settingMarkup({ title: "Foreground", type: "list", options: [] }), />Foreground<\/div>/);
	assert.match(
		context.settingMarkup({ title: "Metric N <script>", type: "list", options: [] }),
		/Metric <var>N<\/var> &lt;script&gt;/,
	);
});

test("renders alternative setting guidance for middle metric regions", () => {
	const { context, document } = createHarness();

	context.renderPanel("top");
	const topHtml = document.getElementById("detailPanel").innerHTML;

	assert.match(topHtml, /panel-note/);
	assert.match(topHtml, /alternative top metrics/);

	context.renderPanel("bottom");
	const bottomHtml = document.getElementById("detailPanel").innerHTML;

	assert.doesNotMatch(bottomHtml, /panel-note/);
	assert.doesNotMatch(bottomHtml, /alternative bottom metrics/);
});

test("middle metric feature copy matches exposed settings", () => {
	const { context, document } = createHarness();

	for (const feature of ["top", "bottom"]) {
		context.renderPanel(feature);
		const html = document.getElementById("detailPanel").innerHTML;

		assert.match(html, /Data/);
		assert.match(html, /Width/);
		assert.match(html, /Auto width/);
		assert.doesNotMatch(html, /\bicon\b/i);
		assert.doesNotMatch(html, /\bpadding\b/i);
		assert.doesNotMatch(html, /\bgauge behavior\b/i);
	}
});

test("outer hotspots show battery and sun or moon choices for each slot", () => {
	const { context, document } = createHarness();

	for (const feature of ["top_outer", "bottom_outer"]) {
		context.renderPanel(feature);
		const html = document.getElementById("detailPanel").innerHTML;

		assert.match(html, /Battery or sun and moon/);
		assert.match(html, /Battery percentage/);
		assert.match(html, /Dawn or dusk with (sun|moon)/);
	}
});

test("renders supported devices and languages from generated site data", () => {
	const { supportedDevices, supportedLanguages } = createHarness();

	assert.match(supportedDevices.innerHTML, /Forerunner 255/);
	assert.match(supportedDevices.innerHTML, /Fenix 7X/);
	assert.match(supportedLanguages.innerHTML, /English/);
	assert.match(supportedLanguages.innerHTML, /support-code/);
	assert.match(supportedLanguages.innerHTML, /eng/);
});
