// Serves this playground folder.  bun trash/playground/<ctx>/server.ts
//   PORT=3333                                 port (default 3333)
//   API_PROXY=http://localhost:8000/v1        /api/* → that base (the API usually allows only the app's origin)
//   PUBLIC_DIR=web/public                     fallback for images and fonts, relative to the repo root
const root = `${import.meta.dir}/../../..`
const proxy = process.env.API_PROXY?.replace(/\/$/, '')
const publicDir = process.env.PUBLIC_DIR ? `${root}/${process.env.PUBLIC_DIR}` : null

const server = Bun.serve({
  port: Number(process.env.PORT ?? 3333),
  async fetch(req) {
    const url = new URL(req.url)
    if (proxy && url.pathname.startsWith('/api/')) {
      return fetch(`${proxy}/${url.pathname.slice(5)}${url.search}`, {
        method: req.method,
        headers: { Accept: 'application/json', 'Content-Type': req.headers.get('Content-Type') ?? 'application/json' },
        body: ['GET', 'HEAD'].includes(req.method) ? undefined : await req.text(),
      })
    }
    const path = url.pathname === '/' ? '/README.md' : decodeURIComponent(url.pathname)
    for (const base of [import.meta.dir, publicDir]) {
      if (!base) continue
      const file = Bun.file(`${base}${path}`)
      if (await file.exists()) return new Response(file, { headers: { 'Cache-Control': 'no-store' } })
    }
    return new Response('Not Found', { status: 404 })
  },
})
console.log(`Theme playground at http://localhost:${server.port}/`)
