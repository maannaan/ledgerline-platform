import http from "k6/http";
import { check } from "k6";

const BASE_URL = __ENV.BASE_URL;
const TENANTS = __ENV.TENANTS.split(",").map((t) => {
  const [id, key] = t.split(":");
  return { id, key };
});

const scenarios = {
  steady: {
    executor: "constant-arrival-rate",
    rate: Number(__ENV.RATE || 200),
    timeUnit: "1s",
    duration: "10m",
    preAllocatedVUs: 100,
    maxVUs: 400,
    exec: "steady",
  },
};

if (__ENV.NOISY === "1") {
  scenarios.noisy = {
    executor: "constant-vus",
    vus: 20,
    duration: "10m",
    exec: "noisy",
  };
}

export const options = {
  scenarios,
  thresholds: {
    "http_req_duration{endpoint:records}": ["p(95)<300"],
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
    tags: { endpoint: "records" },
  };
  if (Math.random() < 0.3) {
    const body = JSON.stringify({
      amount: Math.random() * 500,
      sku: "SKU-LOAD",
    });
    const res = http.post(`${BASE_URL}/records`, body, params);
    check(res, { created: (r) => r.status === 200 || r.status === 201 });
  } else {
    const res = http.get(`${BASE_URL}/records?search=SKU-1`, params);
    check(res, { listed: (r) => r.status === 200 });
  }
}

export function noisy() {
  const params = {
    headers: headersFor("cobalt", __ENV.NOISY_KEY),
    tags: { endpoint: "heavy" },
  };
  http.get(`${BASE_URL}/reports/heavy`, params);
}
