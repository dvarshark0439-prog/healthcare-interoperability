# Medifix

Medifix is a Flutter healthcare interoperability app built from the project requirements in the provided presentation.

It includes:

- Secure patient login and registration
- Centralized patient dashboard
- Aggregated medical records from hospitals, clinics, labs, and pharmacies
- Health trends and chart-based visualization
- Interoperability controls with consent-based sync
- Audit logging and security-focused patient access views
- Persistent local storage for users, patients, and record edits
- Doctor console for adding patients and editing medical records
- Doctor controls for deleting patients
- Record image attachments for scans such as MRI images, X-rays, and other medical photos
- Patient nearby-hospital map with sharing controls
- Hospital portal for sharing hospital records into patient charts
- Patient personal-details editor with emergency contacts
- Doctor and hospital self-service registration
- Hospital doctor management with patient assignment views
- Hospital realtime data transfer with live packet delivery

## Demo Login

- Email: `akash123@gmail.com`
- Password: `Pass@123`

## Doctor Login

- Email: `dr.luffy@medibridge.app`
- Password: `Doctor@123`

## Hospital Login

- Email: `records@greenvalleyhospital.com`
- Password: `Hospital@123`

## Google Maps Setup

Real Google Maps support has been added for the patient nearby-hospitals view.

Replace `YOUR_GOOGLE_MAPS_API_KEY` in:

- [android/app/src/main/AndroidManifest.xml](/Users/akash/Desktop/codexxx/android/app/src/main/AndroidManifest.xml)
- [ios/Runner/AppDelegate.swift](/Users/akash/Desktop/codexxx/ios/Runner/AppDelegate.swift)
- [web/index.html](/Users/akash/Desktop/codexxx/web/index.html)

Without a valid Google Maps API key, the map feature will not work correctly on those platforms.

## Persistence

User accounts, doctor-added patients, and edited medical records are now saved locally on the device using app storage, so they remain available after restarting the app.

Patients created by the doctor console receive the default password:

- Password: `Pass@123`

## New Doctor Actions

- Add patient
- Edit patient medical records
- Delete patients from local storage
- Upload image attachments to records such as MRI scans, X-rays, and photos
- Register new doctor accounts

## Patient Network Page

The patient hospitals section now shows:

- Connected providers in plain language
- Sharing on/off for each provider
- Last refresh time
- Hospitals and providers last visited/updated
- Nearby hospitals on Google Maps
- One-tap data sharing to selected hospitals

## Patient Profile

Patients can now:

- Edit personal details
- Update phone and address
- Maintain multiple emergency contacts

## Hospital Portal

Hospital accounts can now:

- Share patient data and records
- Upload reports and scans into patient charts
- Add new doctors inside the portal
- Assign patients to hospital doctors
- View the patients their doctors are treating

## Run

```bash
flutter run
```

## Verify

```bash
flutter analyze
flutter test
```
