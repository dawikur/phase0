const settingsData = window.PHASE_SETTINGS || { groups: [] };
const screenshotData = (window.PHASE_SCREENSHOTS || []).filter((screenshot) => screenshot.name !== "data-rich");

const featureContent = {
	global: {
		kicker: "Global settings",
		title: "Global palette for the whole face",
		copy: "Global settings define the accent, foreground, shade and background used by the watch face. Clock and gauges can inherit these colors. Hovering here highlights the shared visual layer behind every widget.",
		regions: ["theme"],
	},
	top: {
		kicker: "Top Metrics",
		title: "Context above the clock",
		copy: "The upper middle slots can show weather, environmental and other compact metrics. Each slot can choose data and width. Auto width uses the selected data's default.",
		alternativeCopy: "Top Metrics can also have alternative settings. When alternatives are configured, long-pressing the clock switches between the base and alternative top metrics.",
		regions: ["top"],
	},
	top_outer: {
		kicker: "Top",
		title: "Battery or sun and moon",
		copy: "The top slot can show battery information or sunrise and sunset details, with optional sun or moon icons.",
		regions: ["top_outer"],
	},
	status: {
		kicker: "Status rail",
		title: "Small signals stay out of the way",
		copy: "Status positions can show alarm, Bluetooth state and notifications without competing with the main clock.",
		regions: ["status"],
	},
	clock: {
		kicker: "Main clock",
		title: "The time remains the anchor",
		copy: "Clock settings control foreground, shade and size. Select Global for either color to follow the Global palette.",
		regions: ["clock"],
	},
	gauges: {
		kicker: "Progress gauges",
		title: "Side bars for bounded metrics",
		copy: "Gauge widgets are intended for values with a useful maximum, such as Body Battery, stress or movement progress. Their accent can follow the Global palette.",
		regions: ["gauges"],
	},
	bottom: {
		kicker: "Bottom Metrics",
		title: "Activity, health and progress data",
		copy: "Lower slots are built for metric-heavy activity, health and progress data. Each middle slot can choose data and width. Auto width uses the selected data's default.",
		alternativeCopy: "Bottom Metrics can also have alternative settings. When alternatives are configured, long-pressing the clock switches between the base and alternative bottom metrics.",
		regions: ["bottom"],
	},
	bottom_outer: {
		kicker: "Bottom",
		title: "Battery or sun and moon",
		copy: "The bottom slot can show battery information or sunrise and sunset details, with optional sun or moon icons.",
		regions: ["bottom_outer"],
	},
};

const panel = document.getElementById("detailPanel");
const faceRing = document.getElementById("faceRing");
const hotspots = Array.from(document.querySelectorAll(".hotspot"));
const viewButtons = Array.from(document.querySelectorAll(".ui-view-option"));
const watchFace = document.getElementById("watchFace");
const watchFaceAod = document.getElementById("watchFaceAod");
const pageLede = document.getElementById("pageLede");
const normalLede = pageLede.textContent;
const supportedDevicesList = document.getElementById("supportedDevices");
const supportedLanguagesList = document.getElementById("supportedLanguages");
const screenshotGrid = document.getElementById("screenshotGrid");
let activeFeature = "global";
let activeView = "normal";

const watchViews = {
	normal: {
		label: "phase0 normal watch face on a Garmin watch",
		lede: normalLede,
		src: "assets/screenshots/data-rich.png",
		fallback: "assets/screenshots/data-rich.png",
		features: ["global", "top", "top_outer", "status", "clock", "gauges", "bottom", "bottom_outer"],
	},
	aod: {
		label: "phase0 always-on watch face on a Garmin watch",
		lede: "Always-on mode keeps only the essentials: the time, battery state for the charge-or-not decision, and quiet status signals for alarms, notifications and connection state.",
		src: "assets/screenshots/data-rich-aod.png",
		fallback: "assets/screenshots/data-rich-aod.png",
		features: ["global", "status", "clock", "bottom_outer"],
	},
};

const hotspotGeometry = {
	// Face is absolute, in percentages relative to the Garmin device overlay.
	// Other regions are percentages relative to the face box.
	// Top, bottom, status and gauges can be tuned independently when regions need
	// different hit areas than the visual bounds suggest.
	// Keep middle regions clear of the outer widgets and side regions on the clock.
	face: { left: 16.25, top: 26.60, right: 84.73, bottom: 76.20 },
	top: { left: 5, top: 12.8, right: 95, bottom: 35.08 },
	top_outer: { left: 38, top: 1.61, right: 62, bottom: 12.8 },
	status: { left: 6.1, top: 37.8, right: 13.1, bottom: 62.8 },
	clock: { left: 13.1, top: 35.08, right: 85.8, bottom: 64.72 },
	gauges: { left: 85.8, top: 37.8, right: 92.8, bottom: 62.8 },
	bottom: { left: 5, top: 64.72, right: 95, bottom: 88.51 },
	bottom_outer: { left: 40.52, top: 88.51, right: 59.65, bottom: 98.19 },
};

function boxFromEdges(left, top, right, bottom) {
	return {
		left,
		top,
		width: right - left,
		height: bottom - top,
	};
}

function faceRelativeBox(face, region) {
	const faceWidth = face.right - face.left;
	const faceHeight = face.bottom - face.top;

	return boxFromEdges(
		face.left + faceWidth * (region.left / 100),
		face.top + faceHeight * (region.top / 100),
		face.left + faceWidth * (region.right / 100),
		face.top + faceHeight * (region.bottom / 100)
	);
}

function computedHotspots() {
	const face = hotspotGeometry.face;
	const top = faceRelativeBox(face, hotspotGeometry.top);
	const topOuter = faceRelativeBox(face, hotspotGeometry.top_outer);
	const status = faceRelativeBox(face, hotspotGeometry.status);
	const clock = faceRelativeBox(face, hotspotGeometry.clock);
	const gauges = faceRelativeBox(face, hotspotGeometry.gauges);
	const bottom = faceRelativeBox(face, hotspotGeometry.bottom);
	const bottomOuter = faceRelativeBox(face, hotspotGeometry.bottom_outer);
	const sideWidth = clock.left - face.left;

	return {
		global: boxFromEdges(
			face.left - sideWidth * 0.45,
			face.top + (face.bottom - face.top) * 0.34,
			face.left + sideWidth * 0.55,
			face.top + (face.bottom - face.top) * 0.48
		),
		top,
		top_outer: topOuter,
		status,
		clock,
		gauges,
		bottom,
		bottom_outer: bottomOuter,
	};
}

function applyHotspotGeometry() {
	const boxes = computedHotspots();
	const face = hotspotGeometry.face;

	hotspots.forEach((hotspot) => {
		const box = boxes[hotspot.dataset.feature];
		if (!box) {
			return;
		}

		hotspot.style.left = `${box.left}%`;
		hotspot.style.top = `${box.top}%`;
		hotspot.style.width = `${box.width}%`;
		hotspot.style.height = `${box.height}%`;
	});

	faceRing.style.left = `${face.left}%`;
	faceRing.style.top = `${face.top}%`;
	faceRing.style.width = `${face.right - face.left}%`;
	faceRing.style.height = `${face.bottom - face.top}%`;
}

function applyTheme(mode) {
	window.phaseTheme.apply(mode);
}

function applyWatchView(view) {
	const nextView = watchViews[view] ? view : "normal";
	const config = watchViews[nextView];

	activeView = nextView;
	document.documentElement.dataset.phaseView = nextView;
	window.phaseTheme.updateTransferLinks();
	watchFace.alt = nextView === "normal" ? config.label : "";
	watchFace.setAttribute("aria-hidden", String(nextView !== "normal"));
	watchFace?.classList.toggle("is-hidden", nextView === "aod");
	watchFaceAod?.setAttribute("aria-hidden", String(nextView !== "aod"));
	pageLede.textContent = config.lede;

	hotspots.forEach((hotspot) => {
		const visible = config.features.includes(hotspot.dataset.feature);
		hotspot.classList.toggle("is-hidden", !visible);
		hotspot.tabIndex = visible ? 0 : -1;
		hotspot.setAttribute("aria-hidden", String(!visible));
		hotspot.setAttribute("aria-pressed", String(visible && hotspot.dataset.feature === activeFeature));
	});

	viewButtons.forEach((button) => {
		button.setAttribute("aria-pressed", String(button.dataset.watchView === nextView));
	});

	screenshotGrid?.querySelectorAll(".screenshot-card").forEach((card) => {
		card.classList.toggle("is-aod", nextView === "aod");
		const normalImage = card.querySelector(".screenshot-image--normal");
		const aodImage = card.querySelector(".screenshot-image--aod");
		if (normalImage) {
			normalImage.alt = nextView === "normal" ? normalImage.dataset.normalAlt : "";
			normalImage.setAttribute("aria-hidden", String(nextView !== "normal"));
		}
		if (aodImage) {
			aodImage.alt = nextView === "aod" ? aodImage.dataset.aodAlt : "";
			aodImage.setAttribute("aria-hidden", String(nextView !== "aod"));
		}
	});

	applyHotspotGeometry();

	if (!config.features.includes(activeFeature)) {
		const fallbackFeature = config.features.includes("global") ? "global" : "clock";
		activate(fallbackFeature, fallbackFeature !== "global");
	} else {
		activate(activeFeature, activeFeature !== "global");
	}
}

watchFace.addEventListener("load", () => watchFace.classList.remove("is-loading"));

watchFace.addEventListener("error", (event) => {
	if (event.currentTarget.dataset.fallbackApplied) {
		return;
	}
	event.currentTarget.dataset.fallbackApplied = "true";
	event.currentTarget.src = watchViews[activeView].fallback;
});

function colorFromValue(value) {
	const numeric = Number(value);
	if (!Number.isInteger(numeric) || numeric < 0 || numeric > 0xffffff) {
		return null;
	}
	return `#${numeric.toString(16).padStart(6, "0")}`;
}

function escapeHtml(value) {
	return String(value)
		.replaceAll("&", "&amp;")
		.replaceAll("<", "&lt;")
		.replaceAll(">", "&gt;")
		.replaceAll('"', "&quot;")
		.replaceAll("'", "&#39;");
}

function renderScreenshotGallery() {
	if (!screenshotGrid) {
		return;
	}

	screenshotGrid.innerHTML = screenshotData.map((screenshot) => `
		<figure class="screenshot-card${screenshot.previewSize === "small" ? " screenshot-card--small" : ""}">
			<div class="screenshot-preview">
				<img class="screenshot-image--normal" src="assets/screenshots/${escapeHtml(screenshot.name)}.png" alt="${escapeHtml(screenshot.alt)}" data-normal-alt="${escapeHtml(screenshot.alt)}" loading="lazy">
				<img class="screenshot-image--aod" src="assets/screenshots/${escapeHtml(screenshot.name)}-aod.png" alt="" data-aod-alt="${escapeHtml(screenshot.aodAlt)}" aria-hidden="true" loading="lazy">
			</div>
			<figcaption>
				<strong>${escapeHtml(screenshot.title)}</strong>
				<span>${escapeHtml(screenshot.description)}</span>
			</figcaption>
		</figure>
	`).join("");
}

function supportListMarkup(items, formatter = (item) => item) {
	if (!items.length) {
		return "<li>Not generated yet.</li>";
	}

	return items.map((item) => `<li>${formatter(item)}</li>`).join("");
}

function renderSupportMeta() {
	if (supportedDevicesList) {
		supportedDevicesList.innerHTML = supportListMarkup(
			settingsData.supportedDevices || [],
			escapeHtml
		);
	}

	if (supportedLanguagesList) {
		supportedLanguagesList.innerHTML = supportListMarkup(
			settingsData.supportedLanguages || [],
			(language) => `${escapeHtml(language.name)} <span class="support-code">${escapeHtml(language.code)}</span>`
		);
	}
}

function groupsForFeature(feature) {
	const regions = featureContent[feature].regions;
	return settingsData.groups.filter((group) => regions.includes(group.region));
}

function hasAlternativeGroup(groupId) {
	return settingsData.groups.some(
		(group) => group.id === groupId && group.hasAlternative
	);
}

function alternativeNoteForFeature(feature) {
	if (feature === "top" && hasAlternativeGroup("TopMiddle")) {
		return featureContent.top.alternativeCopy;
	}

	if (feature === "bottom" && hasAlternativeGroup("BottomMiddle")) {
		return featureContent.bottom.alternativeCopy;
	}

	return "";
}

function optionsMarkup(setting) {
	if (setting.type === "boolean") {
		return `<span class="ui-toggle"><span>On</span><span>Off</span></span>`;
	}

	if (setting.type === "numeric") {
		const min = setting.min ?? "0";
		const max = setting.max ?? "10";
		return `<span class="ui-pill ui-pill--stacked-at-mobile">Range ${escapeHtml(min)}-${escapeHtml(max)}</span>`;
	}

	return (setting.options || []).map((option) => {
		const color = /(?:Accent|Foreground|Background|Shade)\d*$/.test(setting.key)
			? colorFromValue(option.value)
			: null;
		if (color) {
			return `<span class="ui-pill ui-pill--color ui-pill--stacked-at-mobile"><span class="ui-color-dot" style="background:${color}"></span>${escapeHtml(option.label)}</span>`;
		}
		return `<span class="ui-pill ui-pill--stacked-at-mobile">${escapeHtml(option.label)}</span>`;
	}).join("");
}

function settingMarkup(setting) {
	const title = escapeHtml(setting.title).replace(/\bN\b/g, "<var>N</var>");
	return `
		<div class="setting-row">
			<div class="setting-name">${title}</div>
			<div class="setting-options">${optionsMarkup(setting)}</div>
		</div>
	`;
}

function groupMarkup(group) {
	return `
		<section class="setting-group">
			<div class="group-head">
				<h3>${escapeHtml(group.title)}</h3>
			</div>
			${group.settings.map(settingMarkup).join("")}
		</section>
	`;
}

function renderPanel(feature) {
	const content = featureContent[feature];
	const groups = groupsForFeature(feature);
	const alternativeCopy = alternativeNoteForFeature(feature);
	const alternativeNote = alternativeCopy
		? `<p class="panel-note">${alternativeCopy}</p>`
		: "";
	panel.innerHTML = `
		<div class="panel-inner">
			<p class="panel-kicker">${escapeHtml(content.kicker)}</p>
			<h2 class="panel-title">${escapeHtml(content.title)}</h2>
			<p class="panel-copy">${escapeHtml(content.copy)}</p>
			${alternativeNote}
			${groups.length ? groups.map(groupMarkup).join("") : "<p class=\"panel-copy\">Settings data has not been generated yet.</p>"}
		</div>
	`;
}

function activate(feature, highlight = true) {
	activeFeature = feature;
	hotspots.forEach((hotspot) => {
		hotspot.classList.toggle("is-active", highlight && hotspot.dataset.feature === feature);
		hotspot.setAttribute("aria-pressed", String(hotspot.dataset.feature === feature));
	});
	faceRing.classList.toggle("is-active", highlight && feature === "global");
	renderPanel(feature);
}

function blurFocusedHotspot(exceptFeature) {
	const focused = document.activeElement;
	if (!(focused instanceof HTMLElement) || !focused.classList.contains("hotspot")) {
		return;
	}

	if (focused.dataset.feature === exceptFeature) {
		return;
	}

	focused.blur();
}

hotspots.forEach((hotspot) => {
	hotspot.addEventListener("mouseenter", () => {
		blurFocusedHotspot(hotspot.dataset.feature);
		activate(hotspot.dataset.feature);
	});
	hotspot.addEventListener("focus", () => activate(hotspot.dataset.feature));
	hotspot.addEventListener("click", () => activate(hotspot.dataset.feature));
});

viewButtons.forEach((button) => {
	button.addEventListener("click", () => applyWatchView(button.dataset.watchView));
});

window.addEventListener("keydown", (event) => {
	if (event.key !== "Escape") {
		return;
	}

	event.preventDefault();
	blurFocusedHotspot();
	activate("global", false);
});

window.addEventListener("resize", () => {
	applyHotspotGeometry();
});
const initialFeature = window.location.hash.slice(1);
if (featureContent[initialFeature]) {
	activeFeature = initialFeature;
}

const urlParams = new URLSearchParams(window.location.search);
const initialView = document.documentElement.dataset.phaseView || urlParams.get("view");
const themeMode = document.documentElement.dataset.themeMode || "auto";

applyHotspotGeometry();
applyTheme(themeMode);
renderScreenshotGallery();
renderSupportMeta();
applyWatchView(initialView || "normal");

if (!featureContent[initialFeature]) {
	activate("global", false);
}
