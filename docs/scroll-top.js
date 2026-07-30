(() => {
	const button = document.querySelector(".scroll-top");
	if (button == null) return;

	const update = () => {
		const canScroll = document.documentElement.scrollHeight > window.innerHeight + 1;
		const visible = canScroll && window.scrollY >= window.innerHeight / 2;
		button.hidden = !canScroll;
		button.classList.toggle("is-visible", visible);
		button.tabIndex = visible ? 0 : -1;
		button.setAttribute("aria-hidden", String(!visible));
	};

	button.addEventListener("click", () => {
		const reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
		window.scrollTo({ top: 0, behavior: reducedMotion ? "auto" : "smooth" });
	});
	window.addEventListener("scroll", update, { passive: true });
	window.addEventListener("resize", update);
	update();
})();
