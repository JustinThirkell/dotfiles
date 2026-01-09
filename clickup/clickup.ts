import { ClickUpClient } from './clickup-client'
import stringify from 'safe-stable-stringify'

/*
  ------------------------------------------------------------------------------------
  ClickUp CLI – read-only utilities
  ------------------------------------------------------------------------------------
  Commands implemented (only READ-type operations for now):
    • issue <task-id>                      – detailed info for a single issue/task

  Usage examples:
    npx tsx clickup.ts issue 86ew4x0vz
    npx tsx clickup.ts issue 86ew4x0vz --debug

  Notes:
  • All output is JSON so that shell scripts/zsh functions can parse it easily.
  • Use the --debug flag for verbose logging to stderr.
*/

// -------------------------------------------------------------------------------------------------
// Environment
// -------------------------------------------------------------------------------------------------
const apiKey: string | undefined = process.env.CLICKUP_API_KEY
if (!apiKey) {
  console.error(
    JSON.stringify({
      error: 'CLICKUP_API_KEY environment variable is not set.',
    }),
  )
  process.exit(1)
}

const clickUp = new ClickUpClient({ apiKey })

// -------------------------------------------------------------------------------------------------
// Main
// -------------------------------------------------------------------------------------------------
async function main(): Promise<void> {
  const rawArgs = process.argv.slice(2)
  const argv = stripGlobalFlags(rawArgs)
  const command = argv[0]
  const rest = argv.slice(1)
  const params = parseArgs(rest)

  try {
    switch (command) {
      case 'issue': {
        // Accept issue ID as positional argument or --id flag
        const issueId = rest[0] && !rest[0].startsWith('--') ? rest[0] : (params.id as string)
        const json = stringify(await getIssue(issueId), null, 2)
        console.log(json)
        return
      }
      default:
        console.error(
          JSON.stringify({
            error: `Unknown command: ${command}`,
            supported: ['issue'],
          }),
        )
        process.exit(1)
        return
    }
  } catch (err: unknown) {
    const error = err as Error
    console.error(JSON.stringify({ error: error.message, stack: error.stack }))
    process.exit(1)
  }
}

main()

// -------------------------------------------------------------------------------------------------
// CLI argument parsing (very small utility – avoids bringing external deps)
// -------------------------------------------------------------------------------------------------
interface ParsedArgs {
  [key: string]: string | boolean
}

function parseArgs(argv: string[]): ParsedArgs {
  const parsed: ParsedArgs = {}
  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i]
    if (arg.startsWith('--')) {
      const key = arg.slice(2)
      // next token is value if it does not start with '--'
      const next = argv[i + 1]
      if (next && !next.startsWith('--')) {
        parsed[key] = next
        i++ // skip value
      } else {
        parsed[key] = true // flag style
      }
    }
  }
  return parsed
}

// -------------------------------------------------------------------------------------------------
// Logging helpers (info to stderr, debug to stderr when enabled)
// -------------------------------------------------------------------------------------------------
const parsedGlobalArgs = parseArgs(process.argv.slice(2))
const DEBUG_ENABLED: boolean = Boolean(parsedGlobalArgs.debug)

function debug(message: unknown, ...optional: unknown[]): void {
  if (DEBUG_ENABLED) {
    console.error(`[DEBUG] ${String(message)}`, ...optional)
  }
}

function info(message: unknown, ...optional: unknown[]): void {
  console.error(`[INFO] ${String(message)}`, ...optional)
}

// Remove global flags (like --debug) from argv before command dispatch
function stripGlobalFlags(argv: string[]): string[] {
  const copy = [...argv]
  return copy.filter((token, idx) => {
    if (!token.startsWith('--')) return true
    const key = token.slice(2)
    if (key === 'debug') {
      // remove flag and following value if any (though we use flag style only)
      return false
    }
    return true
  })
}

// -------------------------------------------------------------------------------------------------
// Command implementations (READ-only)
// -------------------------------------------------------------------------------------------------
async function getIssue(issueId: string): Promise<unknown> {
  if (!issueId) throw new Error("Issue ID is required for issue (e.g., '86ew4x0vz' or '--id 86ew4x0vz')")
  info(`Fetching issue ${issueId}…`)
  const task = await clickUp.getTask(issueId)
  debug('Issue fetched:', task)
  return task
}

