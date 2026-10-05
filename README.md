# Car Tracker

A private-first Android app for tracking fuel usage, maintenance, service reminders, and real ownership costs. I built it for my own car, but anyone who finds it useful is welcome to use it.

> **Android only.** This is a personal sideload build, not a Google Play Store release. All vehicle records stay locally on the device unless you explicitly export or back them up.

## Screenshots

<p align="center">
  <img src="assets/screenshots/fuel-history.png" alt="Fuel history and completed cycle" width="31%" />
  <img src="assets/screenshots/maintenance-history.png" alt="Maintenance history and service reminder" width="31%" />
  <img src="assets/screenshots/analytics.png" alt="Fuel and maintenance analytics" width="31%" />
</p>

## Highlights

- Full-to-full fuel-cycle tracking, including partial fills
- Maintenance records, itemized costs, receipts, and service reminders
- Mileage alerts, date alerts, and calendar integration
- Fuel-efficiency and ownership-cost analytics (Fuel + Service + Repairs)
- Accessories tracked separately in maintenance analytics
- Whole-number odometer input and display; accessory records need no odometer
- Vehicle retirement/history, Excel exports, and full backup/restore

## Download

[**Download the latest Android APK**](https://github.com/Laxman1104/car-tracking-app/releases/latest)

Open the APK on your Android phone and allow installation from that browser or file manager if Android prompts you.

## Version 1.0.2 (build 3)

- Ownership spending and monthly charts count Fuel + Service + Repairs, excluding Accessories.
- Accessories remain visible separately in maintenance analytics and no longer request or contribute odometer readings.
- Odometer inputs and displays use whole numbers. Existing decimal readings remain stored unchanged.
- The Home odometer subtitle uses a smaller single-line font.
- Full-to-full fuel-cycle mathematics are unchanged.

### Updating without losing records

Create a full backup using the app's backup/export feature before updating. Install the new APK over the existing app and choose **Update**; do not uninstall the app or clear its storage.

This release keeps the application ID (`com.laxmanpillai.car_tracking_app`), database name (`car_tracker`), and database schema (version 5). It does not reset or delete existing records, receipts, or reminders. Ownership totals are recalculated with Accessories excluded; the accessory records remain saved.

Android requires the update APK to use the same signing certificate as the installed app. Personal builds currently use the local Android debug signing key, so builds from another machine or a regenerated key may be incompatible. If Android rejects the update, keep the existing app installed and obtain a build signed with the original key. Uninstalling to bypass that error removes local app data.

## Development

Built with Flutter and Dart. To run it locally:

```bash
flutter pub get
flutter run
```

Automated checks are available through `flutter test`. This project is provided as-is without warranty.
