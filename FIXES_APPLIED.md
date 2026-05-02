# Fixes Applied to Project Kimiko

## Summary

This document details all bugs identified and fixed across the Project Kimiko codebase. The primary focus was ensuring the Kimiko AI assistant correctly sends messages to the Gemini API and displays replies in the War Room chat.

---

## 1. Gemini API Endpoint — CRITICAL

**File:** `lib/chat_thread_screen.dart`

**Problem:** The Gemini API call used the `/v1/` endpoint, but `gemini-1.5-flash` requires the `/v1beta/` endpoint. This caused a 404 or model-not-found error, meaning Kimiko never replied.

**Fix:** Changed the endpoint URL from:
```
https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent
```
to:
```
https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent
```

---

## 2. Gemini Response Parsing — CRITICAL

**File:** `lib/chat_thread_screen.dart`

**Problem:** The original code accessed `data['candidates'][0]['content']['parts'][0]['text']` without null checks. If the API returned an error (e.g., invalid key, quota exceeded, or safety block), the app crashed with a `NoSuchMethodError` or `RangeError`.

**Fix:** Added defensive null-checks at each level of the response JSON. If the API returns a non-200 status code, the error message is now extracted and shown. Missing `candidates` or empty `parts` arrays are caught and reported gracefully via a SnackBar.

---

## 3. Missing Conversation Context

**File:** `lib/chat_thread_screen.dart`

**Problem:** Each message was sent in isolation — the prompt only contained the current user message. The AI had no memory of previous turns, making it unable to carry on a coherent conversation.

**Fix:** Before calling Gemini, the last 20 messages in the thread are fetched from Supabase and assembled into a multi-turn `contents` array. A system-level instruction is prepended to set Kimiko's persona and task context.

---

## 4. Navigation Tabs Showed Placeholders Instead of Real Screens

**File:** `lib/main.dart`

**Problem:** The `MainShell` widget used `_KimikoPlaceholder` and `_YouPlaceholder` inline widgets instead of the actual `KimikoScreen` and `YouScreen` classes defined in their respective files. Users could never see the Kimiko dashboard or the You/Ledger screen.

**Fix:** Replaced the placeholder widgets with `KimikoScreen()` and `YouScreen()`. Added the corresponding imports for `kimiko_screen.dart` and `you_screen.dart`.

---

## 5. Hardcoded API Keys & Credentials — SECURITY

**Files:** `lib/main.dart`, `lib/chat_thread_screen.dart`

**Problem:** The Supabase URL, anon key, and Gemini API key were hardcoded directly in source files. This is a security risk if the repo is public or shared.

**Fix:** Created `lib/config/keys.dart` as a centralized configuration file. All credentials are now imported from that single location. Added `lib/config/keys.dart` to `.gitignore` to prevent accidental commits.

> **Manual step required:** If you clone this repo fresh, you must recreate `lib/config/keys.dart` with your own credentials. See the template in the current file.

---

## 6. Duplicated Bypass User ID Constants

**Files:** `lib/tasks_list_screen.dart`, `lib/task_detail_screen.dart`, `lib/chat_thread_screen.dart`

**Problem:** The bypass UUID `00000000-0000-0000-0000-000000000000` was independently declared as `_kBypassUserId` in multiple files. Changing it required editing every file.

**Fix:** Moved the constant to `lib/config/keys.dart` as `kBypassUserId`. All files now import and reference this single source of truth.

---

## 7. Missing `dispose()` for Controllers

**File:** `lib/chat_thread_screen.dart`

**Problem:** `TextEditingController` was never disposed, causing potential memory leaks.

**Fix:** Added a proper `dispose()` override that disposes both the `TextEditingController` and the new `ScrollController`.

---

## 8. Missing `mounted` Checks After Async Gaps

**File:** `lib/chat_thread_screen.dart`

**Problem:** `setState` was called after `await` calls without checking `mounted`, which can throw a `setState() called after dispose()` exception if the user navigates away during an API call.

**Fix:** Added `if (!mounted) return;` guards after every async gap before calling `setState` or accessing `context`.

---

## 9. Lint Warning in `you_screen.dart`

**File:** `lib/you_screen.dart`

**Problem:** `TextStyle(color: Color(0xFF666666), fontSize: 16)` was missing the `const` keyword.

**Fix:** Added `const` to the `TextStyle` constructor.

---

## Files Changed

| File | Change Type |
|---|---|
| `lib/config/keys.dart` | **NEW** — Centralized API keys and constants |
| `lib/main.dart` | Modified — Imports config, wires up real screens |
| `lib/chat_thread_screen.dart` | Modified — Fixed API endpoint, parsing, context, dispose |
| `lib/tasks_list_screen.dart` | Modified — Imports centralized user ID |
| `lib/task_detail_screen.dart` | Modified — Imports centralized user ID |
| `lib/you_screen.dart` | Modified — Const lint fix |
| `.gitignore` | Modified — Added keys.dart exclusion |

## Files NOT Changed (no issues found)

| File | Status |
|---|---|
| `lib/kimiko_screen.dart` | Clean — static UI, no runtime issues |
| `lib/brainstorming_screen.dart` | Clean — correct Supabase query and navigation |
| `lib/main_layout.dart` | Clean — unused alternate layout (not imported by main.dart) |
| `pubspec.yaml` | Clean — all dependencies correct and resolved |
| `analysis_options.yaml` | Clean — valid config |

---

## Remaining Manual Steps

1. **Verify your Gemini API key** — Open `lib/config/keys.dart` and confirm the `geminiApiKey` value is a valid, active Google Cloud API key with the Generative AI API enabled.

2. **Verify your Supabase project** — Ensure the Supabase URL and anon key in `keys.dart` match your project. The database must have the following tables:
   - `tasks` (columns: `id`, `user_id`, `name`, `priority`, `status`, `time_budget_mins`, `purpose`, `check_target_value`, `check_metric_label`, `created_at`)
   - `micro_contributions` (columns: `id`, `task_id`, `user_id`, `logged_date`, `value`)
   - `war_room_chats` (columns: `id`, `task_id`, `user_id`, `role`, `content`, `created_at`)
   - `action_queue` (columns: `id`, `task_id`)

3. **Test the AI assistant:**
   - Run `flutter run`
   - Navigate to the **War Room** tab
   - Tap on any active task (create one in the Tasks tab first if none exist)
   - Type a message and press send
   - Verify that Kimiko replies within 2–5 seconds
   - Check the Supabase `war_room_chats` table to confirm both user and assistant messages are persisted

4. **Test task creation:**
   - Tap the **+** button on the Tasks tab
   - Fill in a task name, priority, and optional fields
   - Confirm the task appears in the list

5. **Test micro-contributions:**
   - Tap a task to open the detail screen
   - Log a numeric value
   - Confirm the velocity chart and vital signs update
