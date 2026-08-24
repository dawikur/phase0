import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import test from "node:test";

const page = readFileSync(new URL("../devices/index.html", import.meta.url), "utf8");
const app = readFileSync(new URL("../devices/app.js", import.meta.url), "utf8");

test("device reference loads generated device data and provides sortable columns", () => {
	assert.match(page, /<script src="\.\.\/devices-data\.js"><\/script>/);
	assert.match(page, /id="devicesTableBody"/);
	assert.match(page, /data-sort-column="productId"/);
	assert.match(page, /data-sort-column="resolution"/);
	assert.match(page, /data-sort-column="screenType"/);
	assert.match(page, /data-sort-column="connectIqId"/);
	assert.match(page, /data-sort-column="totalMemory"/);
	assert.match(page, /data-filter-column="productId"/);
	assert.match(page, /data-filter-column="resolution"/);
	assert.match(page, /data-filter-column="screenType"/);
	assert.match(page, /data-filter-column="connectIqId"/);
	assert.match(page, /data-filter-column="totalMemory"/);
	assert.match(app, /button\.closest\("th"\)\.setAttribute\("aria-sort"/);
	assert.match(app, /function matchesFilters\(device\)/);
	assert.match(app, /filter\.addEventListener\("input", render\)/);
	assert.match(app, /filter\.addEventListener\("change", render\)/);
});

test("device reference keeps unknown memory values distinguishable and last", () => {
	assert.match(app, /return value < 0 \? "Unknown"/);
	assert.match(app, /if \(first < 0\) return second < 0 \? 0 : 1/);
});
