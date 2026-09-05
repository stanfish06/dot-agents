interface Ctx {
  params: { app: string; request_id: string; interval_ms: number; timeout_ms: number; logs: boolean }
  api: {
    call(
      profile: string,
      request: { method?: string; path: string; query?: Record<string, string> },
    ): Promise<{ outcome: string; status?: number; body?: string; message?: string }>
  }
}

interface Status {
  status?: string
  queue_position?: number
  logs?: unknown
  metrics?: unknown
}

const TERMINAL = new Set(['COMPLETED', 'FAILED', 'CANCELLED'])

function parse<T>(body: string | undefined): T | undefined {
  if (!body) return undefined
  try {
    return JSON.parse(body) as T
  } catch {
    return undefined
  }
}

export default async function run(ctx: Ctx) {
  const { request_id, interval_ms, timeout_ms, logs } = ctx.params
  // request sub-paths take only the first two app segments
  const app = ctx.params.app.replace(/^\/+/, '').split('/').slice(0, 2).join('/')
  if (app.split('/').length !== 2) throw new Error(`app must be <owner>/<app>, got \`${ctx.params.app}\``)
  if (!/^[0-9a-f-]{36}$/i.test(request_id)) throw new Error('request_id must be a UUID')

  const base = `/${app}/requests/${request_id}`
  const started = Date.now()
  let polls = 0
  let last: Status | undefined
  let lastCall: { outcome: string; status?: number; message?: string } | undefined

  while (Date.now() - started < timeout_ms) {
    polls += 1
    const response = await ctx.api.call('fal/keyed', {
      method: 'GET',
      path: `${base}/status`,
      query: logs ? { logs: '1' } : undefined,
    })
    lastCall = { outcome: response.outcome, status: response.status, message: response.message }
    if (response.outcome !== 'success') {
      return { done: false, polls, elapsed_ms: Date.now() - started, error: lastCall }
    }
    last = parse<Status>(response.body)
    if (last?.status && TERMINAL.has(last.status)) break
    await new Promise((resolve) => setTimeout(resolve, interval_ms))
  }

  if (!last?.status || !TERMINAL.has(last.status)) {
    return { done: false, timed_out: true, polls, elapsed_ms: Date.now() - started, last_status: last }
  }

  const result = await ctx.api.call('fal/keyed', { method: 'GET', path: base })
  return {
    done: true,
    status: last.status,
    polls,
    elapsed_ms: Date.now() - started,
    logs: last.logs ?? undefined,
    metrics: last.metrics ?? undefined,
    result_status: result.status,
    result: result.outcome === 'success' ? (parse<unknown>(result.body) ?? result.body) : { error: result.outcome, message: result.message },
  }
}
