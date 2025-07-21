import type { Team, Project, Issue } from "@linear/sdk";
import { LinearClient } from "@linear/sdk";
import stringify from "safe-stable-stringify";

/*
  ------------------------------------------------------------------------------------
  Linear CLI – read-only utilities
  ------------------------------------------------------------------------------------
  Commands implemented (only READ-type operations for now):
    • teams                              – list all teams the API key can access
    • projects [--teamId <id>]           – list projects (optionally filtered by team)
    • issues-by-team --teamId <id>       – list open issues in the given team
    • issues-by-project --projectId <id> – list open issues in the given project
    • get-issue --id <identifier|uuid>   – detailed info for a single issue
    • branch-for-issue --id <identifier|uuid> – return branch name associated with issue

  Usage examples:
    npx tsx linear.ts teams --debug
    npx tsx linear.ts projects --teamId e48ca2cc-... --debug
    npx tsx linear.ts get-issue --id JT-25

  Notes:
  • All output is JSON so that shell scripts/zsh functions can parse it easily.
  • Use the --debug flag (or DEBUG_LINEAR=1 env var) for verbose logging to stderr.
  • Mutating operations (begin / create-issue) are intentionally NOT implemented yet –
    they will be added after manual approval.
*/

// -------------------------------------------------------------------------------------------------
// Environment
// -------------------------------------------------------------------------------------------------
const apiKey: string | undefined = process.env.LINEAR_API_KEY;
if (!apiKey) {
	console.error(
		JSON.stringify({
			error: "LINEAR_API_KEY environment variable is not set.",
		}),
	);
	process.exit(1);
}

const linear = new LinearClient({ apiKey });

// Optionally supplied user id (used later for filtering in mutations)
const LINEAR_USER_ID: string | undefined = process.env.LINEAR_USER_ID;

// -------------------------------------------------------------------------------------------------
// Main
// -------------------------------------------------------------------------------------------------
async function main(): Promise<void> {
	const rawArgs = process.argv.slice(2);
	const argv = stripGlobalFlags(rawArgs);
	const command = argv[0];
	const rest = argv.slice(1);
	const params = parseArgs(rest);

	try {
		switch (command) {
			case "teams": {
				const all = Boolean(params.all);
				const json = JSON.stringify(await listTeams(all), null, 2);
				console.log(json);
				return;
			}
			case "projects": {
				const all = Boolean(params.all);
				const json = JSON.stringify(
					await listProjects(params.teamId as string | undefined, all),
					null,
					2,
				);
				console.log(json);
				return;
			}
			case "issues": {
				const json = JSON.stringify(
					await listIssues(
						params.teamId as string | undefined,
						params.projectId as string | undefined,
					),
					null,
					2,
				);
				console.log(json);
				return;
			}
			case "issue": {
				// Accept issue ID as positional argument or --id flag
				const issueId =
					rest[0] && !rest[0].startsWith("--")
						? rest[0]
						: (params.id as string);
				const json = stringify(await getIssue(issueId), null, 2);
				console.log(json);
				return;
			}
			case "me": {
				const json = JSON.stringify(await getMe(), null, 2);
				console.log(json);
				return;
			}
			case "set-userId": {
				const json = JSON.stringify(await setUserId(), null, 2);
				console.log(json);
				return;
			}
			default:
				console.error(
					JSON.stringify({
						error: `Unknown command: ${command}`,
						supported: [
							"teams",
							"projects",
							"issues",
							"issue",
							"me",
							"set-userId",
						],
					}),
				);
				process.exit(1);
				return;
		}
	} catch (err: unknown) {
		const error = err as Error;
		console.error(JSON.stringify({ error: error.message, stack: error.stack }));
		process.exit(1);
	}
}

main();

// -------------------------------------------------------------------------------------------------
// CLI argument parsing (very small utility – avoids bringing external deps)
// -------------------------------------------------------------------------------------------------
interface ParsedArgs {
	[key: string]: string | boolean;
}

function parseArgs(argv: string[]): ParsedArgs {
	const parsed: ParsedArgs = {};
	for (let i = 0; i < argv.length; i++) {
		const arg = argv[i];
		if (arg.startsWith("--")) {
			const key = arg.slice(2);
			// next token is value if it does not start with '--'
			const next = argv[i + 1];
			if (next && !next.startsWith("--")) {
				parsed[key] = next;
				i++; // skip value
			} else {
				parsed[key] = true; // flag style
			}
		}
	}
	return parsed;
}

// -------------------------------------------------------------------------------------------------
// Logging helpers (info to stderr, debug to stderr when enabled)
// -------------------------------------------------------------------------------------------------
const parsedGlobalArgs = parseArgs(process.argv.slice(2));
const DEBUG_ENABLED: boolean =
	Boolean(parsedGlobalArgs.debug) || process.env.DEBUG_LINEAR === "1";

function debug(message: unknown, ...optional: unknown[]): void {
	if (DEBUG_ENABLED) {
		console.error(`[DEBUG] ${String(message)}`, ...optional);
	}
}

function info(message: unknown, ...optional: unknown[]): void {
	console.error(`[INFO] ${String(message)}`, ...optional);
}

// Remove global flags (like --debug) from argv before command dispatch
function stripGlobalFlags(argv: string[]): string[] {
	const copy = [...argv];
	return copy.filter((token, idx) => {
		if (!token.startsWith("--")) return true;
		const key = token.slice(2);
		if (key === "debug") {
			// remove flag and following value if any (though we use flag style only)
			return false;
		}
		return true;
	});
}

// -------------------------------------------------------------------------------------------------
// Utility helpers
// -------------------------------------------------------------------------------------------------
async function collectAllNodes<T>(
	connectionPromise: Promise<{
		nodes: T[];
		pageInfo?: { hasNextPage: boolean };
		next?: () => Promise<any>;
	}>,
): Promise<T[]> {
	const firstConn = await connectionPromise;
	let nodes: T[] = [...(firstConn.nodes ?? [])];
	let currentConn: any = firstConn;

	while (
		currentConn.pageInfo?.hasNextPage &&
		typeof currentConn.next === "function"
	) {
		currentConn = await currentConn.next();
		nodes = nodes.concat(currentConn.nodes ?? []);
	}
	return nodes;
}

// -------------------------------------------------------------------------------------------------
// Command implementations (READ-only)
// -------------------------------------------------------------------------------------------------
async function listTeams(showAll = false): Promise<unknown> {
	info("Fetching teams…");
	const teams: Team[] = await collectAllNodes(linear.teams());

	if (showAll) {
		debug(`Teams returned: ${teams.length} (showing all)`);
		return teams.map((t) => ({ id: t.id, key: t.key, name: t.name }));
	}

	// Get current user's team memberships (same approach as getMe())
	const viewer = await linear.viewer;
	if (!viewer) throw new Error("Could not fetch current user");

	const teamMembershipsConnection = await viewer.teamMemberships();
	const teamMemberships = await collectAllNodes(
		Promise.resolve(teamMembershipsConnection),
	);

	// Extract team IDs from memberships
	const myTeamIds = new Set<string>();
	for (const membership of teamMemberships as any[]) {
		const team = await membership.team;
		if (team) {
			myTeamIds.add(team.id);
		}
	}

	const filtered = teams.filter((t) => myTeamIds.has(t.id));

	debug(`Teams returned: ${filtered.length} (filtered by current membership)`);
	return filtered.map((t) => ({ id: t.id, key: t.key, name: t.name }));
}

async function listProjects(
	teamIdArg: string | undefined,
	showAll = false,
): Promise<unknown> {
	info("Fetching projects…");
	const projects: Project[] = await collectAllNodes(linear.projects());

	// Resolve team information for all projects
	const projectsWithTeams = await Promise.all(
		projects.map(async (p) => {
			const teams = await p.teams();
			const firstTeam = teams.nodes?.[0];
			return {
				id: p.id,
				name: p.name,
				state: p.state,
				teamId: firstTeam?.id || null,
				teamName: firstTeam?.name || null,
			};
		}),
	);

	// If --teamId is specified, filter by that specific team
	if (teamIdArg) {
		const filtered = projectsWithTeams.filter((p) => p.teamId === teamIdArg);
		debug(
			`Projects returned: ${filtered.length} (filtered by teamId: ${teamIdArg})`,
		);

		return filtered;
	}

	// If --all is specified, show all projects
	if (showAll) {
		debug(`Projects returned: ${projectsWithTeams.length} (showing all)`);
		return projectsWithTeams;
	}

	// Default: show only projects from teams I'm a member of
	const viewer = await linear.viewer;
	if (!viewer) throw new Error("Could not fetch current user");

	const teamMembershipsConnection = await viewer.teamMemberships();
	const teamMemberships = await collectAllNodes(
		Promise.resolve(teamMembershipsConnection),
	);

	// Extract team IDs from memberships
	const myTeamIds = new Set<string>();
	for (const membership of teamMemberships as any[]) {
		const team = await membership.team;
		if (team) {
			myTeamIds.add(team.id);
		}
	}

	const filtered = projectsWithTeams.filter(
		(p) => p.teamId && myTeamIds.has(p.teamId),
	);
	debug(
		`Projects returned: ${filtered.length} (filtered by current team membership)`,
	);
	return filtered;
}

async function listIssues(
	teamId: string | undefined,
	projectId: string | undefined,
): Promise<unknown> {
	if (!teamId && !projectId) {
		throw new Error("Either --teamId or --projectId is required for issues");
	}
	if (teamId && projectId) {
		throw new Error("Cannot specify both --teamId and --projectId for issues");
	}

	let connection: any;
	let filterDescription: string;

	if (teamId) {
		info(`Fetching open issues for team ${teamId}…`);
		connection = await linear.issues({
			filter: {
				team: { id: { eq: teamId } },
				completedAt: { null: true },
			},
		});
		filterDescription = `team ${teamId}`;
	} else {
		info(`Fetching open issues for project ${projectId}…`);
		connection = await linear.issues({
			filter: {
				project: { id: { eq: projectId } },
				completedAt: { null: true },
			},
		});
		filterDescription = `project ${projectId}`;
	}

	const issues: Issue[] = await collectAllNodes(Promise.resolve(connection));
	debug(`Issues fetched for ${filterDescription}:`, issues.length);

	const result: unknown[] = [];
	for (const iss of issues) {
		const state = await iss.state;
		result.push({
			id: iss.id,
			identifier: iss.identifier,
			title: iss.title,
			branchName: iss.branchName,
			state: state?.name ?? null,
			assigneeId: iss.assigneeId,
		});
	}
	return result;
}

async function getIssue(issueId: string): Promise<unknown> {
	if (!issueId)
		throw new Error(
			"Issue ID is required for issue (e.g., 'VIT-364' or '--id VIT-364')",
		);
	info(`Fetching issue ${issueId}…`);
	const issue = await linear.issue(issueId);
	if (!issue) throw new Error(`Issue ${issueId} not found`);
	const project = await issue.project;
	const assignee = await issue.assignee;
	const state = await issue.state;
	debug("Issue fetched:", issue);
	return {
		id: issue.id,
		identifier: issue.identifier,
		title: issue.title,
		description: issue.description,
		url: issue.url,
		branchName: issue.branchName,
		project: project ? { id: project.id, name: project.name } : null,
		assignee: assignee ? { id: assignee.id, name: assignee.name } : null,
		state: state ? { id: state.id, name: state.name, type: state.type } : null,
	};
}

async function getMe(): Promise<unknown> {
	info("Fetching current user info…");

	// Get viewer (current user)
	const viewer = await linear.viewer;
	if (!viewer) throw new Error("Could not fetch current user");

	debug("Raw viewer object:", viewer);

	// Get teams I'm a member of directly from viewer
	const teamMembershipsConnection = await viewer.teamMemberships();
	const teamMemberships = await collectAllNodes(
		Promise.resolve(teamMembershipsConnection),
	);

	debug("Team memberships:", teamMemberships.length);

	// Extract teams from memberships
	const myTeams: Team[] = [];
	for (const membership of teamMemberships as any[]) {
		const team = await membership.team;
		if (team) {
			myTeams.push(team);
		}
	}

	debug("User info fetched:", {
		userId: viewer.id,
		teamsCount: myTeams.length,
	});

	return {
		id: viewer.id,
		name: viewer.name,
		email: viewer.email,
		displayName: viewer.displayName,
		teams: myTeams.map((t) => ({ id: t.id, key: t.key, name: t.name })),
	};
}

async function setUserId(): Promise<unknown> {
	info("Fetching current user ID from Linear…");

	// Get viewer (current user)
	const viewer = await linear.viewer;
	if (!viewer) throw new Error("Could not fetch current user");

	const userId = viewer.id;
	info(`Found user ID: ${userId}`);

	// Path to the zshrc.local.symlink file
	const fs = require("node:fs");
	const path = require("node:path");
	const zshrcPath = path.join(__dirname, "..", "zsh", "zshrc.local.symlink");

	try {
		// Read the current file
		let content = "";
		if (fs.existsSync(zshrcPath)) {
			content = fs.readFileSync(zshrcPath, "utf8");
		}

		// Split into lines
		const lines = content.split("\n");

		// Look for existing LINEAR_USER_ID line
		const userIdLineIndex = lines.findIndex((line) =>
			line.trim().startsWith("export LINEAR_USER_ID="),
		);

		const newUserIdLine = `export LINEAR_USER_ID="${userId}"`;

		if (userIdLineIndex >= 0) {
			// Update existing line
			lines[userIdLineIndex] = newUserIdLine;
			info(`Updated existing LINEAR_USER_ID in ${zshrcPath}`);
		} else {
			// Find a good place to insert it (after LINEAR_API_KEY if it exists)
			const apiKeyIndex = lines.findIndex((line) =>
				line.trim().startsWith("export LINEAR_API_KEY="),
			);

			if (apiKeyIndex >= 0) {
				// Insert after LINEAR_API_KEY
				lines.splice(apiKeyIndex + 1, 0, newUserIdLine);
			} else {
				// Add at the beginning
				lines.unshift(newUserIdLine);
			}
			info(`Added LINEAR_USER_ID to ${zshrcPath}`);
		}

		// Write back to file
		fs.writeFileSync(zshrcPath, lines.join("\n"));

		return {
			userId,
			message: `Successfully set LINEAR_USER_ID to ${userId} in ${zshrcPath}`,
			note: "Please restart your shell or run 'source ~/.zshrc' to use the new value",
		};
	} catch (err) {
		throw new Error(`Failed to update zshrc file: ${(err as Error).message}`);
	}
}
