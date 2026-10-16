//
//  sync.test.mjs
//  Tests for sync.mjs. Run with:  node --test .github/scripts/issue-sync/
//
//  THIS FILE IS IDENTICAL IN BOTH REPOSITORIES (see the note at the top of sync.mjs).
//  The tests run against a small in-memory fake of the GitHub issues API, so they need no
//  network and no tokens.
//

import test from 'node:test';
import assert from 'node:assert/strict';
import * as S from './sync.mjs';

// ---------------------------------------------------------------------------
// In-memory fake of the parts of the GitHub API the sync uses
// ---------------------------------------------------------------------------

function createFake() {
	const repos = {
		[S.PUBLIC_REPO]: { issues: [], comments: [], nextIssue: 290, nextComment: 5000 },
		[S.PRIVATE_REPO]: { issues: [], comments: [], nextIssue: 150, nextComment: 9000 },
	};
	const writes = [];
	const sameName = (a, b) => a.toLowerCase() === b.toLowerCase();
	const issueView = (repo, i) => ({
		...i,
		labels: i.labels.map((name) => ({ name })),
		html_url: `https://github.com/${repo}/issues/${i.number}`,
	});
	const commentView = (repo, c) => ({ ...c, html_url: `https://github.com/${repo}/issues/${c.issue}#issuecomment-${c.id}` });
	const issueOf = (repo, n) => {
		const issue = repos[repo].issues.find((i) => i.number === Number(n));
		if (!issue) throw Object.assign(new Error(`no issue ${repo}#${n}`), { status: 404 });
		return issue;
	};
	const commentOf = (repo, id) => repos[repo].comments.find((c) => c.id === Number(id));

	function client(actor) {
		function route(method, path, body, options = {}) {
			const [pathname, query = ''] = path.split('?');
			const params = new URLSearchParams(query);
			if (method !== 'GET') writes.push({ actor, method, path });
			let m;

			if ((m = pathname.match(/^\/repos\/([^/]+\/[^/]+)\/issues$/))) {
				const repo = m[1];
				if (method === 'GET') {
					const label = params.get('labels');
					return repos[repo].issues.filter((i) => !label || i.labels.some((l) => sameName(l, label))).map((i) => issueView(repo, i));
				}
				const issue = {
					number: repos[repo].nextIssue++,
					title: body.title,
					body: body.body ?? '',
					state: 'open',
					state_reason: null,
					labels: [...(body.labels ?? [])],
					user: { login: actor },
				};
				repos[repo].issues.push(issue);
				return issueView(repo, issue);
			}
			if ((m = pathname.match(/^\/repos\/([^/]+\/[^/]+)\/issues\/comments\/(\d+)$/))) {
				const [, repo, id] = m;
				const comment = commentOf(repo, id);
				if (!comment) return null;
				if (method === 'PATCH') comment.body = body.body;
				if (method === 'DELETE') repos[repo].comments = repos[repo].comments.filter((c) => c !== comment);
				return method === 'DELETE' ? null : commentView(repo, comment);
			}
			if ((m = pathname.match(/^\/repos\/([^/]+\/[^/]+)\/issues\/(\d+)\/comments$/))) {
				const [, repo, n] = m;
				if (method === 'GET') return repos[repo].comments.filter((c) => c.issue === Number(n)).map((c) => commentView(repo, c));
				const comment = { id: repos[repo].nextComment++, issue: Number(n), body: body.body, user: { login: actor } };
				repos[repo].comments.push(comment);
				return commentView(repo, comment);
			}
			if ((m = pathname.match(/^\/repos\/([^/]+\/[^/]+)\/issues\/(\d+)\/labels$/))) {
				const issue = issueOf(m[1], m[2]);
				for (const name of body.labels) if (!issue.labels.some((l) => sameName(l, name))) issue.labels.push(name);
				return issue.labels.map((name) => ({ name }));
			}
			if ((m = pathname.match(/^\/repos\/([^/]+\/[^/]+)\/issues\/(\d+)\/labels\/(.+)$/))) {
				const issue = issueOf(m[1], m[2]);
				const name = decodeURIComponent(m[3]);
				if (!issue.labels.some((l) => sameName(l, name))) {
					if (options.allow404) return null;
					throw new Error('label not on issue');
				}
				issue.labels = issue.labels.filter((l) => !sameName(l, name));
				return null;
			}
			if ((m = pathname.match(/^\/repos\/([^/]+\/[^/]+)\/issues\/(\d+)$/))) {
				const [, repo, n] = m;
				const issue = repos[repo].issues.find((i) => i.number === Number(n));
				if (!issue) {
					if (options.allow404) return null;
					throw new Error(`404 ${path}`);
				}
				if (method === 'PATCH') {
					if (body.title !== undefined) issue.title = body.title;
					if (body.body !== undefined) issue.body = body.body;
					if (body.state !== undefined) {
						issue.state = body.state;
						issue.state_reason = body.state === 'closed' ? (body.state_reason ?? 'completed') : null;
					}
				}
				return issueView(repo, issue);
			}
			throw new Error(`fake GitHub: unhandled ${method} ${path}`);
		}
		return {
			get: async (path, options) => route('GET', path, undefined, options),
			post: async (path, body) => route('POST', path, body),
			patch: async (path, body) => route('PATCH', path, body),
			del: async (path, options) => route('DELETE', path, undefined, options),
			paginate: async (path) => route('GET', path),
		};
	}

	return {
		repos,
		writes,
		client,
		issue: (repo, n) => issueOf(repo, n),
		comments: (repo, n) => repos[repo].comments.filter((c) => c.issue === Number(n)),
		addIssue(repo, { title, body = '', labels = [], user = 'reporter' }) {
			const issue = { number: repos[repo].nextIssue++, title, body, state: 'open', state_reason: null, labels: [...labels], user: { login: user } };
			repos[repo].issues.push(issue);
			return issue;
		},
		addComment(repo, n, body, login) {
			const comment = { id: repos[repo].nextComment++, issue: Number(n), body, user: { login } };
			repos[repo].comments.push(comment);
			return comment;
		},
		mirrors: () => repos[S.PRIVATE_REPO].issues.filter((i) => i.labels.includes(S.MIRROR_LABEL)),
	};
}

function setup(issue = {}) {
	const gh = createFake();
	const pub = gh.client('github-actions');
	const priv = gh.client('maintainer-pat');
	const P = gh.addIssue(S.PUBLIC_REPO, { title: 'Menu bar icon missing', body: 'It disappears.', labels: ['bug', 'needs-triage', S.TRIGGER_LABEL], ...issue });
	const run = () => S.reconcile({ pub, priv, publicNumber: P.number, log: () => {} });
	const Q = () => gh.mirrors()[0];
	return { gh, P, run, Q };
}

// ---------------------------------------------------------------------------
// Text handling
// ---------------------------------------------------------------------------

test('sanitizeForPrivate rewrites #N, stops pings and strips markers, but leaves code alone', () => {
	const text = ['See #12 and @octocat, mail me@example.com or https://x.test/y#12.', 'Keep `@inline #5` as is, but #5 is public.', '```', '@fenced #7', '```', '<!-- aap-sync:public=X#1 -->'].join('\n');
	const out = S.sanitizeForPrivate(text);
	assert.match(out, /See App-Auto-Patch\/App-Auto-Patch#12 and @\u200boctocat/);
	assert.ok(out.includes('me@example.com'));
	assert.ok(out.includes('https://x.test/y#12'));
	assert.ok(out.includes('`@inline #5`'));
	assert.ok(out.includes('but App-Auto-Patch/App-Auto-Patch#5 is public'));
	assert.ok(out.includes('@fenced #7'));
	assert.ok(!out.includes('aap-sync:'));
});

test('sanitizeForPublic removes private links and defuses #N', () => {
	const out = S.sanitizeForPublic('Fixed in #153, see https://github.com/App-Auto-Patch/AAP4-Swift/pull/153) and App-Auto-Patch/AAP4-Swift#9. `#4` stays.');
	assert.ok(out.includes('`#153`'));
	assert.ok(out.includes('(private link removed)'));
	assert.ok(out.includes('`#9`'));
	assert.ok(out.includes('`#4` stays'));
	assert.ok(!out.includes('AAP4-Swift'));
});

test('/public commands', () => {
	assert.equal(S.isPublicCommand('/public hello'), true);
	assert.equal(S.isPublicCommand('  /PUBLIC\nhello'), true);
	assert.equal(S.isPublicCommand('/publication'), false);
	assert.equal(S.isPublicCommand('hello /public'), false);
	assert.equal(S.stripPublicCommand('/public  Fixed.\nMore'), 'Fixed.\nMore');
});

test('markers round trip and cannot be forged by user text', () => {
	assert.equal(S.readMarker(S.marker('public', 'A/B#1'), 'public'), 'A/B#1');
	assert.equal(S.readMarker(S.marker('public-comment', 7), 'public'), null);
	assert.equal(S.isSyncText(S.sanitizeForPrivate('<!-- aap-sync:ack -->')), false);
});

test('resolvePublicNumber', () => {
	const pubEvent = { issue: { number: 294 } };
	assert.equal(S.resolvePublicNumber({ eventName: 'issues', repo: S.PUBLIC_REPO, event: pubEvent }), 294);
	assert.equal(S.resolvePublicNumber({ eventName: 'issues', repo: S.PUBLIC_REPO, event: { issue: { number: 3, pull_request: {} } } }), null);
	const body = `${S.marker('public', `${S.PUBLIC_REPO}#291`)}\ntext`;
	assert.equal(S.resolvePublicNumber({ eventName: 'issues', repo: S.PRIVATE_REPO, event: { issue: { number: 160, body } } }), 291);
	assert.equal(S.resolvePublicNumber({ eventName: 'issues', repo: S.PRIVATE_REPO, event: { issue: { number: 161, body: 'plain' } } }), null);
	assert.equal(S.resolvePublicNumber({ eventName: 'workflow_dispatch', repo: S.PUBLIC_REPO, event: { inputs: { issue_number: '12' } } }), 12);
	assert.equal(S.resolvePublicNumber({ eventName: 'workflow_dispatch', repo: S.PUBLIC_REPO, event: { inputs: { issue_number: 'x' } } }), null);
});

// ---------------------------------------------------------------------------
// Creating the private twin
// ---------------------------------------------------------------------------

test('creates the private issue, labels it, credits the reporter and acknowledges publicly', async () => {
	const { gh, P, run, Q } = setup({ user: 'reporter' });
	const outcome = await run();
	assert.equal(outcome.result, 'created');
	const q = Q();
	assert.equal(q.title, 'Menu bar icon missing');
	assert.deepEqual([...q.labels].sort(), ['bug', 'from-public']);
	assert.equal(S.readMarker(q.body, 'public'), `${S.PUBLIC_REPO}#${P.number}`);
	assert.deepEqual(S.readBase(q.body), { s: 'open', l: [] });
	assert.ok(q.body.includes('by @reporter.'));
	assert.ok(q.body.includes('It disappears.'));
	const ack = gh.comments(S.PUBLIC_REPO, P.number);
	assert.equal(ack.length, 1);
	assert.ok(S.hasMarker(ack[0].body, 'ack'));
	assert.equal(ack[0].user.login, 'github-actions');
	assert.equal(gh.comments(S.PRIVATE_REPO, q.number).length, 0, 'the acknowledgement is not mirrored');
});

test('a second run finds nothing to do', async () => {
	const { gh, run } = setup();
	await run();
	const before = gh.writes.length;
	const outcome = await run();
	assert.equal(outcome.result, 'synced');
	assert.equal(gh.writes.length, before);
	assert.equal(gh.mirrors().length, 1);
});

test('an issue without the version 4 label is ignored until it gets the label', async () => {
	const { gh, P, run } = setup({ labels: ['bug', 'needs-triage'] });
	assert.equal((await run()).result, 'detached');
	assert.equal(gh.writes.length, 0);
	P.labels.push(S.TRIGGER_LABEL);
	assert.equal((await run()).result, 'created');
	assert.equal(gh.mirrors().length, 1);
});

test('an issue that is already closed is mirrored as closed', async () => {
	const { gh, P, run, Q } = setup();
	P.state = 'closed';
	P.state_reason = 'not_planned';
	await run();
	assert.equal(Q().state, 'closed');
	assert.equal(Q().state_reason, 'not_planned');
	assert.deepEqual(S.readBase(Q().body), { s: 'closed', l: [] });
	assert.equal(gh.mirrors().length, 1);
});

test('very long bodies are truncated', async () => {
	const { run, Q } = setup({ body: 'x'.repeat(70000) });
	await run();
	assert.ok(Q().body.length < 60200);
	assert.ok(Q().body.includes('Truncated'));
});

// ---------------------------------------------------------------------------
// Public edits flow to the private issue
// ---------------------------------------------------------------------------

test('title, body and type labels follow the public issue; private extras are removed', async () => {
	const { gh, P, run, Q } = setup();
	await run();
	P.title = 'Menu bar icon vanishes';
	P.body = 'New text with a forged <!-- aap-sync:public=App-Auto-Patch/App-Auto-Patch#1 --> marker.';
	P.labels = ['enhancement', S.TRIGGER_LABEL];
	gh.issue(S.PRIVATE_REPO, Q().number).labels.push('bug');
	await run();
	assert.equal(Q().title, 'Menu bar icon vanishes');
	assert.ok(Q().body.includes('New text with a forged'));
	assert.equal(S.readMarker(Q().body, 'public'), `${S.PUBLIC_REPO}#${P.number}`);
	assert.deepEqual([...Q().labels].sort(), ['enhancement', 'from-public']);
	assert.equal(gh.mirrors().length, 1);
});

// ---------------------------------------------------------------------------
// Comments
// ---------------------------------------------------------------------------

test('public comments are mirrored, kept up to date and marked deleted', async () => {
	const { gh, P, run, Q } = setup();
	await run();
	const c = gh.addComment(S.PUBLIC_REPO, P.number, 'Happens on 15.4, @bob see #3.', 'alice');
	await run();
	let mirrored = gh.comments(S.PRIVATE_REPO, Q().number);
	assert.equal(mirrored.length, 1);
	assert.equal(S.readMarker(mirrored[0].body, 'public-comment'), String(c.id));
	assert.ok(mirrored[0].body.includes('**@alice** commented on the public issue'));
	assert.ok(mirrored[0].body.includes('@\u200bbob see App-Auto-Patch/App-Auto-Patch#3'));

	c.body = 'Edited text.';
	await run();
	mirrored = gh.comments(S.PRIVATE_REPO, Q().number);
	assert.equal(mirrored.length, 1);
	assert.ok(mirrored[0].body.includes('Edited text.'));

	gh.repos[S.PUBLIC_REPO].comments = gh.repos[S.PUBLIC_REPO].comments.filter((x) => x !== c);
	await run();
	mirrored = gh.comments(S.PRIVATE_REPO, Q().number);
	assert.equal(mirrored.length, 1);
	assert.ok(mirrored[0].body.includes('deleted on the public issue'));
	const before = gh.writes.length;
	await run();
	assert.equal(gh.writes.length, before);
});

test('only /public comments cross to the public issue, and they stay in step', async () => {
	const { gh, P, run, Q } = setup();
	await run();
	gh.addComment(S.PRIVATE_REPO, Q().number, 'Internal: this is our fault, see #153.', 'dan-snelson');
	const reply = gh.addComment(S.PRIVATE_REPO, Q().number, '/public Fixed in build 81, see #153 and https://github.com/App-Auto-Patch/AAP4-Swift/pull/153', 'dan-snelson');
	await run();
	let publicComments = gh.comments(S.PUBLIC_REPO, P.number).filter((c) => S.hasMarker(c.body, 'private-comment'));
	assert.equal(publicComments.length, 1);
	assert.ok(publicComments[0].body.includes('Maintainer reply from @dan-snelson'));
	assert.ok(publicComments[0].body.includes('Fixed in build 81'));
	assert.ok(!publicComments[0].body.includes('AAP4-Swift'));
	assert.ok(!publicComments[0].body.includes('Internal'));
	assert.equal(gh.comments(S.PUBLIC_REPO, P.number).length, 2, 'acknowledgement plus the reply');
	assert.equal(gh.comments(S.PRIVATE_REPO, Q().number).length, 2, 'nothing mirrored back');

	reply.body = '/public Corrected: fixed in build 82.';
	await run();
	publicComments = gh.comments(S.PUBLIC_REPO, P.number).filter((c) => S.hasMarker(c.body, 'private-comment'));
	assert.equal(publicComments.length, 1);
	assert.ok(publicComments[0].body.includes('build 82'));

	reply.body = 'Actually, keep this internal.';
	await run();
	assert.equal(gh.comments(S.PUBLIC_REPO, P.number).filter((c) => S.hasMarker(c.body, 'private-comment')).length, 0);
});

// ---------------------------------------------------------------------------
// State and status labels
// ---------------------------------------------------------------------------

test('closing and reopening follow whichever side changed', async () => {
	const { gh, P, run, Q } = setup();
	await run();

	P.state = 'closed';
	P.state_reason = 'not_planned';
	await run();
	assert.equal(Q().state, 'closed');
	assert.equal(Q().state_reason, 'not_planned');
	assert.equal(S.readBase(Q().body).s, 'closed');

	gh.issue(S.PRIVATE_REPO, Q().number).state = 'open';
	await run();
	assert.equal(P.state, 'open', 'the public issue is reopened by the private side');
	assert.equal(S.readBase(Q().body).s, 'open');

	const q = gh.issue(S.PRIVATE_REPO, Q().number);
	q.state = 'closed';
	q.state_reason = 'completed';
	await run();
	assert.equal(P.state, 'closed');
	assert.equal(P.state_reason, 'completed');
	const before = gh.writes.length;
	await run();
	assert.equal(gh.writes.length, before);
});

test('status labels sync both ways, including removal', async () => {
	const { gh, P, run, Q } = setup();
	await run();

	gh.issue(S.PRIVATE_REPO, Q().number).labels.push('Planned');
	await run();
	assert.ok(P.labels.includes('Planned'));
	assert.deepEqual(S.readBase(Q().body).l, ['Planned']);

	P.labels.push('In Progress');
	await run();
	assert.ok(Q().labels.includes('In Progress'));

	P.labels = P.labels.filter((l) => l !== 'Planned');
	await run();
	assert.ok(!Q().labels.includes('Planned'));

	const q = gh.issue(S.PRIVATE_REPO, Q().number);
	q.labels = q.labels.filter((l) => l !== 'In Progress');
	await run();
	assert.ok(!P.labels.includes('In Progress'));
	assert.deepEqual(S.readBase(Q().body).l, []);
	const before = gh.writes.length;
	await run();
	assert.equal(gh.writes.length, before);
});

test('labels that are not on the status list never cross to the public issue', async () => {
	const { gh, P, run, Q } = setup();
	await run();
	gh.issue(S.PRIVATE_REPO, Q().number).labels.push('help wanted', 'internal-only');
	await run();
	assert.deepEqual([...P.labels].sort(), ['bug', 'needs-triage', S.TRIGGER_LABEL].sort());
});

// ---------------------------------------------------------------------------
// Stopping and resuming
// ---------------------------------------------------------------------------

test('removing the version 4 label stops syncing once, and adding it back resumes without a duplicate', async () => {
	const { gh, P, run, Q } = setup();
	await run();
	P.labels = P.labels.filter((l) => l !== S.TRIGGER_LABEL);
	P.title = 'Changed while detached';
	assert.equal((await run()).result, 'detached');
	assert.equal((await run()).result, 'detached');
	assert.equal(gh.comments(S.PRIVATE_REPO, Q().number).filter((c) => S.hasMarker(c.body, 'detached')).length, 1);
	assert.equal(Q().title, 'Menu bar icon missing');

	P.labels.push(S.TRIGGER_LABEL);
	assert.equal((await run()).result, 'synced');
	assert.equal(Q().title, 'Changed while detached');
	assert.equal(gh.mirrors().length, 1);
});
