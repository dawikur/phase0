(() => {
	const root = document.documentElement;
	const views = ["normal", "aod"];
	const sorts = ["hue", "lightness", "rgb"];
	const usesView = "phaseViewControl" in root.dataset;
	const usesPaletteSort = "paletteSortControl" in root.dataset;

	function updateTransferLinks() {
		window.SiteUi.url.setOwnedParameters([
			...(usesView ? [{ name: "view", value: root.dataset.phaseView, defaultValue: "normal" }] : []),
			...(usesPaletteSort ? [{ name: "sort", value: root.dataset.paletteSort, defaultValue: "hue" }] : []),
		]);
	}

	const parameters = new URLSearchParams(window.location.search);
	if (usesView && views.includes(parameters.get("view"))) root.dataset.phaseView = parameters.get("view");
	if (usesPaletteSort && sorts.includes(parameters.get("sort"))) root.dataset.paletteSort = parameters.get("sort");

	window.phaseTheme = {
		apply: window.SiteUi.theme.applyTheme,
		resolvedTheme: window.SiteUi.theme.resolveTheme,
		updateTransferLinks,
	};

	const bind = () => {
		updateTransferLinks();
	};
	if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", bind, { once: true });
	else bind();
})();
