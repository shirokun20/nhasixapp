# Business Requirements Document (BRD)
## License Management System (Simple Web API & Frontend)

### 1. Overview
The goal is to build a simple, lightweight Web API and Frontend Dashboard to manage "Premium" access for the mobile application. The system will issue license keys (Windows-style) and enforce device limits per license.

### 2. Core Concepts
-   **License Key**: A unique string (e.g., `NHASIX-AB12-CD34-EF56`) that grants premium access.
-   **Device Locking**: Each license can be used on a maximum of **3 devices** (configurable).
-   **Validation**: The mobile app calls the API to validate the key and register the device.

### 3. Functional Requirements

#### 3.1. Admin Panel (Frontend)
A simple web dashboard for the administrator.
-   **Login**: Secure access for the admin.
-   **Dashboard Overview**:
    -   Total Licenses.
    -   Active Licenses.
    -   Total Registered Devices.
-   **License Management**:
    -   **Generate License**: Create a new license key (or bulk generate).
    -   **List Licenses**: Show key, status (Active/Suspended), creation date, Device Count (e.g., 2/3).
    -   **License Detail**: Show connected devices (Device ID, Device Name, Last Active).
    -   **Revoke/Suspend**: Manually block a license.
    -   **Reset Devices**: Clear all devices linked to a license (to allow user to switch devices).

#### 3.2. Public API (Backend)
Restful API endpoints for the mobile application.

-   **`POST /api/v1/license/validate`**
    -   **Input**: `{ "license_key": "...", "device_id": "...", "device_name": "..." }`
    -   **Logic**:
        1.  Check if Key exists and is Active.
        2.  Check if `device_id` is already linked.
            -   (Yes) -> Return **Success** (Valid).
            -   (No) -> Check `current_device_count < max_devices`.
                -   (Yes) -> Link Device -> Return **Success** (Valid).
                -   (No) -> Return **Error** ("Device limit reached for this license").
    -   **Response**: `{ "valid": true, "message": "Premium Active" }` or `{ "valid": false, "error": "Reason" }`

### 4. Technical Specifications (Proposed)

#### 4.1. Technology Stack
-   **Backend**: Laravel (PHP) or Node.js (Express) - *Assumed standard web stack*.
-   **Database**: MySQL or SQLite (for simplicity).
-   **Frontend**: Blade Templates (if Laravel) or Simple React/HTML Interface.

#### 4.2. Database Schema

**Table: `licenses`**
| Column | Type | Description |
| :--- | :--- | :--- |
| `id` | INT (PK) | |
| `key` | VARCHAR | Unique License Key (Indexed) |
| `status` | ENUM | `active`, `suspended`, `banned` |
| `max_devices` | INT | Default: 3 |
| `created_at` | TIMESTAMP | |

**Table: `license_devices`**
| Column | Type | Description |
| :--- | :--- | :--- |
| `id` | INT (PK) | |
| `license_id` | INT (FK) | Relation to `licenses` |
| `device_id` | VARCHAR | Unique Hardware ID from App |
| `device_name` | VARCHAR | e.g., "Samsung S23" |
| `last_seen` | TIMESTAMP | Last validation call |

### 5. Future Roadmap
-   Self-service portal for users to reset their own devices.
-   Expiration dates for licenses (Subscription model).
