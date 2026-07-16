const settingsData = window.PHASE_SETTINGS || { groups: [] };

const featureContent = {
	general: {
		kicker: "General settings",
		title: "Global palette for the whole face",
		copy: "Theme settings define the accent, foreground, shade and background used by the watch face. Hovering here highlights the shared visual layer behind every widget.",
		regions: ["theme"],
	},
	top: {
		kicker: "Upper widgets",
		title: "Context and compact metrics",
		copy: "The upper area is built for quick context such as time-of-day, weather, environmental and compact metric data. Each middle slot can choose data, accent and width.",
		alternativeCopy: "Top Middle can also have alternative settings. When alternatives are configured, long-pressing the clock switches between the base and alternative top middle metrics.",
		regions: ["top"],
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
		copy: "Clock settings control foreground, background and height so the time can stay prominent across different visual themes.",
		regions: ["clock"],
	},
	gauges: {
		kicker: "Progress gauges",
		title: "Side bars for bounded metrics",
		copy: "Gauge widgets are intended for values with a useful maximum, such as Body Battery, stress or movement progress.",
		regions: ["gauges"],
	},
	bottom: {
		kicker: "Lower metrics",
		title: "Activity, health and progress data",
		copy: "Lower slots are built for metric-heavy activity, health and progress data. Each middle slot can choose data, accent and width.",
		alternativeCopy: "Bottom Middle can also have alternative settings. When alternatives are configured, long-pressing the clock switches between the base and alternative bottom middle metrics.",
		regions: ["bottom"],
	},
	battery: {
		kicker: "Battery slot",
		title: "Battery status stays visible at the base",
		copy: "The bottom outer slot can show battery-oriented data or another compact widget while staying separate from the lower metric row.",
		regions: ["battery"],
	},
};

const panel = document.getElementById("detailPanel");
const stage = document.getElementById("watchStage");
const guideLayer = document.getElementById("guideLayer");
const guideLine = document.getElementById("guideLine");
const faceRing = document.getElementById("faceRing");
const hotspots = Array.from(document.querySelectorAll(".hotspot"));
const themeButtons = Array.from(document.querySelectorAll(".theme-option"));
const viewButtons = Array.from(document.querySelectorAll(".view-option"));
const watchFace = document.getElementById("watchFace");
const pageLede = document.getElementById("pageLede");
const supportedDevicesList = document.getElementById("supportedDevices");
const supportedLanguagesList = document.getElementById("supportedLanguages");
const systemTheme = window.matchMedia("(prefers-color-scheme: dark)");
let activeFeature = "general";
let activeView = "normal";

const watchViews = {
	normal: {
		label: "phase0 normal watch face on a Garmin watch",
		lede: "Normal mode is built for fast human scanning: time, conditions and daily progress resolve into clear visual reads. Gauges add completeness cues to bottom metrics, condition icons stay recognizable at a glance, and the dense layout keeps a unified retro style without giving up readability.",
		src: "assets/normal.png",
		fallback: "assets/normal.png",
		features: ["general", "top", "status", "clock", "gauges", "bottom", "battery"],
	},
	aod: {
		label: "phase0 always-on watch face on a Garmin watch",
		lede: "Always-on mode keeps only the essentials: the time, battery state for the charge-or-not decision, and quiet status signals for alarms, notifications and connection state.",
		src: "assets/aod.png",
		fallback: "assets/aod.png",
		features: ["status", "clock", "battery"],
	},
};

const hotspotGeometry = {
	// Face is absolute, in percentages relative to the Garmin device overlay.
	// Other regions are percentages relative to the face box.
	// Top, bottom, status and gauges can be tuned independently when regions need
	// different hit areas than the visual bounds suggest.
	face: { left: 16.25, top: 26.60, right: 84.73, bottom: 76.20 },
	top: { left: 5, top: 0, right: 95, bottom: 35.08 },
	status: { left: 3.65, top: 35.08, right: 12.05, bottom: 64.72 },
	clock: { left: 11.03, top: 35.08, right: 87.98, bottom: 64.72 },
	gauges: { left: 86.96, top: 35.08, right: 95.50, bottom: 64.72 },
	bottom: { left: 5, top: 64.72, right: 95, bottom: 90.51 },
	battery: { left: 40.52, top: 88.51, right: 59.65, bottom: 98.19 },
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
	const status = faceRelativeBox(face, hotspotGeometry.status);
	const clock = faceRelativeBox(face, hotspotGeometry.clock);
	const gauges = faceRelativeBox(face, hotspotGeometry.gauges);
	const bottom = faceRelativeBox(face, hotspotGeometry.bottom);
	const battery = faceRelativeBox(face, hotspotGeometry.battery);
	const sideWidth = clock.left - face.left;

	return {
		general: boxFromEdges(
			face.left - sideWidth * 0.45,
			face.top + (face.bottom - face.top) * 0.34,
			face.left + sideWidth * 0.55,
			face.top + (face.bottom - face.top) * 0.48
		),
		top,
		status,
		clock,
		gauges,
		bottom,
		battery,
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

function resolvedTheme(mode) {
	return mode === "auto" ? (systemTheme.matches ? "dark" : "light") : mode;
}

function applyTheme(mode) {
	document.documentElement.dataset.themeMode = mode;
	document.documentElement.dataset.theme = resolvedTheme(mode);

	themeButtons.forEach((button) => {
		button.setAttribute("aria-pressed", String(button.dataset.themeMode === mode));
	});
}

function visibleHotspots() {
	return hotspots.filter((hotspot) => !hotspot.classList.contains("is-hidden"));
}

function applyWatchView(view) {
	const nextView = watchViews[view] ? view : "normal";
	const config = watchViews[nextView];

	activeView = nextView;
	watchFace.dataset.fallbackApplied = "";
	watchFace.src = config.src;
	watchFace.alt = config.label;
	pageLede.textContent = config.lede;

	hotspots.forEach((hotspot) => {
		const visible = config.features.includes(hotspot.dataset.feature);
		hotspot.classList.toggle("is-hidden", !visible);
		hotspot.tabIndex = visible ? 0 : -1;
		hotspot.setAttribute("aria-hidden", String(!visible));
	});

	viewButtons.forEach((button) => {
		button.setAttribute("aria-pressed", String(button.dataset.watchView === nextView));
	});

	applyHotspotGeometry();

	if (!config.features.includes(activeFeature)) {
		activate(config.features.includes("general") ? "general" : "clock");
	} else {
		activate(activeFeature);
	}
}

watchFace.addEventListener("error", (event) => {
	if (event.currentTarget.dataset.fallbackApplied) {
		return;
	}
	event.currentTarget.dataset.fallbackApplied = "true";
	event.currentTarget.src = watchViews[activeView].fallback;
});

function colorFromValue(value) {
	const numeric = Number(value);
	if (!Number.isFinite(numeric)) {
		return null;
	}
	return `#${numeric.toString(16).padStart(6, "0")}`;
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
			settingsData.supportedDevices || []
		);
	}

	if (supportedLanguagesList) {
		supportedLanguagesList.innerHTML = supportListMarkup(
			settingsData.supportedLanguages || [],
			(language) => `${language.name} <span class="support-code">${language.code}</span>`
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
		return `<span class="boolean-toggle"><span>On</span><span>Off</span></span>`;
	}

	if (setting.type === "numeric") {
		const min = setting.min ?? "0";
		const max = setting.max ?? "10";
		return `<span class="option-pill">Range ${min}-${max}</span>`;
	}

	return setting.options.map((option) => {
		const color = setting.title === "Accent" || setting.title === "Foreground" || setting.title === "Background" || setting.title === "Shade"
			? colorFromValue(option.value)
			: null;
		if (color) {
			return `<span class="option-pill is-color"><span class="swatch" style="background:${color}"></span>${option.label}</span>`;
		}
		return `<span class="option-pill">${option.label}</span>`;
	}).join("");
}

function settingMarkup(setting) {
	return `
		<div class="setting-row">
			<div class="setting-name">${setting.title}</div>
			<div class="setting-options">${optionsMarkup(setting)}</div>
		</div>
	`;
}

function groupMarkup(group) {
	return `
		<section class="setting-group">
			<div class="group-head">
				<h3>${group.title}</h3>
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
			<p class="panel-kicker">${content.kicker}</p>
			<h2 class="panel-title">${content.title}</h2>
			<p class="panel-copy">${content.copy}</p>
			${alternativeNote}
			${groups.length ? groups.map(groupMarkup).join("") : "<p class=\"panel-copy\">Settings data has not been generated yet.</p>"}
		</div>
	`;
}

function updateGuide(feature) {
	const hotspot = hotspots.find((item) => item.dataset.feature === feature);
	if (!hotspot || window.matchMedia("(max-width: 980px)").matches) {
		return;
	}

	const stageRect = stage.getBoundingClientRect();
	const hotspotRect = hotspot.getBoundingClientRect();
	const panelRect = panel.getBoundingClientRect();

	const startX = hotspotRect.left + hotspotRect.width / 2 - stageRect.left;
	const startY = hotspotRect.top + hotspotRect.height / 2 - stageRect.top;
	const endX = panelRect.right - stageRect.left - 10;
	const endY = Math.min(
		Math.max(startY, panelRect.top - stageRect.top + 28),
		panelRect.bottom - stageRect.top - 28
	);

	guideLayer.setAttribute("viewBox", `0 0 ${stageRect.width} ${stageRect.height}`);
	guideLine.setAttribute("x1", startX);
	guideLine.setAttribute("y1", startY);
	guideLine.setAttribute("x2", endX);
	guideLine.setAttribute("y2", endY);
}

function activate(feature) {
	activeFeature = feature;
	hotspots.forEach((hotspot) => {
		hotspot.classList.toggle("is-active", hotspot.dataset.feature === feature);
	});
	faceRing.classList.toggle("is-active", feature === "general");
	renderPanel(feature);
	requestAnimationFrame(() => updateGuide(feature));
}

function focusFeature(feature) {
	const hotspot = hotspots.find((item) => item.dataset.feature === feature);
	if (!hotspot) {
		return;
	}

	hotspot.focus({ preventScroll: true });
	activate(feature);
}

function cycleHotspotFocus(backwards) {
	const focusableHotspots = visibleHotspots();
	const currentIndex = focusableHotspots.findIndex((hotspot) => hotspot.dataset.feature === activeFeature);
	const fallbackIndex = 0;
	const startIndex = currentIndex === -1 ? fallbackIndex : currentIndex;
	const nextIndex = (startIndex + (backwards ? -1 : 1) + focusableHotspots.length) % focusableHotspots.length;

	focusFeature(focusableHotspots[nextIndex].dataset.feature);
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

themeButtons.forEach((button) => {
	button.addEventListener("click", () => applyTheme(button.dataset.themeMode));
});

viewButtons.forEach((button) => {
	button.addEventListener("click", () => applyWatchView(button.dataset.watchView));
});

systemTheme.addEventListener("change", () => {
	if (document.documentElement.dataset.themeMode === "auto") {
		applyTheme("auto");
	}
});

window.addEventListener("resize", () => {
	applyHotspotGeometry();
	updateGuide(activeFeature);
});
window.addEventListener("keydown", (event) => {
	if (event.key === "Tab") {
		event.preventDefault();
		cycleHotspotFocus(event.shiftKey);
		return;
	}

	if (event.key === "Escape") {
		focusFeature(watchViews[activeView].features.includes("general") ? "general" : "clock");
	}
});

const initialFeature = window.location.hash.slice(1);
if (featureContent[initialFeature]) {
	activeFeature = initialFeature;
}

const urlParams = new URLSearchParams(window.location.search);
const initialTheme = urlParams.get("theme");
const initialView = urlParams.get("view");
const themeMode = ["auto", "light", "dark"].includes(initialTheme)
	? initialTheme
	: document.documentElement.dataset.themeMode || "auto";

applyHotspotGeometry();
applyTheme(themeMode);
renderSupportMeta();
applyWatchView(initialView || "normal");
