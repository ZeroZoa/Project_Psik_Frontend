const functions = require("firebase-functions");
const https = require("https");

const BACKEND_HOST = "psik-backend-1078606124034.asia-northeast3.run.app";

exports.oauthProxy = functions
    .region("asia-northeast1")
    .https.onRequest((req, res) => {
        const forwardHeaders = {...req.headers};
        forwardHeaders["host"] = BACKEND_HOST;
        forwardHeaders["x-forwarded-proto"] = "https";
        forwardHeaders["x-forwarded-host"] = "psik.kr";

        const options = {
            hostname: BACKEND_HOST,
            path: req.url,
            method: req.method,
            headers: forwardHeaders,
        };

        const proxyReq = https.request(options, (proxyRes) => {
            res.status(proxyRes.statusCode);
            for (const [key, value] of Object.entries(proxyRes.headers)) {
                if (key.toLowerCase() !== "transfer-encoding") {
                    res.setHeader(key, value);
                }
            }
            proxyRes.pipe(res, {end: true});
        });

        proxyReq.on("error", (err) => {
            console.error("[oauthProxy] error:", err);
            res.status(500).send("Proxy error");
        });

        if (req.method !== "GET" && req.method !== "HEAD") {
            req.pipe(proxyReq, {end: true});
        } else {
            proxyReq.end();
        }
    });