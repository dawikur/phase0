(() => {
	const modes = ["auto", "light", "dark"];
	const views = ["normal", "aod"];
	const sorts = ["hue", "lightness", "rgb"];
	const systemTheme = window.matchMedia("(prefers-color-scheme: dark)");

	function resolvedTheme(mode) {
		return mode === "auto" ? (systemTheme.matches ? "dark" : "light") : mode;
	}

	function updateTransferLinks() {
		const state = document.documentElement.dataset;
		document.querySelectorAll("a[data-theme-transfer]").forEach((link) => {
			const target = new URL(link.href, window.location.href);
			target.searchParams.set("theme", state.themeMode || "auto");
			target.searchParams.set("view", state.phaseView || "normal");
			target.searchParams.set("sort", state.paletteSort || "hue");
			link.href = target.href;
		});
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

	window.phaseTheme = { apply, resolvedTheme, updateTransferLinks };

	function consumeTransferredState() {
		const parameters = new URLSearchParams(window.location.search);
		const mode = parameters.get("theme");
		const view = parameters.get("view");
		const sort = parameters.get("sort");
		if (views.includes(view)) {
			document.documentElement.dataset.phaseView = view;
		}
		if (sorts.includes(sort)) {
			document.documentElement.dataset.paletteSort = sort;
		}

		if (modes.includes(mode) || views.includes(view) || sorts.includes(sort)) {
			parameters.delete("theme");
			parameters.delete("view");
			parameters.delete("sort");
			const query = parameters.toString();
			window.history.replaceState(
				null,
				"",
				`${window.location.pathname}${query ? `?${query}` : ""}${window.location.hash}`,
			);
		}

		return modes.includes(mode) ? mode : null;
	}

	apply(consumeTransferredState() || "auto");

	function bindControls() {
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
