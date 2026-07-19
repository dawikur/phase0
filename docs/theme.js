(() => {
	const modes = ["auto", "light", "dark"];
	const systemTheme = window.matchMedia("(prefers-color-scheme: dark)");

	function resolvedTheme(mode) {
		return mode === "auto" ? (systemTheme.matches ? "dark" : "light") : mode;
	}

	function apply(mode) {
		const nextMode = modes.includes(mode) ? mode : "auto";
		document.documentElement.dataset.themeMode = nextMode;
		document.documentElement.dataset.theme = resolvedTheme(nextMode);
		document.querySelectorAll(".theme-option").forEach((button) => {
			button.setAttribute("aria-pressed", String(button.dataset.themeMode === nextMode));
		});
	}

	window.phaseTheme = { apply, resolvedTheme };
	const urlTheme = new URLSearchParams(window.location.search).get("theme");
	apply(modes.includes(urlTheme) ? urlTheme : "auto");

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
