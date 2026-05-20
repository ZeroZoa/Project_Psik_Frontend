const functions = require("firebase-functions");
const https = require("https");

const BACKEND_HOST = "psik-backend-1078606124034.asia-northeast3.run.app";

// psik.kr/login/oauth2/code/** 요청을 Cloud Run 백엔드로 프록시
exports.oauthProxy = functions
    .region("asia-northeast1")
    .https.onRequest((req, res) => {
        const options = {
            hostname: BACKEND_HOST,
            path: req.url, // /login/oauth2/code/google?code=...&state=...
            method: "GET",
            headers: {
                host: BACKEND_HOST,
                "x-forwarded-proto": "https",
                "x-forwarded-host": "psik.kr",
            },
        };

        const proxyReq = https.request(options, (proxyRes) => {
            // 302 redirect 포함 헤더 그대로 브라우저로 전달
            res.status(proxyRes.statusCode);
            for (const [key, value] of Object.entries(proxyRes.headers)) {
                if (key.toLowerCase() !== "transfer-encoding") {
                    res.setHeader(key, value);
                }
            }
            proxyRes.pipe(res, { end: true });
        });

        proxyReq.on("error", (err) => {
            console.error("[oauthProxy] error:", err);
            res.status(500).send("Proxy error");
        });

        proxyReq.end();
    });