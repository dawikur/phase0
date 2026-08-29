const devices = Array.isArray(window.PHASE_DEVICES) ? [...window.PHASE_DEVICES] : [];
const tableBody = document.getElementById("devicesTableBody");
const summary = document.getElementById("devicesSummary");
const sortButtons = Array.from(document.querySelectorAll("[data-sort-column]"));
const filters = Array.from(document.querySelectorAll("[data-filter-column]"));
const columnLabels = {
	connectIqId: "Connect IQ ID",
	productId: "Device",
	resolution: "Resolution",
	screenType: "Screen",
	totalMemory: "Total memory",
	apiVersion: "API version",
};
let sortColumn = "productId";
let sortDirection = "ascending";

function compareText(first, second) {
	return String(first).localeCompare(String(second));
}

function compareMemory(first, second) {
	if (first < 0) return second < 0 ? 0 : 1;
	if (second < 0) return -1;
	return (first - second) * (sortDirection === "ascending" ? 1 : -1);
}

function compareDevices(first, second) {
	let result;
	if (sortColumn === "resolution") {
		result = first.resolution.width - second.resolution.width || first.resolution.height - second.resolution.height;
	} else if (sortColumn === "totalMemory") {
		result = compareMemory(first.totalMemory, second.totalMemory);
	} else if (sortColumn === "apiVersion") {
		result = Number(first.apiVersion) - Number(second.apiVersion);
	} else if (sortColumn === "connectIqId") {
		result = compareText(first.connectIqId, second.connectIqId);
	} else {
		result = compareText(first[sortColumn], second[sortColumn]);
	}
	const direction = sortColumn === "totalMemory" || sortDirection === "ascending" ? 1 : -1;
	return result * direction || compareText(first.productId, second.productId);
}

function cell(value) {
	const element = document.createElement("td");
	element.textContent = value;
	return element;
}

function formatMemory(value) {
	return value < 0 ? "Unknown" : `${value.toLocaleString("en-US")} B`;
}

function populateFilters() {
	["resolution", "screenType"].forEach((column) => {
		const filter = filters.find((element) => element.dataset.filterColumn === column);
		const values = [...new Set(devices.map((device) => column === "resolution"
			? `${device.resolution.width} × ${device.resolution.height}`
			: device[column]))].sort(compareText);
		values.forEach((value) => {
			const option = document.createElement("option");
			option.value = value;
			option.textContent = value;
			filter.append(option);
		});
	});
}

function matchesFilters(device) {
	return filters.every((filter) => {
		const value = filter.value.trim().toLowerCase();
		if (!value) return true;
		if (filter.dataset.filterColumn === "resolution") {
			return `${device.resolution.width} × ${device.resolution.height}` === filter.value;
		}
		if (filter.dataset.filterColumn === "totalMemory") {
			return value === "measured" ? device.totalMemory >= 0 : device.totalMemory < 0;
		}
		const deviceValue = device[filter.dataset.filterColumn];
		return deviceValue.toLowerCase().includes(value);
	});
}

function render() {
	const visibleDevices = devices.filter(matchesFilters).sort(compareDevices);
	tableBody.replaceChildren(...visibleDevices.map((device) => {
		const row = document.createElement("tr");
		row.append(
			cell(device.productId),
			cell(`${device.resolution.width} × ${device.resolution.height}`),
			cell(device.screenType),
			cell(device.connectIqId || "—"),
			cell(formatMemory(device.totalMemory)),
			cell(device.apiVersion),
		);
		return row;
	}));
	summary.textContent = `${visibleDevices.length} of ${devices.length} devices · ${devices.filter((device) => device.totalMemory >= 0).length} measured`;
	sortButtons.forEach((button) => {
		const active = button.dataset.sortColumn === sortColumn;
		button.closest("th").setAttribute("aria-sort", active ? sortDirection : "none");
		button.textContent = `${columnLabels[button.dataset.sortColumn]}${active ? (sortDirection === "ascending" ? " ↑" : " ↓") : ""}`;
	});
}

sortButtons.forEach((button) => button.addEventListener("click", () => {
	const nextColumn = button.dataset.sortColumn;
	sortDirection = nextColumn === sortColumn && sortDirection === "ascending" ? "descending" : "ascending";
	sortColumn = nextColumn;
	render();
}));

filters.forEach((filter) => {
	filter.addEventListener("input", render);
	filter.addEventListener("change", render);
});
populateFilters();
render();
