import { ClickUpClient } from './clickup-client'
import stringify from 'safe-stable-stringify'

/*
  ------------------------------------------------------------------------------------
  ClickUp CLI – read-only utilities
  ------------------------------------------------------------------------------------
  Commands implemented:
    • get-task <task-id>                  – detailed info for a single task
    • start-task <task-id>               – update task status to "IN PROGRESS"
    • pr-task <task-id>                  – update task status to "IN REVIEW"
    • create-task <title> <description>    – create a new task (requires CLICKUP_DEFAULT_LIST_ID)

  Usage examples:
    npx tsx clickup.ts get-task 86ew4x0vz
    npx tsx clickup.ts get-task 86ew4x0vz --debug
    npx tsx clickup.ts start-task 86ew4x0vz
    npx tsx clickup.ts pr-task 86ew4x0vz
    npx tsx clickup.ts create-task "My title" "My description"

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

const listIdRaw = process.env.CLICKUP_DEFAULT_LIST_ID
if (!listIdRaw) {
  console.error(
    JSON.stringify({
      error: 'CLICKUP_DEFAULT_LIST_ID environment variable is not set.',
    }),
  )
  process.exit(1)
}
const listId: string = listIdRaw

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
      case 'get-task': {
        // Accept task ID as positional argument or --id flag
        const taskId = rest[0] && !rest[0].startsWith('--') ? rest[0] : (params.id as string)
        const json = stringify(await getTask(taskId), null, 2)
        console.log(json)
        return
      }
      case 'start-task': {
        // Accept task ID as positional argument or --id flag
        const taskId = rest[0] && !rest[0].startsWith('--') ? rest[0] : (params.id as string)
        const json = stringify(await startTask(taskId), null, 2)
        console.log(json)
        return
      }
      case 'pr-task': {
        // Accept task ID as positional argument or --id flag
        const taskId = rest[0] && !rest[0].startsWith('--') ? rest[0] : (params.id as string)
        const json = stringify(await prTask(taskId), null, 2)
        console.log(json)
        return
      }
      case 'create-task': {
        const title = rest[0] && !rest[0].startsWith('--') ? rest[0] : (params.title as string)
        const description = rest[1] && !rest[1].startsWith('--') ? rest[1] : (params.description as string)
        const json = stringify(await createTask(title, description), null, 2)
        console.log(json)
        return
      }
      default:
        console.error(
          JSON.stringify({
            error: `Unknown command: ${command}`,
            supported: ['get-task', 'start-task', 'pr-task', 'create-task'],
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
  return copy.filter((token) => {
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
// Command implementations
// -------------------------------------------------------------------------------------------------
async function getTask(taskId: string): Promise<unknown> {
  if (!taskId) throw new Error("Task ID is required for get-task (e.g., '86ew4x0vz' or '--id 86ew4x0vz')")
  info(`Fetching task ${taskId}…`)
  const task = await clickUp.getTask(taskId)
  debug('Task fetched:', task)
  return task
}

async function startTask(taskId: string): Promise<unknown> {
  if (!taskId) throw new Error("Task ID is required for start-task (e.g., '86ew4x0vz' or '--id 86ew4x0vz')")
  info(`Updating task ${taskId} status to "IN PROGRESS"…`)
  const task = await clickUp.updateTask(taskId, { status: 'IN PROGRESS' })
  debug('Task updated:', task)
  return task
}

async function prTask(taskId: string): Promise<unknown> {
  if (!taskId) throw new Error("Task ID is required for pr-task (e.g., '86ew4x0vz' or '--id 86ew4x0vz')")
  info(`Updating task ${taskId} status to "IN REVIEW"…`)
  const task = await clickUp.updateTask(taskId, { status: 'IN REVIEW' })
  debug('Task updated:', task)
  return task
}

async function createTask(title: string, description: string): Promise<unknown> {
  if (!title) throw new Error("Title is required for create-task (e.g., 'My title' or --title 'My title')")
  info(`Creating task "${title}"…`)
  const task = await clickUp.createTask(listId, { name: title, description: description || undefined })
  debug('Task created:', task)
  return task
}
