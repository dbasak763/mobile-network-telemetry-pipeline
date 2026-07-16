import http from 'k6/http';
import { Counter } from 'k6/metrics';
import { check } from 'k6';

const acceptedEvents = new Counter('accepted_events');
const eventsPerRequest = 100;

export const options = {
  scenarios: {
    ten_thousand_events_per_second: {
      executor: 'constant-arrival-rate',
      rate: 100,
      timeUnit: '1s',
      duration: '2m',
      preAllocatedVUs: 100,
      maxVUs: 500,
    },
  },
  thresholds: {
    accepted_events: ['rate>9900'],
    http_req_failed: ['rate<0.01'],
    http_req_duration: ['p(95)<5000'],
  },
};

function event(index) {
  return {
    'ip-address': `10.0.${Math.floor(index / 255)}.${index % 255}`,
    device_information: {
      device_info: { model: 'load-test', android: '13', hardware: 'k6' },
      location: { latitude: 41.88, longitude: -87.63, altitude: 181, accuracy: 3 },
      timestamp: new Date().toISOString(),
    },
    lte_params: {
      mcc: '310', mnc: '260', band: '48', Fc: 3550.0, EarFcn: 55240,
      TimeAdv: 1, tac: '1', eci: '1', pci: 10, rsrp: -85.0,
      rsrq: -9.0, rssi: -65.0, snr: 20.0, cqi: 12,
    },
  };
}

export default function () {
  const events = Array.from({ length: eventsPerRequest }, (_, i) => event(i));
  const response = http.post(
    `${__ENV.BASE_URL || 'http://localhost:5050'}/data/batch`,
    JSON.stringify(events),
    { headers: { 'Content-Type': 'application/json' } },
  );
  if (check(response, { 'batch accepted': (r) => r.status === 202 })) {
    acceptedEvents.add(eventsPerRequest);
  }
}
