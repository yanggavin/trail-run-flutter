# TrailRun — Mobile App Requirements Spec (Flutter • iOS & Android)

**Version:** 1.0 • **Date:** 2025-09-16  
**Audience:** Product, Flutter engineers, QA, DevOps, Design  
**Source:** Internal “TrailRun Requirements Retrospective & Future Requirements” document

---

## 1) Product Overview
TrailRun is a mobile app for trail runners to **track runs**, **capture geo‑tagged photos**, and **generate rich activity summaries** (route + stats + photos), with **offline‑first** reliability, **secure storage**, and **privacy by default**.

**Primary Personas**
- **Everyday Trail Runner:** reliable GPS, low battery use, easy summaries/sharing.  
- **Power User:** accuracy, analytics, export, device/sensor integrations (future).  
- **Coach/Organizer (future):** team oversight & structured training.

---

## 2) Scope

### In‑Scope (v1.0)
1. **GPS tracking**: start/stop, pause/resume, background tracking, auto‑pause, accuracy control.  
2. **Photo capture** during an activity with **EXIF geotagging** and fast return to tracking.  
3. **Activity summary**: stats (distance/duration/pace/elevation), map polyline, photo markers, splits, elevation chart.  
4. **Offline‑first & Sync**: full functionality offline; local encrypted DB; automatic cloud sync & conflict handling.  
5. **History**: activity list with pagination, search, filters, sort; detail view; delete; share.  
6. **Battery & permissions**: optimized sampling; clear permission UX; crash/state recovery.  
7. **Security & privacy**: encrypted local storage, TLS in transit, privacy‑by‑default, EXIF stripping option.  
8. **GPS signal robustness**: filtering, gap interpolation, outlier detection, Kalman smoothing.  
9. **Sharing & export**: privacy‑respecting share cards; export GPX; native sharesheet.  
10. **Cross‑platform consistency** across iOS & Android.

### Out‑of‑Scope (v1.0; planned 2.x)
- Wearables (Apple Watch / Wear OS companion), external sensors (HR/foot pods).  
- Advanced analytics, social/community, training plans, route planning & navigation, coach tools, expanded export formats & APIs, environmental/safety alerts.

---

## 3) Platform & Technical Targets

### Flutter Targets
- **Flutter:** Stable channel (LTS where available)  
- **iOS:** iOS 15+ (background location enabled)  
- **Android:** Android 8.0 (API 26)+ (foreground service for location)

### Non‑Functional Targets (v1.0)
- **Startup:** ≤ **2.5s** to tracking screen ready (P50 mid‑tier device).  
- **CPU:** < **10%** during steady‑state tracking (screen on).  
- **Battery:** **4–6%/hour** while tracking with screen periodically on.  
- **Photo flow:** return to tracking screen in **< 400ms** after capture (P95 < 700ms).  
- **Background reliability:** continuous tracking while backgrounded.  
- **Map perf:** smooth pan/zoom for long routes (≈ 30k+ points) without jank.  
- **Security:** AES‑256 at rest (encrypted DB), TLS 1.2+ in transit, secure token storage.  
- **Privacy:** activities private by default; EXIF stripping toggle.  
- **Accessibility:** supports platform screen readers & text scaling; high‑contrast mode.

---

## 4) User Stories & Acceptance Criteria (v1.0)

### 4.1 GPS Tracking
- **US‑T1**: As a runner, I can **Start / Pause / Resume / Stop** a run.  
  **AC:** Controls visible; state persists through lifecycle transitions.  
- **US‑T2**: The app records my route at **1–5s intervals** with **adaptive sampling**.  
  **AC:** Interval adapts to movement & battery; accuracy indicator visible.  
- **US‑T3**: **Auto‑pause** when stopped; resume on movement.  
  **AC:** Thresholds configurable; no phantom distance while idle.  
- **US‑T4**: **Background tracking** is reliable.  
  **AC:** iOS background modes & Android foreground service active; no gaps beyond OS throttling; session survives process death and recovers.  
- **US‑T5**: **GPS quality warnings** when accuracy degrades.  
  **AC:** UI toast/banner with actionable tips (wait, move to open sky).

### 4.2 Photo Capture with Geotagging
- **US‑P1**: Capture photos from the tracking screen.  
  **AC:** Launch camera and **return < 400ms**; photo linked to active session.  
- **US‑P2**: Photo stores **GPS location & timestamp**; optional **EXIF stripping** on export/share.  
  **AC:** EXIF present in local vault; stripped if user chooses privacy mode.

### 4.3 Activity Summary
- **US‑S1**: Post‑run **summary** shows distance, duration, avg pace, elevation gain/loss.  
- **US‑S2**: **Interactive map** with route polyline & **photo markers**.  
- **US‑S3**: **Per‑km splits** & **elevation chart**.  
- **US‑S4**: **Edit** title/notes/privacy; choose **cover photo**.  
- **US‑S5**: **Share card** (map + key stats + photos collage) via native sharesheet.  
  **AC:** Sharing respects privacy; no precise coordinates if disabled.

### 4.4 Offline & Sync
- **US‑O1**: Full **offline tracking & photo capture**.  
- **US‑O2**: **Encrypted local DB** stores all data; works with zero network.  
- **US‑O3**: **Automatic sync** when online with exponential backoff & retries; **conflict policy: server‑wins** with local preservation of unsent deltas.  
- **US‑O4**: **Backup/restore** on new device via account sign‑in.

### 4.5 History & Management
- **US‑H1**: **Activity list** with pagination, rich preview card (cover, stats).  
- **US‑H2**: **Search & filters** (date range, distance, text); sort (date/duration/pace).  
- **US‑H3**: Pull‑to‑refresh; delete with confirm; share from list.

### 4.6 Battery, Permissions, Resilience
- **US‑B1**: Battery usage within **4–6%/hour** while tracking.  
- **US‑B2**: Permission prompts are clear; graceful degradation if denied.  
- **US‑B3**: **Crash/state recovery** restores an in‑progress session on next launch.

### 4.7 Security & Privacy
- **US‑SP1**: **AES‑256 encrypted** local DB; **Keychain/Keystore** for secrets.  
- **US‑SP2**: **TLS 1.2+** for sync; **certificate pinning**.  
- **US‑SP3**: **Privacy‑by‑default**; explicit user action to share or make public.  
- **US‑SP4**: **Data deletion/export** complies with GDPR (delete my data, export my data).

### 4.8 GPS Robustness
- **US‑G1**: **Outlier filtering** (impossible jumps) & **Kalman smoothing**.  
- **US‑G2**: **Gap interpolation** when brief signal loss occurs.  
- **US‑G3**: Internal **confidence score** shown as an indicator.

### 4.9 Export & Sharing
- **US‑E1**: **Export GPX**; include photos as optional bundle (zipped with JSON metadata).  
- **US‑E2**: Native share of **image summaries**.

### 4.10 Cross‑Platform Consistency
- **US‑X1**: Feature parity & consistent UX patterns adapted to platform norms.  
- **US‑X2**: Performance parity on mid‑tier devices.

---

## 5) System Architecture (High‑Level)

### 5.1 App Layers
- **Presentation:** Flutter (Material 3), responsive layout, accessibility aware.  
- **State mgmt:** Riverpod or BLoC (choose one; assumption: Riverpod).  
- **Domain:** Activities, Photos, TrackPoints, Splits, ElevationProfile, Settings, SyncQueue.  
- **Data:** Repositories over local DB (Drift or sqflite_sqlcipher) + Sync API client (Dio).

### 5.2 Location Pipeline
Foreground/background location stream → **Accuracy gate + Kalman filter + outlier reject** → adaptive sampler (1–5s) → persist TrackPoint batch (write‑behind) → live stats (pace, distance, elevation).

### 5.3 Persistence (Encrypted SQLite)
- `activities (id, start_ts, end_ts, distance_m, duration_s, elev_gain_m, avg_pace_s_per_km, privacy, title, notes, cover_photo_id, sync_state, created_at, updated_at)`  
- `track_points (id, activity_id, ts, lat, lon, elev_m, acc_m, source, seq)`  
- `photos (id, activity_id, ts, lat, lon, file_path, thumb_path, exif_present, curated_score)`  
- `splits (id, activity_id, km_index, pace_s, elev_gain_m)`  
- `settings (...)`  
- `sync_queue (id, entity_type, entity_id, op, payload, retry_count, last_error)`

### 5.4 Sync
- **Auth:** token‑based, stored in Keychain/Keystore.  
- **Transport:** HTTPS with cert pinning.  
- **Strategy:** queue‑based, incremental; **server‑wins** conflict resolution; exponential backoff.

### 5.5 Media
Photos stored in **app private storage**; on export/share generate derived assets (thumbnails, share cards).

### 5.6 Maps
Provider‑agnostic (e.g., **flutter_map** with vector tiles, or Mapbox SDK).  
Must support **interactive polyline**, **photo markers**, **offline tile packs** (2.x).

---

## 6) Permissions & OS‑Specific Requirements

### iOS
- **Info.plist**: `NSLocationWhenInUseUsageDescription`, `NSLocationAlwaysAndWhenInUseUsageDescription`, `NSCameraUsageDescription`, `NSPhotoLibraryAddUsageDescription`.  
- **Background Modes**: Location updates, audio (if using voice cues), background fetch.  
- **Precise Location** prompt handling; fallback if reduced precision.

### Android
- **Manifest**: `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, `ACCESS_BACKGROUND_LOCATION`, `FOREGROUND_SERVICE`, `CAMERA`, `WRITE_EXTERNAL_STORAGE` (scoped storage aware).  
- **Foreground Service** for tracking; notification channel with live stats.

---

## 7) Analytics, Logging, Observability
- **Privacy‑first analytics** (opt‑in): session counts, crash reports, performance (battery/CPU), feature adoption.  
- **In‑app diagnostics screen**: GPS accuracy, last points, DB queue size.  
- **Redaction** of PII and precise coordinates in analytics when privacy mode is on.

---

## 8) Acceptance Test Plan (v1.0)

1. **Tracking Reliability Matrix**  
   Scenarios: screen off, app backgrounded, process kill, phone reboot during run (resume flow).  
   **Pass:** recorded distance loss ≤ **2%** vs control device on open‑sky loop.

2. **Battery Bench**  
   2‑hour tracked session, typical use (≈3 photos/10min, occasional screen ons).  
   **Pass:** consumption ≤ **12%**.

3. **Photo Flow**  
   Tracking → camera → back to tracking.  
   **Pass:** P95 return < **700ms**; photos linked to correct activity with lat/long.

4. **Map & Summary**  
   Route with **30k points + 50 photos** renders smoothly; no sustained dropped frames.

5. **Offline & Sync**  
   Airplane mode run + photos; reconnect; all entities sync within **2 minutes** with retries; conflicts resolved (server‑wins) with no data loss.

6. **Security & Privacy**  
   DB unreadable without app (sqlcipher).  
   **Privacy mode share:** contains no precise GPS coordinates nor EXIF.

7. **Search/Filter**  
   Large history (≈1k activities): search & filters respond **< 250ms**.

---

## 9) Release Plan

### v1.0 (MVP, production)
All **In‑Scope** features above.  
**KPIs:** App rating ≥ **4.7**; GPS satisfaction > **95%**; battery **4–6%/hour**.

### v1.1 (Hardening/Quality)
Map perf polish; device‑specific battery & GPS tuning; export options (CSV).

### v2.x Backlog (Prioritized)
1. **Enhanced UX & Accessibility** (onboarding, voice cues, 200% text scale, high contrast).  
2. **Advanced Analytics** (trends, PRs, pace zones, training load, predictions).  
3. **Wearables & Sensors** (watch app, HR/foot pod, haptics, low‑power watch‑only mode).  
4. **Social/Community** (profiles, follows, feeds, shared routes, challenges, badges).  
5. **Training Plans** (intervals with audio targets, adaptive plans, workout analysis).  
6. **Route Planning & Navigation** (turn‑by‑turn, offline topo/satellite, breadcrumb return, SOS).  
7. **AI Assistance** (photo curation/tags, intelligent summaries, risk detection, weather‑based tips).  
8. **Coach/Enterprise** (coach dashboard, plan assignment, team analytics).  
9. **Data & Integrations** (TCX/FIT/CSV/JSON, Strava/Garmin/TrainingPeaks, webhooks/APIs).  
10. **Environment & Safety** (trail conditions, weather alerts, wildlife reports, sunrise/sunset).

---

## 10) Dependencies & Implementation Notes
- **State mgmt:** Riverpod (simple, testable) or BLoC (team preference).  
- **Location:** robust background location with iOS/Android parity; validate on real OEMs.  
- **Storage:** Drift or sqflite_sqlcipher; WAL mode and batched writes for power efficiency.  
- **Networking:** Dio + interceptors (retry, pinning).  
- **Maps:** flutter_map (vector tiles) or Mapbox; plan offline tile packs (2.x).  
- **Charts:** fl_chart for elevation/splits.  
- **Media:** camera + image processing in isolates; generate thumbnails at import.

---

## 11) Risks & Mitigations
- **OEM background limits (Android):** foreground service + user education; test on Samsung/Xiaomi/Oppo.  
- **iOS background throttling:** enable proper modes, keep energy footprint low.  
- **Battery variability:** adaptive sampling + heuristics; device‑specific tuning.  
- **Map SDK changes/licensing:** provider‑agnostic abstraction.

---

## 12) Open Questions (pre‑dev freeze)
1. Which **map provider** & licensing? Offline tile strategy?  
2. **Auth**/account system & backend endpoints.  
3. Exact **privacy defaults** (e.g., location precision on share).  
4. **Design language** details (iconography, typography scale, dark mode rules).  
5. **Analytics vendor** & opt‑in flow.

---

### Traceability (v1.0)
- Requirements map to items enumerated in the internal retrospective and roadmap; v2.x backlog corresponds to UX/Accessibility, Analytics, Social, Training, Wearables, AI, Routes, Enterprise, Data, and Safety initiatives.
