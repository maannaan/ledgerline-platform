import http from "k6/http";
import { check } from "k6";

const BASE_URL = __ENV.BASE_URL;
if (!BASE_URL) {
  throw new Error("BASE_URL is required");
}
if (!__ENV.TENANTS) {
  throw new Error("TENANTS is required (tenant:key,tenant:key,...)");
}

const TENANTS = __ENV.TENANTS.split(",").map((t) => {
  const idx = t.indexOf(":");
  if (idx < 1) {
    throw new Error(`Bad TENANTS entry: ${t}`);
  }
  return { id: t.slice(0, idx), key: t.slice(idx + 1) };
});

const duration = __ENV.DURATION || "10m";
const rate = Number(__ENV.RATE || 200);

const scenarios = {
  steady: {
    executor: "constant-arrival-rate",
    rate,
    timeUnit: "1s",
    duration,
    preAllocatedVUs: Number(__ENV.PRE_VUS || 50),
    maxVUs: Number(__ENV.MAX_VUS || 400),
    exec: "steady",
  },
};

if (__ENV.NOISY === "1") {
  if (!__ENV.NOISY_KEY) {
    throw new Error("NOISY=1 requires NOISY_KEY (cobalt bearer key)");
  }
  scenarios.noisy = {
    executor: "constant-vus",
    vus: Number(__ENV.NOISY_VUS || 10),
    duration,
    exec: "noisy",
  };
}

export const options = {
  scenarios,
  thresholds: {
    "http_req_duration{endpoint:records}": [`p(95)<${__ENV.P95_MS || 300}`],
    "http_req_failed{endpoint:records}": ["rate<0.01"],
  },
};

function headersFor(id, key) {
  return {
    "Content-Type": "application/json",
    "X-Tenant-Id": id,
    Authorization: `Bearer ${key}`,
  };
}

export function steady() {
  const t = TENANTS[Math.floor(Math.random() * TENANTS.length)];
  const params = {
    headers: headersFor(t.id, t.key),
    tags: { endpoint: "records", tenant: t.id },
  };
  // Mix: mostly cheap tenant-scoped list; occasional write; rare ILIKE search.
  // Full-scan search under 200 RPS saturates t4g.micro — keep it minority traffic.
  const r = Math.random();
  if (r < 0.15) {
    const body = JSON.stringify({
      amount: Math.random() * 500,
      sku: "SKU-LOAD",
    });
    const res = http.post(`${BASE_URL}/records`, body, params);
    check(res, { created: (r) => r.status === 200 || r.status === 201 });
  } else if (r < 0.2) {
    const res = http.get(`${BASE_URL}/records?search=SKU&limit=20`, params);
    check(res, { listed: (r) => r.status === 200 });
  } else {
    const res = http.get(`${BASE_URL}/records?limit=50`, params);
    check(res, { listed: (r) => r.status === 200 });
  }
}

export function noisy() {
  const params = {
    headers: headersFor("cobalt", __ENV.NOISY_KEY),
    tags: { endpoint: "heavy", tenant: "cobalt" },
  };
  const res = http.get(`${BASE_URL}/reports/heavy`, params);
  check(res, {
    heavy_ok_or_limited: (r) =>
      r.status === 200 || r.status === 429 || r.status === 504,
  });
}
