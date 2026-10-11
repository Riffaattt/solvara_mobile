# Solvara — Flutter Citizen App PRD

**Version:** 1.0  
**Status:** Draft for hackathon MVP  
**Product:** Solvara — AI-assisted civic issue reporting

## 1. Product overview

Solvara helps residents report public-infrastructure and neighborhood issues—such as damaged roads, unmanaged waste, blocked drainage, broken streetlights, and other public-facility problems. The citizen-facing Flutter app lets a resident submit a report with a description, photo, and location, then follow its status and provide feedback.

AI supports the workflow by helping categorize and summarize incoming reports, flagging potentially related or duplicate reports, and suggesting a priority for staff review. AI recommendations are advisory: authorized public-service staff retain responsibility for decisions and actions.

## 2. Goals and non-goals

### Goals
- Make it straightforward for residents to submit a useful, location-aware report.
- Provide a clear report status and update history.
- Capture structured data that helps officers review and route issues.
- Keep AI processing behind the backend so the mobile app does not expose model credentials.
- Deliver an MVP that can be built and demonstrated during a hackathon.

### Non-goals for the citizen app MVP
- An officer/admin dashboard.
- Direct calls from Flutter to IBM Langflow or an AI model.
- Automatic enforcement or final decisions made by AI.
- Guaranteed real-time government-system integration.
- Complex offline synchronization unless explicitly added later.

## 3. Users and primary journeys

### Primary user
A resident who notices a public issue and wants to report it and track progress.

### Main journeys
1. Register or sign in.
2. Create a report: choose category (or accept a suggested category), describe the issue, attach a photo if available, and set a location by GPS or manual selection.
3. Review and submit the report.
4. Browse personal reports and open a report detail page.
5. Follow status updates and the report timeline.
6. Provide feedback when a report is marked resolved.

## 4. MVP features

### Authentication
- Sign up, sign in, and sign out.
- Persist an authenticated session securely.
- Handle expired sessions and API errors with clear Indonesian-language messages.

### Create report
- Required description and category; photo is optional unless product decisions change.
- Attach a photo using camera/gallery picker where supported.
- Capture current GPS location with permission, or allow manual location selection/entry.
- Show a preview of the report before submission.
- Validate required fields and explain permission failures without blocking manual entry.

### My reports
- List reports created by the current user.
- Show title/summary, category, submission date, status, and location summary.
- Support loading, empty, error, and retry states.
- Pagination or incremental loading may be added if the backend supports it.

### Report detail and timeline
- Show description, category, photos, location, created date, current status, and status history.
- Display public-facing staff updates if provided by the API.
- Do not expose internal officer notes or private user data.

### Resolution feedback
- Allow the resident to rate or comment on the resolution when the report is eligible.
- Prevent duplicate submissions where supported by the backend.
- Show confirmation or a useful error.

## 5. AI-assisted backend behavior

AI is invoked server-side, not directly from Flutter. The backend may use IBM Langflow to orchestrate model steps.

Potential AI tasks:
- Classify a report into an approved category list.
- Produce a concise summary from the citizen's description.
- Identify candidate duplicate or related reports.
- Suggest priority using transparent, configurable signals.

Requirements:
- Treat AI output as untrusted suggestions and validate it against an expected schema.
- Keep staff in control of final priority, assignment, and resolution.
- Do not make claims that a report is verified merely because AI processed it.
- Provide a graceful fallback if the AI service is unavailable.
- Avoid sending unnecessary personal information to the AI workflow.
- Keep secrets, model keys, and Langflow endpoints on the server.

## 6. Suggested technical stack

- **Mobile:** Flutter and Dart.
- **State management:** Riverpod.
- **HTTP:** Dio.
- **Navigation:** go_router.
- **Secure session storage:** flutter_secure_storage.
- **Image selection:** image_picker.
- **Location:** geolocator; manual location fallback required.
- **Maps:** optional flutter_map or another map package, depending on API keys and hackathon constraints.
- **Backend:** Laravel REST API.
- **Database:** MySQL.
- **AI orchestration:** IBM Langflow called by the backend.
- **Coding assistant:** IBM Bob is a development-time assistant, not a runtime dependency.

Confirm package versions and backend contract before implementation.

## 7. API assumptions

The exact routes and response envelopes must be confirmed with the backend team. Example logical operations:

- `POST /api/auth/register`
- `POST /api/auth/login`
- `POST /api/auth/logout`
- `GET /api/me`
- `GET /api/reports`
- `POST /api/reports` (multipart when uploading a photo)
- `GET /api/reports/{id}`
- `POST /api/reports/{id}/feedback`

Example report model:

```json
{
  "id": "report-id",
  "title": "Ringkasan laporan",
  "description": "Deskripsi dari warga",
  "category": "road_damage",
  "status": "submitted",
  "photo_urls": [],
  "latitude": -6.2,
  "longitude": 106.8,
  "created_at": "ISO-8601 timestamp",
  "timeline": []
}
```

Suggested status values (confirm with backend): `submitted`, `under_review`, `in_progress`, `resolved`, `rejected`.

Suggested category values (confirm with backend): `road_damage`, `waste`, `drainage`, `streetlight`, `public_facility`, `other`.

The mobile app must not assume these names are final until the API contract is agreed.

## 8. Suggested project structure

```text
lib/
  app/
    app.dart
    router.dart
    theme/
  core/
    config/
    errors/
    network/
    storage/
    widgets/
  features/
    auth/
      data/
      domain/
      presentation/
    reports/
      data/
      domain/
      presentation/
    profile/
      presentation/
```

Keep API clients and DTOs out of widgets. Separate presentation, data access, and domain models enough to make the MVP testable without overengineering.

## 9. UX and accessibility

- Primary language: Bahasa Indonesia.
- Use plain, respectful language and concise labels.
- Make status and validation messages understandable.
- Support small screens and different text sizes.
- Provide loading, empty, offline/network-error, and retry states.
- Do not rely on color alone to communicate status.
- Request location and photo permissions only when needed.
- Always provide a manual location alternative if GPS permission is denied.

## 10. Privacy and security

- Use HTTPS in production.
- Store tokens in secure storage, not ordinary preferences.
- Never hardcode credentials, AI keys, or private endpoints in the app.
- Validate all data on the server; client validation is for usability only.
- Request only necessary permissions and explain why they are needed.
- Handle user-generated photos and location as potentially sensitive data.
- Avoid logging tokens, precise location, or unnecessary personal data.
- Enforce authorization on the backend so users can access only their own reports unless explicitly public.

## 11. Error handling and resilience

- Handle network timeout, no connection, unauthorized response, validation errors, and server errors.
- Preserve form input when a submission fails where feasible.
- Prevent accidental duplicate submissions while a request is in progress.
- Show an actionable retry path.
- If AI processing fails, accept the report using backend fallback rules when possible; do not require AI availability for basic reporting.

## 12. Acceptance criteria

- A user can register/sign in and securely maintain a session.
- A user can create a report with a category, description, and location.
- A user can attach an optional photo and preview it before submission.
- GPS denial does not make reporting impossible; manual location is available.
- A successful submission returns a report identifier and appears in My Reports.
- The report detail page shows status and available timeline updates.
- Loading, empty, validation, and network error states are implemented.
- The app does not call Langflow directly or contain AI credentials.
- AI suggestions are treated as advisory and backend-validated.
- The app uses Indonesian for user-facing copy.

## 13. Implementation plan

1. Confirm API routes, auth scheme, response envelope, category/status enums, and upload constraints.
2. Set up Flutter project, theme, routing, Riverpod, and Dio client.
3. Implement authentication and session handling.
4. Implement report list and report detail.
5. Implement report creation, photo selection, and location capture/manual entry.
6. Add timeline and resolution feedback if backend endpoints are ready.
7. Add robust loading/error states and basic tests.
8. Integrate and test server-side AI workflow through the Laravel API.
9. Prepare a demo flow with realistic sample reports.

## 14. Decisions to confirm

- Does the backend use Laravel Sanctum, JWT, or another authentication mechanism?
- Are reports visible only to their creator, or is there a public community feed?
- Which categories and statuses are canonical?
- Is photo upload required or optional, and what are file-size/type limits?
- What map/location provider is allowed for the demo?
- What are the exact report and feedback API contracts?
- Which AI tasks are in scope for the hackathon demo?
- What is the retention policy for photos, location, and user-submitted content?
