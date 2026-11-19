/**
 * NA Tunnel - Cloudflare Worker for Server 2 (Backup Node)
 * Worker Domain: calm-snowflake-8dcd.softwarepermission.workers.dev
 * Target Backend: na-tunnel-sg2.duckdns.org:80 (152.69.223.67)
 * Carrier Support: Metfone $0 Balance & Smart Axiata Clean IP Reverse Proxy
 */

const TARGET_HOST = "na-tunnel-sg2.duckdns.org";
const TARGET_PORT = "80";
const SERVICE_NAME = "NA Tunnel Metfone VIP-02 Node 2 (SG-02)";

export default {
    async fetch(request, env, ctx) {
        const url = new URL(request.url);

        // Forward to Server 2 Oracle VPS via DuckDNS
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
                server: "Server 2 (Backup)",
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
