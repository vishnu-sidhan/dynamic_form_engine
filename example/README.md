# Dynamic Form Engine Example App

This folder contains an interactive showcase and demonstration application for the `dynamic_form_engine` package.

## Features & Forms Demonstrated

The application seeds 3 distinct generic form templates accessible via the top-bar dropdown:

1. **All Field Types Master Showcase**:
   - Demonstrates all supported `FormFieldType` options in a single comprehensive form:
     - **Textual & Contact**: `text`, `textarea`, `email`, `phone`
     - **Numeric & Financial**: `number`, `decimal`, `currency`
     - **Computed / Derived**: `calculated` (live formula: `[quantity_units] * [unit_rate]`)
     - **Selection & Options**: `dropdown`, `radio`, `checkbox`, `multiSelect`, `toggle`
     - **Temporal**: `date`, `time`, `dateTime`, `dateRange`
     - **Media & Assets**: `image`, `video`, `document`
     - **Advanced Interactions**: `signature` (interactive drawing canvas), `gpsLocation` (geotag coordinates capture)
     - **Sub-forms**: `groupRepeater` (nested dynamic repeating line items)

2. **Work Order & Service Inspection**:
   - Dynamic real-time calculated total service fee (`[service_hours] * [hourly_rate]`).
   - Conditional field dependencies (flagging an escalation checkbox conditionally reveals and requires escalation notes).
   - Facility GPS location capture.
   - Lead inspector verification signature pad.

3. **Customer Experience & Feedback Survey**:
   - Multi-option rating radios and feature selection checkboxes.
   - Recommendation toggles and feedback narrative.

4. **Dynamic Visual Form Designer**:
   - Visually add, configure, and re-order custom form fields and save new templates to the local database.

5. **Submissions History & Inspection**:
   - Review past form submissions with full answer resolution, user IDs, and timestamps.

6. **Live JSON Inspector**:
   - Real-time serialization preview of active form templates.

7. **Theme Switcher**:
   - Material 3 Light & Dark mode support.

## Running the Example

### In VS Code
Select **Run Example App** in the Run & Debug view and press **F5**.

### In Terminal
```bash
flutter run -d chrome # Or your target device (macos, ios, android, windows, linux)
```
