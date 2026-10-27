import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import test from "node:test";
import vm from "node:vm";
import { Element } from "./dom_helpers.mjs";

function harness() {
	const table = new Element();
	const summary = new Element();
	const columns = ["productId", "resolution", "screenShape", "screenType", "connectIqId", "watchFaceMemory", "apiVersion"];
	const buttons = columns.map((sortColumn) => new Element({ sortColumn }));
	const filters = columns.map((filterColumn) => new Element({ filterColumn }));
	const scopes = ["supported", "all"].map((deviceScope) => new Element({ deviceScope }));
	const devices = [["Zulu", 200, true], ["Alpha", -1, true], ["Beta", 100, false]].map(([productId, memory, supported]) => ({
		productId, supported, memory: { watchFace: memory }, resolution: { width: 240, height: 240 },
		screenShape: "Round", screenType: "MIP", connectIqId: productId.toLowerCase(), apiVersion: "3.4",
	}));
	vm.runInNewContext(readFileSync(new URL("../devices/app.js", import.meta.url), "utf8"), {
		window: { PHASE_DEVICES: devices },
		document: {
			getElementById: (id) => id === "devicesTableBody" ? table : summary,
			querySelectorAll: (selector) => ({ "[data-sort-column]": buttons, "[data-filter-column]": filters, "[data-device-scope]": scopes })[selector],
			createElement: () => new Element(),
		},
	});
	return { table, summary, buttons, filters, scopes, names: () => Array.from(table.children, (row) => row.children[0].textContent) };
}

test("scope and filters change visible rows and summary", () => {
	const page = harness();
	assert.deepEqual(page.names(), ["Alpha", "Zulu"]);
	assert.equal(page.summary.textContent, "2 of 2 devices · 1 documented");
	page.scopes[1].listeners.click();
	assert.deepEqual(page.names(), ["Alpha", "Beta", "Zulu"]);
	assert.equal(page.scopes[1].attributes["aria-pressed"], "true");
	page.filters[0].value = "  BeTA  ";
	page.filters[0].listeners.input();
	assert.deepEqual(page.names(), ["Beta"]);
	page.filters[0].value = "";
	page.filters[5].value = "unknown";
	page.filters[5].listeners.change();
	assert.deepEqual(page.names(), ["Alpha"]);
	assert.equal(page.table.children[0].children[5].textContent, "Unknown");
});

test("memory sorting keeps unknown values last in both directions", () => {
	const page = harness();
	page.scopes[1].listeners.click();
	const sort = page.buttons[5];
	sort.listeners.click();
	assert.deepEqual(page.names(), ["Beta", "Zulu", "Alpha"]);
	assert.equal(sort.attributes["aria-sort"], "ascending");
	sort.listeners.click();
	assert.deepEqual(page.names(), ["Zulu", "Beta", "Alpha"]);
	assert.equal(sort.attributes["aria-sort"], "descending");
});
