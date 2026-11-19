/**
 * NA Tunnel - Cloudflare Worker for Server 1 (Primary Node)
 * Worker Domain: na-tunnel.hakrortanabun1.workers.dev
 * Target Backend: na-tunnel-sg.duckdns.org:80 (129.150.63.107)
 * Carrier Support: Metfone $0 Balance & Smart Axiata Clean IP Reverse Proxy
 */

const TARGET_HOST = "na-tunnel-sg.duckdns.org";
const TARGET_PORT = "80";
const SERVICE_NAME = "NA Tunnel Metfone High-Speed Node 1 (SG-01)";

export default {
    async fetch(request, env, ctx) {
        const url = new URL(request.url);

        // Forward to Server 1 Oracle VPS via DuckDNS
        url.hostname = TARGET_HOST;
        url.port = TARGET_PORT;
        url.protocol = "http:";

        const newHeaders = new Headers(request.headers);
        newHeaders.set("Host", TARGET_HOST);

        const upgradeHeader = request.headers.get("Upgrade");

        // 1. WebSocket Tunneling (VLESS WebSocket for Metfone $0 Balance)
        if (upgradeHeader && upgradeHeader.toLowerCase() === "websocket") {
            try {
                return await fetch(url.toString(), {
                    method: "GET",
                    headers: newHeaders,
                    cf: {
                        cacheTtl: 0,
                        cacheEverything: false
                    }
                });
            } catch (err) {
                return new Response(JSON.stringify({
                    error: "Upstream WebSocket Connection Failed",
                    target: `${TARGET_HOST}:${TARGET_PORT}`,
                    message: err.message || String(err)
                }, null, 2), {
                    status: 502,
                    headers: { "Content-Type": "application/json;charset=utf-8" }
                });
            }
        }

        // 2. Health & Performance Diagnostic Check
        if (request.method === "GET") {
            return new Response(JSON.stringify({
                status: "Online",
                service: SERVICE_NAME,
                server: "Server 1 (Primary)",
                target: `${TARGET_HOST}:${TARGET_PORT}`,
                carrier: "Metfone $0 Balance & Smart Axiata Bypass",
                streaming: "Direct Oracle VPS Gigabit (No Buffering)",
                timestamp: new Date().toISOString()
            }, null, 2), {
                status: 200,
                headers: {
                    "Content-Type": "application/json;charset=utf-8",
                    "Cache-Control": "no-store, no-cache, must-revalidate"
                }
            });
        }

        // 3. Other HTTP methods (POST, PUT, OPTIONS, etc.)
        try {
            return await fetch(url.toString(), {
                method: request.method,
                headers: newHeaders,
                body: request.body,
                redirect: "manual",
                cf: {
                    cacheTtl: 0,
                    cacheEverything: false
                }
            });
        } catch (err) {
            return new Response(JSON.stringify({
                error: "Upstream Proxy Error",
                target: `${TARGET_HOST}:${TARGET_PORT}`,
                message: err.message || String(err)
            }, null, 2), {
                status: 502,
                headers: { "Content-Type": "application/json;charset=utf-8" }
            });
        }
    }
};
