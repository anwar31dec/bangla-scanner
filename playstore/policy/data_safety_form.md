# Play Console → App content → Data safety: answers

**Fastest route:** in Play Console open App content → Data safety → *Import from CSV* and upload `data_safety_bangla_scanner.csv` from this folder. It is the Play export template with every answer below filled in. Review the preview, then Save and Submit. The tables below are the same answers for checking by hand.

These answers reflect the code as of version 1.2.2 (Android build includes Firebase Crashlytics and Firebase Analytics; everything else is offline). Re-check them whenever an SDK is added.

## Overview questions

| Question | Answer |
| --- | --- |
| Does your app collect or share any of the required user data types? | **Yes** (crash logs and diagnostics, app interactions, device IDs via Firebase) |
| Is all of the user data collected by your app encrypted in transit? | **Yes** (Firebase uses HTTPS) |
| Do you provide a way for users to request that their data is deleted? | **Yes** – by e-mail (s.anwar369@gmail.com); documents are deleted by the user in the app or by uninstalling. Link the privacy policy. |
| Have you reviewed the Google Play Families policy / is the app for children? | Not designed for children (target audience 13+) |
| Does your app's data collection and security practices comply with Google Play's User Data policy? | Yes |

## Data types

Mark only the following. Everything else (Location, Personal info, Financial info, Health, Messages, Photos and videos, Audio, Files and docs, Calendar, Contacts, Web browsing) → **not collected and not shared**.

Note: the app processes photos, documents and files, but only on the device. Data that is processed ephemerally on the device and never sent off the device does not have to be declared as "collected" under the Play definition.

### App activity → App interactions
- Collected: **Yes** · Shared: **No**
- Ephemeral: No
- Required or optional: **Required** (users cannot opt out)
- Purpose: **Analytics**
- Why: Firebase Analytics logs screen views and app opens.

### App info and performance → Crash logs
- Collected: **Yes** · Shared: **No**
- Ephemeral: No · Required
- Purpose: **Analytics** (crash analysis)
- Why: Firebase Crashlytics.

### App info and performance → Diagnostics
- Collected: **Yes** · Shared: **No**
- Ephemeral: No · Required
- Purpose: **Analytics**
- Why: Crashlytics sends device state at crash time (memory, disk, orientation, OS version).

### Device or other IDs → Device or other IDs
- Collected: **Yes** · Shared: **No**
- Ephemeral: No · Required
- Purpose: **Analytics**
- Why: Firebase installation ID / Analytics app-instance ID (not the advertising ID). The app does not declare `AD_ID` permission.

## Security practices

| Question | Answer |
| --- | --- |
| Data is encrypted in transit | Yes |
| You can request that data be deleted | Yes |
| Committed to follow the Play Families Policy | No (not a kids app) |
| Independent security review | No |

## Privacy policy URL

Published (GitHub Pages, repo `anwar31dec/bangla-scanner-docs`):

**https://anwar31dec.github.io/bangla-scanner-docs/privacy-policy.html**

Paste that URL in **App content → Privacy policy**. The same URL is also required for the Data safety "deletion request" link.

## If you later remove Firebase from the Android build

Answer "No" to the first question and declare no data types. The listing and privacy policy sections about Crashlytics/Analytics must be updated at the same time.
