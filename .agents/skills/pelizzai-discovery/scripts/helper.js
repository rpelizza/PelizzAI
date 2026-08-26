(function () {
	const WS_URL = (window.location.protocol === 'https:' ? 'wss://' : 'ws://') + window.location.host;
	let ws = null;
	let eventQueue = [];

	function connect() {
		ws = new WebSocket(WS_URL);

		ws.onopen = () => {
			eventQueue.forEach((e) => ws.send(JSON.stringify(e)));
			eventQueue = [];
		};

		ws.onmessage = (msg) => {
			const data = JSON.parse(msg.data);
			if (data.type === 'reload') {
				window.location.reload();
			}
		};

		ws.onclose = () => {
			setTimeout(connect, 1000);
		};
	}

	function sendEvent(event) {
		event.timestamp = Date.now();
		if (ws && ws.readyState === WebSocket.OPEN) {
			ws.send(JSON.stringify(event));
		} else {
			eventQueue.push(event);
		}
	}

	// Capture clicks on choice elements
	document.addEventListener('click', (e) => {
		const target = e.target.closest('[data-choice]');
		if (!target) return;

		sendEvent({
			type: 'click',
			text: target.textContent.trim(),
			choice: target.dataset.choice,
			id: target.id || null,
		});

		// Update indicator bar (defer so toggleSelect runs first)
		setTimeout(() => {
			const indicator = document.getElementById('indicator-text');
			if (!indicator) return;
			const container = target.closest('.options') || target.closest('.cards');
			const selected = container ? container.querySelectorAll('.selected') : [];
			if (selected.length === 0) {
				indicator.textContent = 'Click an option above, then return to the terminal';
			} else {
				// Build via textContent: the label comes from mockup text and could
				// contain HTML characters — never interpolate it into innerHTML.
				const label =
					selected.length === 1
						? selected[0].querySelector('h3, .content h3, .card-body h3')?.textContent?.trim() ||
						  selected[0].dataset.choice
						: String(selected.length);
				const span = document.createElement('span');
				span.className = 'selected-text';
				span.textContent = label + ' selected';
				indicator.textContent = '';
				indicator.append(span, ' — return to terminal to continue');
			}
		}, 0);
	});

	// Keyboard access: mockups are plain divs, which never receive focus — a keyboard-only user
	// could not choose at all. Every [data-choice] becomes a focusable button; Enter/Space route
	// through the same click path, so onclick/toggleSelect and the indicator behave identically.
	// The page fully reloads on content changes, so load-time wiring covers every screen.
	function wireKeyboardAccess() {
		document.querySelectorAll('[data-choice]').forEach((el) => {
			if (!el.hasAttribute('tabindex')) el.setAttribute('tabindex', '0');
			if (!el.hasAttribute('role')) el.setAttribute('role', 'button');
			el.setAttribute('aria-pressed', el.classList.contains('selected') ? 'true' : 'false');
		});
	}
	if (document.readyState === 'loading') {
		document.addEventListener('DOMContentLoaded', wireKeyboardAccess);
	} else {
		wireKeyboardAccess();
	}
	document.addEventListener('keydown', (e) => {
		if (e.key !== 'Enter' && e.key !== ' ') return;
		const target = e.target.closest && e.target.closest('[data-choice]');
		if (!target) return;
		e.preventDefault(); // Space must select, not scroll the page
		target.click();
	});

	// Frame UI: selection tracking
	window.selectedChoice = null;

	window.toggleSelect = function (el) {
		const container = el.closest('.options') || el.closest('.cards');
		const multi = container && container.dataset.multiselect !== undefined;
		if (container && !multi) {
			container.querySelectorAll('.option, .card').forEach((o) => {
				o.classList.remove('selected');
				o.setAttribute('aria-pressed', 'false');
			});
		}
		if (multi) {
			el.classList.toggle('selected');
		} else {
			el.classList.add('selected');
		}
		el.setAttribute('aria-pressed', el.classList.contains('selected') ? 'true' : 'false');
		window.selectedChoice = el.dataset.choice;
	};

	// Expose API for explicit use
	window.brainstorm = {
		send: sendEvent,
		choice: (value, metadata = {}) => sendEvent({ type: 'choice', value, ...metadata }),
	};

	connect();
})();
