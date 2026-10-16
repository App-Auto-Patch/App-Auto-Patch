#!/usr/bin/env node
//
//  sync.mjs
//  Keep a public "version 4" issue in App-Auto-Patch/App-Auto-Patch and its private twin in
//  App-Auto-Patch/AAP4-Swift in sync.
//
//  THIS FILE IS IDENTICAL IN BOTH REPOSITORIES. When you change it, change both copies
//  (.github/scripts/issue-sync/ in the public repo and in AAP4-Swift).
//
//  It runs from two workflows, and does the same thing in both: it looks at one public
//  issue and its private twin and makes them agree.
//    public repo   sync-issues-to-private.yml   on issue events of issues labeled "version 4"
//    private repo  sync-issues-to-public.yml    on close/reopen, status labels, and /public comments
//
//  Environment:
//    PUBLIC_TOKEN, PRIVATE_TOKEN   tokens that can write issues in the public / private repo
//    GITHUB_EVENT_NAME, GITHUB_EVENT_PATH, GITHUB_REPOSITORY   set by GitHub Actions
//    DRY_RUN=1                     print the writes instead of making them
//
//  What stays in sync
//    title and body ........ public -> private (the private body is rebuilt from the public one)
//    type labels ........... public -> private (bug, enhancement, documentation, ...)
//    comments .............. public -> private (all); private -> public only when a private
//                            comment starts with /public
//    open/closed ........... both ways
//    status labels ......... both ways (Planned, In Progress, ...)
//
//  Every run reads both issues and only writes what differs, so a change made by the sync
//  produces an event that finds nothing to do. State and status labels are merged against the
//  last agreed values, stored in a hidden marker in the private issue body, so the side that
//  changed wins.
//
//  Text from public users is untrusted: it is only ever passed as data (never to a shell), and
//  it is sanitized so it cannot forge a marker or reference unrelated private issues.
//
//  No dependencies: Node 18+.
//

import fs from 'node:fs';
import { pathToFileURL } from 'node:url';

export const PUBLIC_REPO = 'App-Auto-Patch/App-Auto-Patch';
export const PRIVATE_REPO = 'App-Auto-Patch/AAP4-Swift';
export const TRIGGER_LABEL = 'version 4';
export const MIRROR_LABEL = 'from-public';
export const TYPE_LABELS = ['bug', 'enhancement', 'documentation', 'question', 'duplicate', 'invalid', 'wontfix'];
export const STATUS_LABELS = ['Planned', 'In Progress', 'Implementation Complete', 'Awaiting Reporter Feedback', 'not planned'];

const MAX_BODY = 60000;
const ZWSP = '\u200b';

// ---------------------------------------------------------------------------
// Markers (hidden HTML comments that link the two sides)
// ---------------------------------------------------------------------------

export const marker = (kind, value) => (value === undefined ? `<!-- aap-sync:${kind} -->` : `<!-- aap-sync:${kind}=${value} -->`);

export function readMarker(text, kind) {
	const m = String(text ?? '').match(new RegExp(`<!--\\s*aap-sync:${kind}=(.*?)\\s*-->`, 's'));
	return m ? m[1] : null;
}

export const hasMarker = (text, kind) => String(text ?? '').includes(`aap-sync:${kind}`);

/** True for any text written by the sync (never mirrored back). */
export const isSyncText = (text) => /aap-sync:/i.test(String(text ?? ''));

// ---------------------------------------------------------------------------
// Text handling
// ---------------------------------------------------------------------------

const norm = (s) => String(s ?? '').replace(/\r\n?/g, '\n').trim();

function transformInline(text, fn) {
	const spans = [];
	const protectedText = text.replace(/(`+)([\s\S]*?[^`])\1(?!`)/g, (m) => {
		spans.push(m);
		return `\u0000${spans.length - 1}\u0000`;
	});
	return fn(protectedText).replace(/\u0000(\d+)\u0000/g, (_m, i) => spans[Number(i)]);
}

/** Apply fn to the prose of a markdown text, leaving fenced code blocks and `inline code` alone. */
export function mapOutsideCode(text, fn) {
	const out = [];
	let prose = [];
	let fence = null;
	const flush = () => {
		if (prose.length) out.push(transformInline(prose.join('\n'), fn));
		prose = [];
	};
	for (const line of text.split('\n')) {
		const m = line.match(/^\s{0,3}(`{3,}|~{3,})/);
		if (fence) {
			out.push(line);
			if (m && m[1][0] === fence.char && m[1].length >= fence.len && /^\s{0,3}[`~]+\s*$/.test(line)) fence = null;
			continue;
		}
		if (m) {
			flush();
			fence = { char: m[1][0], len: m[1].length };
			out.push(line);
			continue;
		}
		prose.push(line);
	}
	flush();
	return out.join('\n');
}

/** Public text on its way into the private repo. */
export function sanitizeForPrivate(text) {
	const t = String(text ?? '').replace(/\r\n?/g, '\n').replace(/aap-sync:/gi, 'aap-sync-');
	return mapOutsideCode(t, (prose) =>
		prose
			// No pings: a zero-width space after the @ stops the mention.
			.replace(/(^|[^\w`@/])@([A-Za-z0-9](?:[A-Za-z0-9-]{0,38})(?:\/[A-Za-z0-9_.-]+)?)/g, `$1@${ZWSP}$2`)
			// #123 in a public issue means public issue 123, not private issue 123.
			.replace(/(^|[^\w/&#])#(\d+)\b/g, `$1${PUBLIC_REPO}#$2`),
	);
}

/** Private text on its way into the public repo (a /public comment). */
export function sanitizeForPublic(text) {
	const t = String(text ?? '')
		.replace(/\r\n?/g, '\n')
		.replace(/aap-sync:/gi, 'aap-sync-')
		.replace(/https?:\/\/github\.com\/App-Auto-Patch\/AAP4-Swift[^\s)>\]]*/gi, '(private link removed)');
	return mapOutsideCode(t, (prose) =>
		prose
			.replace(/App-Auto-Patch\/AAP4-Swift#(\d+)/g, '`#$1`')
			// #153 in the private repo is not public issue 153: show it as plain code.
			.replace(/(^|[^\w/&#`])#(\d+)\b/g, '$1`#$2`'),
	);
}

export const isPublicCommand = (body) => /^\s*\/public(\s|$)/i.test(String(body ?? ''));
export const stripPublicCommand = (body) => norm(String(body ?? '').replace(/^\s*\/public\b/i, ''));

const loginOf = (user) => user?.login ?? 'ghost';

// ---------------------------------------------------------------------------
// Labels and state
// ---------------------------------------------------------------------------

const same = (a, b) => String(a).toLowerCase() === String(b).toLowerCase();
export const labelNames = (issue) => (issue.labels ?? []).map((l) => (typeof l === 'string' ? l : l.name));
export const hasLabel = (names, label) => names.some((n) => same(n, label));
const pick = (names, wanted) => wanted.filter((w) => hasLabel(names, w));

const closeReason = (issue) => (['not_planned', 'duplicate'].includes(issue.state_reason) ? 'not_planned' : 'completed');

// ---------------------------------------------------------------------------
// Bodies
// ---------------------------------------------------------------------------

export function buildBase(issue) {
	return { s: issue.state, l: pick(labelNames(issue), STATUS_LABELS) };
}

export function readBase(body) {
	try {
		const base = JSON.parse(readMarker(body, 'base'));
		if ((base.s === 'open' || base.s === 'closed') && Array.isArray(base.l)) return base;
	} catch {
		// fall through
	}
	return null;
}

export function buildPrivateBody(issue, base) {
	const number = issue.number;
	const text = norm(sanitizeForPrivate(issue.body)) || '_No description provided._';
	const body = [
		marker('public', `${PUBLIC_REPO}#${number}`),
		marker('base', JSON.stringify(base)),
		`> Mirrored from [${PUBLIC_REPO}#${number}](${issue.html_url}) by @${loginOf(issue.user)}.`,
		'> The title and everything below the line are overwritten from the public issue, so discuss in comments. A comment that starts with `/public` is posted on the public issue.',
		'',
		'---',
		'',
		text,
	].join('\n');
	return body.length > MAX_BODY ? `${body.slice(0, MAX_BODY)}\n\n_Truncated. See the public issue for the full text._` : body;
}

export function buildPrivateComment(comment) {
	const text = norm(sanitizeForPrivate(comment.body)) || '_(empty comment)_';
	return `${marker('public-comment', comment.id)}\n**@${loginOf(comment.user)}** commented on the public issue ([link](${comment.html_url})):\n\n${text}`.slice(0, MAX_BODY);
}

export const buildDeletedPrivateComment = (id) => `${marker('public-comment', id)}\n_This comment was deleted on the public issue._`;

export function buildPublicComment(comment) {
	const text = norm(sanitizeForPublic(stripPublicCommand(comment.body)));
	return `${marker('private-comment', comment.id)}\n**Maintainer reply from @${loginOf(comment.user)}**\n\n${text}`.slice(0, MAX_BODY);
}

export const ACK_COMMENT = `${marker('ack')}\nThanks for the report. It has been recorded for App Auto-Patch 4 development. Status changes and replies from the team will be posted here.`;
export const DETACHED_COMMENT = `${marker('detached')}\nThe public issue no longer has the \`${TRIGGER_LABEL}\` label, so syncing has stopped. Add the label again to resume.`;

// ---------------------------------------------------------------------------
// GitHub API
// ---------------------------------------------------------------------------

export function createApi({ token, dryRun = false, log = console.log, fetchImpl = globalThis.fetch }) {
	// Dry run: writes are printed, not made. Issues "created" or "patched" during the run are kept in
	// memory so the rest of the run sees them, and an issue created in the run has a negative number.
	let fakeId = 0;
	const overlay = new Map();
	const asIssue = (o) => ({ ...o, labels: o.labels.map((name) => ({ name })) });

	async function dryWrite(method, path, body) {
		log(`[dry-run] ${method} ${path}${body ? ` ${JSON.stringify(body).slice(0, 160)}` : ''}`);
		if (method === 'POST' && /^\/repos\/[^/]+\/[^/]+\/issues$/.test(path)) {
			fakeId -= 1;
			const created = { number: fakeId, id: fakeId, html_url: '', state: 'open', state_reason: null, title: body.title, body: body.body ?? '', labels: [...(body.labels ?? [])] };
			overlay.set(`${path}/${fakeId}`, created);
			return asIssue(created);
		}
		if (method === 'PATCH' && /\/issues\/-?\d+$/.test(path)) {
			const current = overlay.get(path) ?? { ...(await request('GET', path)), labels: [] };
			const labels = overlay.has(path) ? current.labels : (await request('GET', path)).labels.map((l) => l.name);
			const merged = { ...current, labels };
			for (const key of ['title', 'body', 'state', 'state_reason']) if (body[key] !== undefined) merged[key] = body[key];
			if (merged.state === 'open') merged.state_reason = null;
			overlay.set(path, merged);
			return asIssue(merged);
		}
		fakeId -= 1000; // comments and labels: nothing reads them back
		return { id: fakeId, html_url: '' };
	}

	async function request(method, path, body, { allow404 = false } = {}) {
		// In a dry run, an issue created earlier in the run does not exist on GitHub.
		if (dryRun && method === 'GET' && /\/issues\/-\d+/.test(path)) return [];
		if (dryRun && method !== 'GET') return dryWrite(method, path, body);
		for (let attempt = 1; ; attempt++) {
			const response = await fetchImpl(`https://api.github.com${path}`, {
				method,
				headers: {
					...(token ? { Authorization: `Bearer ${token}` } : {}),
					Accept: 'application/vnd.github+json',
					'X-GitHub-Api-Version': '2022-11-28',
					'User-Agent': 'aap-issue-sync',
					...(body === undefined ? {} : { 'Content-Type': 'application/json' }),
				},
				body: body === undefined ? undefined : JSON.stringify(body),
				signal: AbortSignal.timeout(30_000),
			});
			if (response.ok) return response.status === 204 ? null : response.json();
			if (response.status === 404 && allow404) return null;
			const retryAfter = Number(response.headers.get('retry-after'));
			const limited = (response.status === 403 || response.status === 429) && (retryAfter > 0 || response.headers.get('x-ratelimit-remaining') === '0');
			if ((response.status >= 500 || limited) && attempt < 4) {
				const wait = retryAfter > 0 ? retryAfter * 1000 : 2 ** attempt * 1000;
				log(`${method} ${path} answered ${response.status}; retrying in ${wait / 1000}s`);
				await new Promise((resolve) => setTimeout(resolve, Math.min(wait, 60_000)));
				continue;
			}
			throw new Error(`${method} ${path} -> ${response.status} ${(await response.text()).slice(0, 300)}`);
		}
	}

	async function paginate(path) {
		const all = [];
		const joiner = path.includes('?') ? '&' : '?';
		for (let page = 1; page <= 50; page++) {
			const batch = await request('GET', `${path}${joiner}per_page=100&page=${page}`);
			all.push(...batch);
			if (batch.length < 100) break;
		}
		return all;
	}

	return {
		get: (path, options) => request('GET', path, undefined, options),
		post: (path, body) => request('POST', path, body),
		patch: (path, body) => request('PATCH', path, body),
		del: (path, options) => request('DELETE', path, undefined, options),
		paginate,
	};
}

// ---------------------------------------------------------------------------
// Reconcile one public issue with its private twin
// ---------------------------------------------------------------------------

async function findMirror(priv, publicNumber) {
	const issues = await priv.paginate(`/repos/${PRIVATE_REPO}/issues?labels=${encodeURIComponent(MIRROR_LABEL)}&state=all`);
	const wanted = `${PUBLIC_REPO}#${publicNumber}`;
	const matches = issues.filter((i) => !i.pull_request && readMarker(i.body, 'public') === wanted).sort((a, b) => a.number - b.number);
	return matches[0] ?? null;
}

async function setLabel(api, repo, number, label, present) {
	if (present) await api.post(`/repos/${repo}/issues/${number}/labels`, { labels: [label] });
	else await api.del(`/repos/${repo}/issues/${number}/labels/${encodeURIComponent(label)}`, { allow404: true });
}

async function setState(api, repo, number, source) {
	const body = source.state === 'closed' ? { state: 'closed', state_reason: closeReason(source) } : { state: 'open' };
	return api.patch(`/repos/${repo}/issues/${number}`, body);
}

export async function reconcile({ pub, priv, publicNumber, log = console.log }) {
	const pubIssuePath = `/repos/${PUBLIC_REPO}/issues/${publicNumber}`;
	let P = await pub.get(pubIssuePath, { allow404: true });
	if (!P) {
		log(`Public issue #${publicNumber} was not found; nothing to do.`);
		return { result: 'skipped' };
	}
	if (P.pull_request) return { result: 'skipped' };

	let Q = await findMirror(priv, publicNumber);

	// Not (or no longer) a version 4 issue: stop syncing, and say so once.
	if (!hasLabel(labelNames(P), TRIGGER_LABEL)) {
		if (Q) {
			const comments = await priv.paginate(`/repos/${PRIVATE_REPO}/issues/${Q.number}/comments`);
			if (!comments.some((c) => hasMarker(c.body, 'detached'))) {
				await priv.post(`/repos/${PRIVATE_REPO}/issues/${Q.number}/comments`, { body: DETACHED_COMMENT });
				log(`Public issue #${publicNumber} lost the ${TRIGGER_LABEL} label; syncing stopped for private #${Q.number}.`);
			}
		}
		return { result: 'detached' };
	}

	// Create the private twin.
	let created = false;
	if (!Q) {
		const base = buildBase(P);
		Q = await priv.post(`/repos/${PRIVATE_REPO}/issues`, {
			title: P.title,
			body: buildPrivateBody(P, base),
			labels: [MIRROR_LABEL, ...pick(labelNames(P), TYPE_LABELS), ...base.l],
		});
		if (P.state === 'closed') Q = await setState(priv, PRIVATE_REPO, Q.number, P);
		created = true;
		log(`Created private issue #${Q.number} for public #${publicNumber}.`);
		await pub.post(`${pubIssuePath}/comments`, { body: ACK_COMMENT });
	}
	const qPath = `/repos/${PRIVATE_REPO}/issues/${Q.number}`;

	// Open / closed: the side that differs from the last agreed value changed.
	const base = readBase(Q.body) ?? buildBase(P);
	if (P.state !== Q.state) {
		if (P.state !== base.s) {
			Q = await setState(priv, PRIVATE_REPO, Q.number, P);
			log(`Private #${Q.number} is now ${P.state}, following the public issue.`);
		} else {
			P = await setState(pub, PUBLIC_REPO, publicNumber, Q);
			log(`Public #${publicNumber} is now ${Q.state}, following the private issue.`);
		}
	}

	// Status labels, both ways, against the last agreed values.
	const pNames = labelNames(P);
	const qNames = labelNames(Q);
	const agreed = [];
	for (const label of STATUS_LABELS) {
		const pubHas = hasLabel(pNames, label);
		const privHas = hasLabel(qNames, label);
		const baseHas = base.l.some((l) => same(l, label));
		let final = pubHas;
		if (pubHas !== privHas) {
			if (pubHas !== baseHas) {
				await setLabel(priv, PRIVATE_REPO, Q.number, label, pubHas);
				final = pubHas;
			} else {
				await setLabel(pub, PUBLIC_REPO, publicNumber, label, privHas);
				final = privHas;
			}
			log(`Label "${label}" is now ${final ? 'set' : 'removed'} on both.`);
		}
		if (final) agreed.push(label);
	}
	const newBase = { s: P.state, l: agreed };

	// Type labels follow the public issue; the mirror label stays.
	const wantedTypes = pick(pNames, TYPE_LABELS);
	for (const label of TYPE_LABELS) {
		const has = hasLabel(qNames, label);
		const want = wantedTypes.includes(label);
		if (want !== has) await setLabel(priv, PRIVATE_REPO, Q.number, label, want);
	}
	if (!hasLabel(qNames, MIRROR_LABEL)) await setLabel(priv, PRIVATE_REPO, Q.number, MIRROR_LABEL, true);

	// Title and body follow the public issue.
	const patch = {};
	if (Q.title !== P.title) patch.title = P.title;
	const desiredBody = buildPrivateBody(P, newBase);
	if (norm(Q.body) !== norm(desiredBody)) patch.body = desiredBody;
	if (Object.keys(patch).length) {
		Q = await priv.patch(qPath, patch);
		log(`Updated ${Object.keys(patch).join(' and ')} of private #${Q.number}.`);
	}

	await reconcileComments({ pub, priv, publicNumber, privateNumber: Q.number, log });
	return { result: created ? 'created' : 'synced', privateNumber: Q.number };
}

async function reconcileComments({ pub, priv, publicNumber, privateNumber, log }) {
	const pubPath = `/repos/${PUBLIC_REPO}/issues/${publicNumber}/comments`;
	const privPath = `/repos/${PRIVATE_REPO}/issues/${privateNumber}/comments`;
	const pubComments = await pub.paginate(pubPath);
	const privComments = await priv.paginate(privPath);

	// Public -> private: every comment the sync did not write itself.
	const privByPublicId = new Map();
	for (const c of privComments) {
		const id = readMarker(c.body, 'public-comment');
		if (id) privByPublicId.set(id, c);
	}
	const livePublicIds = new Set();
	for (const c of pubComments) {
		if (isSyncText(c.body)) continue;
		livePublicIds.add(String(c.id));
		const wanted = buildPrivateComment(c);
		const existing = privByPublicId.get(String(c.id));
		if (!existing) {
			await priv.post(privPath, { body: wanted });
			log(`Mirrored public comment ${c.id} to private #${privateNumber}.`);
		} else if (norm(existing.body) !== norm(wanted)) {
			await priv.patch(`/repos/${PRIVATE_REPO}/issues/comments/${existing.id}`, { body: wanted });
		}
	}
	for (const [id, existing] of privByPublicId) {
		const gone = buildDeletedPrivateComment(id);
		if (!livePublicIds.has(id) && norm(existing.body) !== norm(gone)) {
			await priv.patch(`/repos/${PRIVATE_REPO}/issues/comments/${existing.id}`, { body: gone });
		}
	}

	// Private -> public: only comments that start with /public.
	const pubByPrivateId = new Map();
	for (const c of pubComments) {
		const id = readMarker(c.body, 'private-comment');
		if (id) pubByPrivateId.set(id, c);
	}
	const eligible = new Set();
	for (const c of privComments) {
		if (isSyncText(c.body) || !isPublicCommand(c.body) || !stripPublicCommand(c.body)) continue;
		eligible.add(String(c.id));
		const wanted = buildPublicComment(c);
		const existing = pubByPrivateId.get(String(c.id));
		if (!existing) {
			await pub.post(pubPath, { body: wanted });
			log(`Posted private comment ${c.id} on public #${publicNumber}.`);
		} else if (norm(existing.body) !== norm(wanted)) {
			await pub.patch(`/repos/${PUBLIC_REPO}/issues/comments/${existing.id}`, { body: wanted });
		}
	}
	for (const [id, existing] of pubByPrivateId) {
		if (!eligible.has(id)) {
			await pub.del(`/repos/${PUBLIC_REPO}/issues/comments/${existing.id}`, { allow404: true });
			log(`Removed public comment ${existing.id}: its private comment is gone or no longer starts with /public.`);
		}
	}
}

// ---------------------------------------------------------------------------
// Entry point
// ---------------------------------------------------------------------------

/** Which public issue does this event concern? null when it is not a synced issue. */
export function resolvePublicNumber({ eventName, repo, event }) {
	if (eventName === 'workflow_dispatch') {
		const n = Number(event.inputs?.issue_number);
		return Number.isInteger(n) && n > 0 ? n : null;
	}
	const issue = event.issue;
	if (!issue || issue.pull_request) return null;
	if (repo === PUBLIC_REPO) return issue.number;
	if (repo === PRIVATE_REPO) {
		const m = (readMarker(issue.body, 'public') ?? '').match(/^App-Auto-Patch\/App-Auto-Patch#(\d+)$/);
		return m ? Number(m[1]) : null;
	}
	throw new Error(`Unexpected repository ${repo}`);
}

export async function main(env = process.env) {
	const event = JSON.parse(fs.readFileSync(env.GITHUB_EVENT_PATH, 'utf8'));
	const publicNumber = resolvePublicNumber({ eventName: env.GITHUB_EVENT_NAME, repo: env.GITHUB_REPOSITORY, event });
	if (!publicNumber) {
		console.log('This event does not concern a synced issue; nothing to do.');
		return;
	}
	if (!env.PRIVATE_TOKEN || !env.PUBLIC_TOKEN) throw new Error('PUBLIC_TOKEN and PRIVATE_TOKEN are both required');
	const dryRun = ['1', 'true'].includes(String(env.DRY_RUN ?? ''));
	const pub = createApi({ token: env.PUBLIC_TOKEN, dryRun });
	const priv = createApi({ token: env.PRIVATE_TOKEN, dryRun });
	const outcome = await reconcile({ pub, priv, publicNumber });
	console.log(`Done: ${outcome.result}${outcome.privateNumber ? ` (private #${outcome.privateNumber})` : ''}.`);
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
	main().catch((error) => {
		console.error(`error: ${error instanceof Error ? error.message : error}`);
		process.exit(1);
	});
}
