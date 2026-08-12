const STEPS = [0x00, 0x55, 0xaa, 0xff];
const settingsData = window.PHASE_SETTINGS || { groups: [] };
const palette = document.getElementById("palette");
const sortButtons = document.querySelectorAll("[data-sort-mode]");

function rgbToHsl(red, green, blue) {
	const [r, g, b] = [red / 255, green / 255, blue / 255];
	const maximum = Math.max(r, g, b);
	const minimum = Math.min(r, g, b);
	const lightness = (maximum + minimum) / 2;
	if (maximum === minimum) return [0, 0, lightness];

	const difference = maximum - minimum;
	const saturation = lightness > .5
		? difference / (2 - maximum - minimum)
		: difference / (maximum + minimum);
	let hue;
	if (maximum === r) hue = (g - b) / difference + (g < b ? 6 : 0);
	else if (maximum === g) hue = (b - r) / difference + 2;
	else hue = (r - g) / difference + 4;
	return [hue / 6, saturation, lightness];
}

function toHex(value) {
	return value.toString(16).padStart(2, "0").toUpperCase();
}

function hexFromDecimalColor(value) {
	const color = Number(value);
	if (!Number.isInteger(color) || color < 0 || color > 0xffffff) return null;
	return `#${color.toString(16).padStart(6, "0").toUpperCase()}`;
}

function settingColorNames() {
	const general = settingsData.groups.find((group) => group.id === "General");
	const accent = general?.settings.find((setting) => setting.key === "GeneralAccent");
	if (!accent) return new Map();
	return new Map(accent.options
		.map((option) => [hexFromDecimalColor(option.value), option.label])
		.filter(([hex]) => hex));
}

const settingColorNamesByHex = settingColorNames();
const colors = [];
for (const red of STEPS) {
	for (const green of STEPS) {
		for (const blue of STEPS) {
			const [hue, saturation, lightness] = rgbToHsl(red, green, blue);
			colors.push({ red, green, blue, hue, saturation, lightness });
		}
	}
}

function compareColors(mode, first, second) {
	if (mode === "lightness") return first.lightness - second.lightness || first.hue - second.hue || first.saturation - second.saturation;
	if (mode === "rgb") return first.red - second.red || first.green - second.green || first.blue - second.blue;
	return first.hue - second.hue || first.saturation - second.saturation || first.lightness - second.lightness;
}

function sortPalette(mode) {
	const nextMode = ["hue", "lightness", "rgb"].includes(mode) ? mode : "hue";
	colors.sort((first, second) => compareColors(nextMode, first, second));
	colors.forEach((color) => palette.appendChild(color.card));
	document.documentElement.dataset.paletteSort = nextMode;
	window.phaseTheme.updateTransferLinks();
	sortButtons.forEach((button) => button.setAttribute("aria-pressed", String(button.dataset.sortMode === nextMode)));
}

colors.forEach((color) => {
	const hex = `#${toHex(color.red)}${toHex(color.green)}${toHex(color.blue)}`;
	const card = document.createElement("div");
	card.className = "ui-palette-card ui-palette-card--compact";
	const swatch = document.createElement("button");
	swatch.type = "button";
	swatch.className = "ui-palette-sample";
	swatch.style.background = hex;
	swatch.setAttribute("aria-label", `Copy ${hex} as a hexadecimal value`);
	swatch.addEventListener("click", async () => {
		try {
			await window.SiteUi.copy.withFeedback(swatch, `0x${hex.slice(1)}`);
		} catch (error) {
			console.error("Clipboard error:", error);
		}
	});
	const hexLabel = document.createElement("div");
	hexLabel.className = "ui-swatch-label";
	hexLabel.textContent = hex;
	const nameLabel = document.createElement("div");
	nameLabel.className = "ui-swatch-name";
	nameLabel.textContent = settingColorNamesByHex.get(hex) || "";
	card.append(swatch, hexLabel, nameLabel);
	color.card = card;
});

sortButtons.forEach((button) => button.addEventListener("click", () => sortPalette(button.dataset.sortMode)));
sortPalette(document.documentElement.dataset.paletteSort || "hue");
