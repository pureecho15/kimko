# Project Kimiko: AI-Driven Productivity Ecosystem

## High-Level Description
Project Kimiko is a sophisticated AI-powered productivity application designed to function as an "AI Enforcer" rather than a passive task manager. The system combines traditional task tracking with proactive AI monitoring and interactive brainstorming capabilities. By leveraging Large Language Models (LLMs), Kimiko tracks user commitments, researches relevant trends, and provides real-time interventions to ensure tasks are completed. The application is built with a focus on high-performance mobile and web interaction, featuring a dark-themed, premium aesthetic.

## Technology Stack
- **Framework:** Flutter (3.x)
- **Programming Language:** Dart
- **Backend-as-a-Service (BaaS):** Supabase (PostgreSQL, Realtime, Authentication)
- **Artificial Intelligence:** Google Gemini 1.5 Flash (via REST API)
- **Data Persistence:** Supabase Database (PostgreSQL)
- **Communication:** HTTP REST for AI, WebSockets for Supabase Realtime

## Folder Structure
```text
kimiko/
├── android/                # Android-specific platform code and configurations
├── ios/                    # iOS-specific platform code and configurations
├── lib/                    # Core application source code
│   ├── main.dart           # Entry point, Supabase initialization, and root navigation
│   ├── main_layout.dart    # Primary application shell and navigation bar logic
│   ├── kimiko_screen.dart  # AI "Enforcer" dashboard with activity feeds and alerts
│   ├── brainstorming_screen.dart # Directory for active AI-assisted brainstorming threads
│   ├── chat_thread_screen.dart  # Interactive chat interface with Gemini 1.5 Flash integration
│   ├── tasks_list_screen.dart   # Dashboard for high-level task management
│   ├── task_detail_screen.dart  # Detailed task tracking with custom velocity charts
│   └── you_screen.dart     # User profile and system settings (The Ledger)
├── web/                    # Web-specific platform code
├── windows/                # Windows-specific platform code
├── pubspec.yaml            # Project dependencies and Flutter configuration
└── README.md               # Basic project documentation
```

## Core Modules

### 1. Task Management & Micro-Contributions
The system tracks tasks with high granularity. Users log "micro-contributions" against specific metrics (e.g., hours, units, or progress values). A custom-built **Velocity Timeline** visualizes these contributions over a 7-day period using Catmull-Rom spline interpolation for smooth data representation.

### 2. Kimiko AI Enforcer
This module acts as the proactive layer of the application. It monitors task status and user activity. Key features include:
- **Actionable Queue:** Displays pending tasks that require immediate attention.
- **Activity Feed:** Logs autonomous AI actions, such as researching trends or preparing for future tasks.
- **Interventions:** Proactive alerts (e.g., "Boss?? You have a pending task??") designed to keep users accountable.

### 3. War Room (Brainstorming)
A real-time chat interface where users can brainstorm with the Kimiko AI. It utilizes the **Gemini 1.5 Flash** model to provide context-aware suggestions based on the specific task being discussed. Chats are persisted in Supabase with real-time synchronization across devices.

### 4. Supabase Integration
The backend architecture relies on Supabase for:
- **Relational Storage:** Managing tasks, micro-contributions, and chat histories.
- **Realtime Streams:** Ensuring the UI reflects changes instantly as they happen in the database.
- **Authentication (Schema Ready):** The codebase uses a bypass UUID system (`00000000-...`) for rapid development, but is structured for full Supabase Auth integration.

## Entry Points & Execution Flow
1. **Bootstrap:** The application initializes via `lib/main.dart`, where Supabase clients and system UI styles are configured.
2. **Main Shell:** Users land on the `MainShell` (found in `main.dart`), which hosts the `IndexedStack` navigation between Tasks, Kimiko, War Room, and the User Profile.
3. **Interaction Flow:**
   - User creates a task in the **Tasks** screen.
   - User logs progress in **Task Detail**.
   - If a task is neglected, **Kimiko** generates an intervention in the AI dashboard.
   - User initiates a "Brainstorm" from the **War Room** to overcome blockers, triggering the Gemini API pipeline.

## Configuration
The project is currently configured with the following parameters:
- **Supabase Endpoint:** `https://osveifptdeeckjaqrofe.supabase.co`
- **AI Model:** `gemini-1.5-flash`
- **Environment Variables:** Currently, API keys and Supabase credentials are hardcoded within `main.dart` and `chat_thread_screen.dart` for development purposes.

## Dependencies
The project utilizes several key packages to facilitate its functionality:
- `supabase_flutter`: For backend communication and real-time data.
- `http`: For making direct REST calls to the Google Generative AI (Gemini) endpoints.
- `cupertino_icons`: For iOS-style iconography.
- `flutter_lints`: For maintaining code quality and adhering to Dart best practices.

## Testing & Quality
- **Linter:** Configured via `analysis_options.yaml` to enforce strict coding standards.
- **Automated Tests:** The project structure includes a `test/` directory for unit and widget testing (standard Flutter practice).
- **Haptic Feedback:** Integrated into logging actions for a premium user experience.

## Deployment
The application is cross-platform by design and can be deployed to:
- **Mobile:** Android and iOS (primary targets).
- **Web:** Fully responsive web application.
- **Desktop:** Windows, macOS, and Linux support is included in the project skeleton.

## Potential Improvements & Missing Pieces
- **Security:** Migration of the Gemini API key and Supabase Anon Key to a secure environment variable or backend proxy.
- **Multi-tenancy:** Transition from the hardcoded bypass user ID to a dynamic authentication-based user management system.
- **AI Tooling:** Expanding Kimiko's capabilities to include automated web search or direct task modification via function calling.
- **State Management:** While currently using `setState` and `StreamBuilder`, the project may benefit from a centralized state management solution (e.g., Riverpod or Bloc) as complexity grows.
