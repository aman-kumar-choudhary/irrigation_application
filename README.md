# JalDrishti Android

Flutter Android client for the JalDrishti irrigation dashboard.

## Docker Backend For Android

The Android app uses the same Dockerized FastAPI and GeoServer services as the
web platform:

- FastAPI: `/api/history`, `/api/point`, `/api/boundary`, `/api/chat`, and graph
  endpoints on port `8000`
- GeoServer WMS: workspace `irrigation` on port `8080`
- Open-Meteo is called directly from the device for weather data

Run against an Android emulator with the default host mapping:

```sh
flutter run
```

Run against a physical Android phone by passing the Docker host machine's LAN IP:

```sh
flutter run --dart-define=BACKEND_HOST=192.168.x.x
```

Optional overrides are available when ports or scheme differ:

```sh
flutter run \
  --dart-define=BACKEND_HOST=192.168.x.x \
  --dart-define=API_PORT=8000 \
  --dart-define=GEOSERVER_PORT=8080 \
  --dart-define=BACKEND_SCHEME=http
```

Backend requirements for Android clients:

- Docker ports `8000` and `8080` must be reachable from the device network.
- FastAPI must keep CORS enabled for mobile/web clients.
- Android cleartext HTTP is enabled in `AndroidManifest.xml`; switch to HTTPS
  and `BACKEND_SCHEME=https` for production.
- The `/api/history` response should include `slots[].date`, `slots[].slot`,
  `slots[].season`, and `slots[].obs_means` so the mobile calendar can mirror
  the web Sentinel imagery dates exactly.
