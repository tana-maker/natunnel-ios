export default {
    async fetch(request) {
        const url = new URL(request.url);

        // Forward directly to your Oracle VPS via DuckDNS
        url.hostname = "na-tunnel-sg.duckdns.org";
        url.port = "80";
        url.protocol = "http:";

        const newHeaders = new Headers(request.headers);
        newHeaders.set("Host", "na-tunnel-sg.duckdns.org");

        const upgradeHeader = request.headers.get("Upgrade");

        // 1. WebSocket Tunneling (VLESS tunnel for Metfone $0 Balance)
        // CRITICAL FIX: Do NOT pass `body: request.body` on GET/WebSocket requests
        // (passing body on GET throws a TypeError in Cloudflare Workers and crashes the tunnel)
        if (upgradeHeader && upgradeHeader.toLowerCase() === "websocket") {
            return fetch(url.toString(), {
                method: "GET",
                headers: newHeaders
            });
        }

        // 2. Normal Web/Preview Health Check (prevents "Bad Request" error in browser preview)
        if (request.method === "GET") {
            return new Response(JSON.stringify({
                status: "Online",
                service: "NA Tunnel Metfone High-Speed Node",
                target: "na-tunnel-sg.duckdns.org:80",
                carrier: "Metfone $0 Balance Bypass",
                streaming: "Direct Oracle VPS Gigabit (No Buffering)"
            }, null, 2), {
                status: 200,
                headers: { "Content-Type": "application/json;charset=utf-8" }
            });
        }

        // 3. Other HTTP methods if needed (POST, PUT, etc.)
        return fetch(url.toString(), {
            method: request.method,
            headers: newHeaders,
            body: request.body,
            redirect: "manual"
        });
    }
};
