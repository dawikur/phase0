(() => {
	const modes = ["auto", "light", "dark"];
	const views = ["normal", "aod"];
	const sorts = ["hue", "lightness", "rgb"];
	const systemTheme = window.matchMedia("(prefers-color-scheme: dark)");
	const usesView = "phaseViewControl" in document.documentElement.dataset;
	const usesPaletteSort = "paletteSortControl" in document.documentElement.dataset;

	function resolvedTheme(mode) {
		return mode === "auto" ? (systemTheme.matches ? "dark" : "light") : mode;
	}

	function updateTransferLinks() {
		const state = document.documentElement.dataset;
		const parameters = new URLSearchParams(window.location.search);
		const setStateParameter = (name, value, defaultValue) => {
			if (value == null || value === defaultValue) {
				parameters.delete(name);
			} else {
				parameters.set(name, value);
			}
		};

		setStateParameter("theme", state.themeMode, "auto");
		if (usesView) setStateParameter("view", state.phaseView, "normal");
		if (usesPaletteSort) setStateParameter("sort", state.paletteSort, "hue");

		const updateLink = (link) => {
			const target = new URL(link.href, window.location.href);
			target.search = parameters.toString();
			link.href = target.href;
		};
		document.querySelectorAll("a[data-theme-transfer]").forEach(updateLink);
		const siteBack = document.getElementById("siteBack");
		if (siteBack != null) updateLink(siteBack);
	}

	function apply(mode) {
		const nextMode = modes.includes(mode) ? mode : "auto";
		document.documentElement.dataset.themeMode = nextMode;
		document.documentElement.dataset.theme = resolvedTheme(nextMode);
		document.querySelectorAll(".theme-option").forEach((button) => {
			button.setAttribute("aria-pressed", String(button.dataset.themeMode === nextMode));
		});
		updateTransferLinks();
	}

	function bindSiteBackLink() {
		const link = document.getElementById("siteBack");
		if (link == null) {
			return;
		}

		const location = window.location;
		const hidden = location.protocol === "file:" || location.pathname === "/";
		link.hidden = hidden;
		document.getElementById("siteBackSeparator").hidden = hidden;
	}

	window.phaseTheme = { apply, resolvedTheme, updateTransferLinks };

	function consumeTransferredState() {
		const parameters = new URLSearchParams(window.location.search);
		const mode = parameters.get("theme");
		const view = parameters.get("view");
		const sort = parameters.get("sort");
		if (usesView && views.includes(view)) {
			document.documentElement.dataset.phaseView = view;
		}
		if (usesPaletteSort && sorts.includes(sort)) {
			document.documentElement.dataset.paletteSort = sort;
		}

		return modes.includes(mode) ? mode : null;
	}

	apply(consumeTransferredState() || "auto");

	function bindControls() {
		bindSiteBackLink();

		document.querySelectorAll(".theme-option").forEach((button) => {
			button.addEventListener("click", () => apply(button.dataset.themeMode));
		});

		systemTheme.addEventListener("change", () => {
			if (document.documentElement.dataset.themeMode === "auto") {
				apply("auto");
			}
		});

		apply(document.documentElement.dataset.themeMode);
	}

	if (document.readyState === "loading") {
		document.addEventListener("DOMContentLoaded", bindControls, { once: true });
	} else {
		bindControls();
	}
})();
