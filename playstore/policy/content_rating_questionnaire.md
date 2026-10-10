# Content rating (IARC questionnaire) – suggested answers

Category: **Utility, Productivity, Communication, or Other**

| Question | Answer |
| --- | --- |
| Does the app contain violence, blood, sexual content, nudity, profanity, drugs, alcohol, tobacco, gambling, horror or crude humour? | No to all |
| Does the app allow users to interact or exchange content with other users? | No (sharing goes through the Android share sheet to other apps; there is no in-app community) |
| Does the app share the user's current location with other users? | No |
| Does the app allow users to purchase digital goods? | No |
| Does the app contain ads? | No |
| Does the app promote or facilitate illegal activities? | No |
| Is the app a web browser or search engine? | No |

Expected rating: **Everyone / PEGI 3 / USK 0**.

# Other App content declarations

| Section | Answer |
| --- | --- |
| **Ads** | This app does not contain ads |
| **App access** | All functionality is available without special access. (The app lock is set by the user after install and is off by default, so reviewers can use the whole app.) |
| **Target audience and content** | Target age group: 18 and over (or 13–17 + 18+). Not designed to appeal to children. Choose a target audience that does NOT include under-13 so the Families policy does not apply. |
| **News app** | No |
| **COVID-19 contact tracing / status** | No |
| **Data safety** | See `data_safety_form.md` |
| **Government apps** | No |
| **Financial features** | None |
| **Health apps** | No health features |
| **Advertising ID** | The app does not use the advertising ID (`com.google.android.gms.permission.AD_ID` is not declared). If Play Console flags the permission because of a transitive Firebase dependency, keep "No" and add `<uses-permission android:name="com.google.android.gms.permission.AD_ID" tools:node="remove" />` to the manifest. |
| **App category** | Productivity (alternative: Tools) |
| **Tags** | Document scanner, PDF, OCR, Productivity |
