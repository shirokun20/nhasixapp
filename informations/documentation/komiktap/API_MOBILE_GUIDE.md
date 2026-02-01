# Mobile App API Guide

This document outlines the available API endpoints for the Komiktap mobile application.

**Base URL**: `https://your-domain.com/api`

## 1. System Configuration
### Get App Config
Retrieves dynamic application configuration (feature flags, ad settings, pricing settings, etc.).
- **Endpoint**: `GET /config`
- **Auth**: Public or Optional Bearer Token
- **Response**: JSON (Configuration object with pricing settings)

---

## 2. User Profile
### Get Current User
Retrieves the currently authenticated user's profile.
- **Endpoint**: `GET /user`
- **Auth**: **Required** (Bearer Token)
- **Response (Success)**:
  ```json
  {
    "app": "Kuron",
    "version": "1.0.0",
    "status": "success",
    "data": {
      "id": 1,
      "name": "John Doe",
      "email": "john@example.com",
      "created_at": "2026-01-01T00:00:00.000000Z",
      "updated_at": "2026-01-01T00:00:00.000000Z"
    }
  }
  ```

---

## 3. Plans & Payments

### Get Available Plans
Retrieves available subscription plans.
- **Endpoint**: `GET /plans`
- **Response**: List of active plans

### Get FAQs
Retrieves Frequently Asked Questions.
- **Endpoint**: `GET /faqs`
- **Response**: List of FAQ items

### Get Payment Methods
Retrieves active payment gateways/methods.
- **Endpoint**: `GET /payment-methods`
- **Query Parameters** (Optional):
  - `type`: Filter by usage type (`all`, `order`, `donation`). Default: `all`
- **Response**:
  ```json
  {
    "app": "Kuron",
    "version": "1.0.0",
    "status": "success",
    "data": {
      "is_enabled": true,
      "payment_methods": [
        {
          "name": "QRIS",
          "account_number": "08123456789",
          "account_holder": "John Doe",
          "instructions": "<p>Scan QR code and complete payment</p>",
          "usage_type": "all"
        }
      ]
    }
  }
  ```
  **Note**: The `instructions` field is rendered as HTML from markdown.

### Check Voucher Code
Validates a voucher code and calculates the discount amount.
- **Endpoint**: `POST /check-voucher`
- **Request Body**:
  ```json
  {
    "voucher_code": "SAVE20",
    "amount": 100000
  }
  ```
- **Response (Success)**:
  ```json
  {
    "app": "Kuron",
    "version": "1.0.0",
    "status": "success",
    "data": {
      "valid": true,
      "code": "SAVE20",
      "discount_amount": 20000,
      "final_amount": 80000,
      "message": "Hemat IDR 20,000"
    }
  }
  ```
- **Response (Invalid/Expired)**:
  ```json
  {
    "app": "Kuron",
    "version": "1.0.0",
    "status": "failed",
    "message": "Kode voucher tidak valid, kadaluarsa, atau sudah habis."
  }
  ```

### Checkout / Purchase
Initiates a transaction for a plan or donation.
- **Endpoint**: `POST /checkout`
- **Request Body**:
  ```json
  {
    "plan_name": "Premium",
    "device_quota": 3,
    "duration_months": 6,
    "customer_contact": "08123456789",
    "proof_digits": "12345",
    "payment_method": "QRIS",
    "voucher_code": "SAVE20",
    "amount": 100000
  }
  ```
  **Field Descriptions**:
  - `plan_name` (required): Name of the plan (e.g., "Starter", "Premium", "Sultan", "Ketengan", "Donasi", or campaign title)
  - `device_quota` (required): Number of devices (integer, min: 1)
  - `duration_months` (required): Subscription duration in months (integer, min: 1)
  - `customer_contact` (required): Customer phone number or contact
  - `proof_digits` (required): Last 5 digits of payment proof (max: 5 characters)
  - `payment_method` (required): Selected payment method name
  - `voucher_code` (optional): Voucher code for discount
  - `amount` (nullable): Required for donations, calculated server-side for plans

- **Response (Success)**:
  ```json
  {
    "app": "Kuron",
    "version": "1.0.0",
    "status": "success",
    "data": {
       "transaction_id": 105,
       "transaction_code": "TRX-2026-XXX",
       "message": "Order received successfully! Voucher applied: Save IDR 20,000"
    }
  }
  ```

---

## 4. Licensing

### Check License Validity
Verifies if a license key is valid and active, and registers the device.
- **Endpoint**: `POST /check-license`
- **Request Body**:
  ```json
  {
    "license_key": "XXXX-XXXX-XXXX-XXXX",
    "device_id": "unique-device-id",
    "device_name": "Samsung Galaxy S24"
  }
  ```
  **Field Descriptions**:
  - `license_key` (required): The license key to validate
  - `device_id` (required): Unique device identifier
  - `device_name` (optional): Human-readable device name

- **Response (Success)**:
  ```json
  {
    "app": "Kuron",
    "version": "1.0.0",
    "status": "success",
    "data": {
      "valid": true,
      "expires_at": "2026-12-31 23:59:59",
      "max_devices": 3,
      "used_devices": 2,
      "message": "License active"
    }
  }
  ```

- **Response (Invalid License)**:
  ```json
  {
    "app": "Kuron",
    "version": "1.0.0",
    "status": "failed",
    "message": "Invalid license key"
  }
  ```

- **Response (Max Devices Reached)**:
  ```json
  {
    "app": "Kuron",
    "version": "1.0.0",
    "status": "failed",
    "message": "Max devices reached (3)"
  }
  ```

---

## 5. Error Reporting
Submits a crash report or error log from the mobile application.

### Submit Error Report
- **Endpoint**: `POST /error-report`
- **Auth**: Optional Bearer Token (if user is logged in, report will be linked to user)
- **Content-Type**: `application/json`

#### Request Body
| Field | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| `error_message` | string | **Yes** | Short description of the error |
| `stack_trace` | string | No | Full stack trace or detailed log |
| `device_info` | string | No | Device model, OS version (e.g., "Samsung S24, Android 14") |
| `app_version` | string | No | App version code (e.g., "1.2.0") |

#### Example Request
```json
{
  "error_message": "NullPointerException in MainActivity",
  "stack_trace": "java.lang.NullPointerException: Attempt to invoke virtual method on a null object reference\n\tat com.komiktap.app.MainActivity.onCreate(MainActivity.kt:42)",
  "device_info": "Pixel 7 Pro, Android 14",
  "app_version": "1.0.5"
}
```

#### Example Response (Success - 201 Created)
```json
{
  "app": "Kuron",
  "version": "1.0.0",
  "status": "success",
  "data": {
    "message": "Error report submitted successfully",
    "report_id": 15
  }
}
```

#### Example Response (Validation Error - 422 Unprocessable Entity)
```json
{
  "app": "Kuron",
  "version": "1.0.0",
  "status": "failed",
  "message": "Validation error",
  "data": {
    "error_message": [
      "The error message field is required."
    ]
  }
}
```
