(() => {
	const urlTheme = new URLSearchParams(window.location.search).get("theme");
	const mode = ["auto", "light", "dark"].includes(urlTheme)
		? urlTheme
		: "auto";
	const systemDark = window.matchMedia("(prefers-color-scheme: dark)").matches;
	document.documentElement.dataset.theme = mode === "auto"
		? (systemDark ? "dark" : "light")
		: mode;
	document.documentElement.dataset.themeMode = mode;
})();
