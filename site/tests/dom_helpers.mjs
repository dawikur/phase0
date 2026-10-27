// Minimal DOM surface for executing the standalone reference pages.
export class Element {
	constructor(dataset = {}) {
		this.dataset = dataset;
		this.children = [];
		this.attributes = {};
		this.listeners = {};
		this.style = {};
		this.value = "";
		this.textContent = "";
	}
	append(...children) { this.children.push(...children); }
	appendChild(child) {
		this.children = this.children.filter((item) => item !== child);
		this.children.push(child);
	}
	replaceChildren(...children) { this.children = children; }
	setAttribute(name, value) { this.attributes[name] = value; }
	addEventListener(name, callback) { this.listeners[name] = callback; }
	closest() { return this; }
}
