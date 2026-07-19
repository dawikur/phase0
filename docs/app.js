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
const faceRing = document.getElementById("faceRing");
const hotspots = Array.from(document.querySelectorAll(".hotspot"));
const viewButtons = Array.from(document.querySelectorAll(".view-option"));
const watchFace = document.getElementById("watchFace");
const pageLede = document.getElementById("pageLede");
const supportedDevicesList = document.getElementById("supportedDevices");
const supportedLanguagesList = document.getElementById("supportedLanguages");
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

function applyTheme(mode) {
	window.phaseTheme.apply(mode);
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
		hotspot.setAttribute("aria-pressed", String(visible && hotspot.dataset.feature === activeFeature));
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
		return `<span class="boolean-toggle"><span>On</span><span>Off</span></span>`;
	}

	if (setting.type === "numeric") {
		const min = setting.min ?? "0";
		const max = setting.max ?? "10";
		return `<span class="option-pill">Range ${escapeHtml(min)}-${escapeHtml(max)}</span>`;
	}

	return (setting.options || []).map((option) => {
		const color = setting.title === "Accent" || setting.title === "Foreground" || setting.title === "Background" || setting.title === "Shade"
			? colorFromValue(option.value)
			: null;
		if (color) {
			return `<span class="option-pill is-color"><span class="swatch" style="background:${color}"></span>${escapeHtml(option.label)}</span>`;
		}
		return `<span class="option-pill">${escapeHtml(option.label)}</span>`;
	}).join("");
}

function settingMarkup(setting) {
	return `
		<div class="setting-row">
			<div class="setting-name">${escapeHtml(setting.title)}</div>
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

function activate(feature) {
	activeFeature = feature;
	hotspots.forEach((hotspot) => {
		hotspot.classList.toggle("is-active", hotspot.dataset.feature === feature);
		hotspot.setAttribute("aria-pressed", String(hotspot.dataset.feature === feature));
	});
	faceRing.classList.toggle("is-active", feature === "general");
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

window.addEventListener("resize", () => {
	applyHotspotGeometry();
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
