# 🚀 Waychaser

**Waychaser** is a live GPS tracking application built to monitor the movement and activity of bank collection officers and sales personnel. It helps managers and team leads keep track of employee travel routes, monitor app usage, and estimate fuel costs based on travel data.

---

## 📱 Overview

Waychaser is designed for field force teams in financial institutions, offering:

- 🔄 **Live location tracking** (foreground & background)
- 📈 **Route mapping** of daily activities
- 🛢 **Petrol cost estimation** based on movement
- 🔍 **App usage tracking** for employee monitoring
- 📶 **Offline data capture and sync** to avoid data loss
- 🗺 **Hierarchy-based map views** for team leads and managers

---

## 🧠 Features

- 🛰️ **High-Accuracy Location Tracking**
  - Uses **Fused Location Provider** and **GPS**
  - Tracks even when the app is in the background (via `background_locator_2`)
  - Location updates every **5 seconds**

- 🗃 **Offline Persistence**
  - Location data is saved in **SQLite** when the device is offline
  - Automatically syncs to the server once back online

- 🔋 **Device Information Collection**
  - Battery status
  - Network type
  - SIM and carrier info
  - Device model and OS

- 🔐 **Authentication**
  - Uses **Firebase Authentication** for secure login

- 🧭 **Manager Portal**
  - View real-time and historic tracking of subordinates
  - Monitor **app usage events** for each employee (using Android usage stats)

---

## 🛠 Tech Stack

| Layer        | Technology              |
|--------------|--------------------------|
| Frontend     | Flutter                  |
| Background Tracking | `background_locator_2`, FusedLocationProvider |
| Backend      | Node.js + Express        |
| ORM          | Sequelize                |
| Database     | MySQL                    |
| Authentication | Firebase (email/password or custom token) |
| Local Storage | SQLite (offline queueing) |

---
