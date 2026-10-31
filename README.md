# 🌾 Intelligent Land Measurement System

An advanced cross-platform Flutter application for intelligent land surveying, GPS boundary mapping, camera AR area estimation, agricultural yield & input planning, and civil engineering material calculation — backed by a live **Node.js/Express + MongoDB Compass** database.

---

## 🚀 Quick Start with MongoDB Compass

### 1. Launch MongoDB Compass
1. Open **MongoDB Compass** on your computer.
2. In the connection string, enter:
   ```
   mongodb://127.0.0.1:27017
   ```
3. Click **Connect**.
4. You will see the database:
   - **Database**: `intelligent_land_measurement`
   - **Collections**:
     - `users`: User profiles, credentials, registrations.
     - `lands`: Saved field boundary coordinates, areas, crop info, and survey records.

---

### 2. Start the Backend API Server
You can start the backend with either option:

- **Option A (Double-Click)**:
  Double-click `start_backend.bat` in the project root.

- **Option B (Terminal / PowerShell)**:
  ```powershell
  node server.js
  ```

The server will display:
```
🚀 Server is listening on http://0.0.0.0:5000
   - Localhost (Desktop/Web): http://127.0.0.1:5000
   - Android Emulator:        http://10.0.2.2:5000
   - Physical Device / Wi-Fi: http://192.168.1.4:5000
====================================================
✅ Connected to MongoDB successfully!
📡 Database URI: mongodb://127.0.0.1:27017/intelligent_land_measurement
📂 Open MongoDB Compass and connect to mongodb://127.0.0.1:27017
📁 Database: "intelligent_land_measurement"
====================================================
```

---

### 3. Run the Flutter App

#### On Connected Physical Device (e.g. Android Device):
To allow your physical phone to talk to the local MongoDB server via USB:
```powershell
adb reverse tcp:5000 tcp:5000
flutter run
```
*(Or connect your phone to the same Wi-Fi network as your PC and the app will automatically reach your computer's local IP!)*

#### On Android Emulator:
```powershell
flutter run
```

---

## 🌟 App Modules & Features

1. **GPS Land Survey Mode** (`lib/screens/gps_measurement_page.dart`):
   - Interactive OpenStreetMap layer with live GPS pin placement.
   - Geodesic Shoelace formula for accurate polygonal land area computation.
   - One-tap saving directly into **MongoDB Compass** & local cache.

2. **Camera AR Measurement** (`lib/screens/ar_measurement_page.dart`):
   - Real-world photo calibration using a known reference object (ruler, tile, card).
   - Draggable calibration pins with real-time area calculation in $m^2$, $cm^2$, $ft^2$.
   - Save photo measurement records straight to MongoDB Compass.

3. **Manual Area Calculator** (`lib/screens/land_measurement.dart`):
   - Instant calculation for standard rectangular plots with multi-unit conversion (Meters, Feet, Yards, Acres, Hectares).
   - Direct save into MongoDB Compass.

4. **Agricultural Planning & Inputs** (`lib/screens/agriculture_page.dart`):
   - Estimates seed requirements, fertilizer (N-P-K) dosage, and water/irrigation savings.
   - Links directly to your saved plots in MongoDB Compass.

5. **Civil Engineering Tools** (`lib/screens/civil_engineering_page.dart`):
   - RCC slab concrete volume, cement bags, sand, aggregate, and cost estimation.

6. **My Saved Fields** (`lib/screens/my_fields_page.dart`):
   - Live synchronization with MongoDB Compass.
   - Search by field name or crop.
   - Detailed inspection with agricultural action buttons.

---

## 🛠️ Architecture & Services

- **`lib/services/api_service.dart`**: Unified HTTP client featuring automatic host detection (`10.0.2.2`, `127.0.0.1`, LAN IP) and live health diagnostics.
- **`lib/services/auth_service.dart`**: Persistent session manager for the authenticated user.
- **`lib/screens/field_storage.dart`**: High-speed hybrid storage engine (combines instantaneous offline SharedPreferences caching with automatic background synchronization to MongoDB Compass).
