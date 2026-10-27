export interface DirectionsRoute {
  durationSeconds: number;
  distanceMeters: number;
  encodedPolyline: string;
  summary: string;
}

interface DirectionsResponse {
  routes: Array<{
    summary: string;
    legs: Array<{
      duration: { value: number };
      distance: { value: number };
    }>;
    overview_polyline: { points: string };
  }>;
  status: string;
}

export async function fetchGoogleDirections(
  originLat: number,
  originLng: number,
  destLat: number,
  destLng: number,
): Promise<DirectionsRoute[]> {
  const rawKey = (process.env.GOOGLE_MAPS_API_KEY ?? process.env.DIRECTIONS_API_KEY ?? "").trim();
  const apiKey = !rawKey || rawKey.startsWith("PASTE_YOUR_") || rawKey.startsWith("YOUR_") ? "" : rawKey;
  if (!apiKey) {
    return [];
  }

  const uri = new URL("https://maps.googleapis.com/maps/api/directions/json");
  uri.searchParams.set("origin", `${originLat},${originLng}`);
  uri.searchParams.set("destination", `${destLat},${destLng}`);
  uri.searchParams.set("alternatives", "true");
  uri.searchParams.set("mode", "driving");
  uri.searchParams.set("key", apiKey);

  const response = await fetch(uri.toString());
  if (!response.ok) return [];

  const body = (await response.json()) as DirectionsResponse;
  if (body.status !== "OK" || !body.routes?.length) return [];

  return body.routes.map((route) => {
    const leg = route.legs[0];
    return {
      durationSeconds: leg.duration.value,
      distanceMeters: leg.distance.value,
      encodedPolyline: route.overview_polyline.points,
      summary: route.summary ?? "Route",
    };
  });
}

export function buildDemoDirections(
  originLat: number,
  originLng: number,
  destLat: number,
  destLng: number,
): DirectionsRoute[] {
  const midLat = (originLat + destLat) / 2;
  const midLng = (originLng + destLng) / 2;
  const encode = (points: Array<{ lat: number; lng: number }>) => {
    // Minimal polyline: use google encode or stub - use fetch from simple 2-point
    // For demo, use empty and client draws straight line - CF returns polyline from 3 points manually encoded
    return encodeSimplePolyline(points);
  };

  const baseDuration = 18 * 60;
  return [
    {
      durationSeconds: baseDuration,
      distanceMeters: 8200,
      encodedPolyline: encode([
        { lat: originLat, lng: originLng },
        { lat: midLat + 0.004, lng: midLng },
        { lat: destLat, lng: destLng },
      ]),
      summary: "Direct via high-traffic corridor",
    },
    {
      durationSeconds: 20 * 60,
      distanceMeters: 8800,
      encodedPolyline: encode([
        { lat: originLat, lng: originLng },
        { lat: midLat, lng: midLng - 0.006 },
        { lat: destLat, lng: destLng },
      ]),
      summary: "Balanced avenue",
    },
    {
      durationSeconds: 22 * 60,
      distanceMeters: 9500,
      encodedPolyline: encode([
        { lat: originLat, lng: originLng },
        { lat: midLat - 0.003, lng: midLng + 0.008 },
        { lat: destLat, lng: destLng },
      ]),
      summary: "Safer residential loop",
    },
  ];
}

function encodeSimplePolyline(points: Array<{ lat: number; lng: number }>): string {
  let lastLat = 0;
  let lastLng = 0;
  let result = "";

  for (const point of points) {
    const lat = Math.round(point.lat * 1e5);
    const lng = Math.round(point.lng * 1e5);
    result += encodeSigned(lat - lastLat);
    result += encodeSigned(lng - lastLng);
    lastLat = lat;
    lastLng = lng;
  }

  return result;
}

function encodeSigned(value: number): string {
  let s = value < 0 ? ~(value << 1) : value << 1;
  let output = "";
  while (s >= 0x20) {
    output += String.fromCharCode((0x20 | (s & 0x1f)) + 63);
    s >>= 5;
  }
  output += String.fromCharCode(s + 63);
  return output;
}
