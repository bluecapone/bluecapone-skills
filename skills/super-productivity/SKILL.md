---
name: super-productivity
description: Read and control the running Super Productivity desktop app through its Local REST API on 127.0.0.1:3876 - list, search, create, update, archive and delete tasks, start/stop the current task, read Focus Mode state, list projects and tags. Use when the user mentions Super Productivity, SP tasks, their task list, time tracking, or the current task.
---

# Super Productivity (Local REST API)

Drive a running Super Productivity desktop app over its Local REST API.
Source: [3.01-API.md §3](https://github.com/super-productivity/super-productivity/blob/master/docs/wiki/3.01-API.md).

## Prerequisites

- Electron desktop app only (not web or mobile), and it must be running with the renderer ready.
- The API is disabled by default. The user enables it in **Settings → Misc → Enable local REST API**.
- The Bearer token is generated when the API is enabled and stored in the `local-rest-api-token` file (mode `0600`) in the user data folder:
  - macOS: `~/Library/Application Support/superProductivity/`
  - Linux: `~/.config/superProductivity/`
  - Windows: `%APPDATA%\superProductivity\`
- Preflight (no token needed):

  ```bash
  curl --noproxy 127.0.0.1 -s http://127.0.0.1:3876/health
  # {"ok":true,"data":{"server":"up","rendererReady":true}}
  ```

  Connection refused or `"rendererReady":false`: stop and tell the user to start the app or enable the API.

## Calling the API

`$SKILL_DIR` is the directory containing this `SKILL.md`. Always call through the helper:

```bash
bash "$SKILL_DIR/scripts/sp-api.sh" METHOD PATH [JSON_BODY]
bash "$SKILL_DIR/scripts/sp-api.sh" GET /tasks
bash "$SKILL_DIR/scripts/sp-api.sh" POST /tasks '{"title":"Buy groceries","projectId":"INBOX_PROJECT"}'
```

- The helper reads the token file and passes the header to curl without exposing it in argv. Set `SP_TOKEN_FILE` to override the path.
- Never put the token on a command line. Never print the token file.
- URL-encode query values yourself: `/tasks?query=team%20sync`.
- Every response uses one envelope:
  - Success: `{"ok": true, "data": <response data>}`
  - Error: `{"ok": false, "error": {"code": "<ERROR_CODE>", "message": "<description>"}}`

## Endpoints

| Method | Path | Description |
| --- | --- | --- |
| GET | `/health` | Server up and renderer ready (no auth) |
| GET | `/tasks` | List tasks (filters below) |
| GET | `/tasks/:id` | Get task by ID |
| POST | `/tasks` | Create task |
| PATCH | `/tasks/:id` | Update task |
| DELETE | `/tasks/:id` | Delete task |
| POST | `/tasks/:id/start` | Start task (set as current) |
| POST | `/tasks/:id/archive` | Archive task |
| POST | `/tasks/:id/restore` | Restore archived task |
| GET | `/status` | Current task and task count |
| GET | `/task-control/current` | Get current task |
| POST | `/task-control/current` | Set current task: `{"taskId": "task-id"}`, or `{"taskId": null}` to clear |
| POST | `/task-control/stop` | Stop current task |
| GET | `/focus` | Read-only Focus Mode timer state and mode |
| GET | `/projects` | List projects (`query` filters by title, case-insensitive) |
| GET | `/tags` | List tags (`query` filters by title, case-insensitive) |

### `GET /tasks` query parameters

| Parameter | Type | Description |
| --- | --- | --- |
| `query` | string | Filter by title (case-insensitive, contains) |
| `projectId` | string | Filter by project ID |
| `tagId` | string | Filter by tag ID. `TODAY` = tasks scheduled for today |
| `includeDone` | boolean | Include completed tasks (default `false`) |
| `source` | `active` \| `archived` \| `all` | Default `active` |

Archiving marks a task done. List archived tasks with `source=archived&includeDone=true`; without `includeDone` the result is empty. While archived, `GET /tasks/:id`, `PATCH` and `DELETE` return `TASK_NOT_FOUND`; `restore` it first.

### `GET /focus`

Returns `mode` (`Flowtime` \| `Pomodoro` \| `Countdown`), `cycle`, `isSessionDone`, and `timer` (`null` when no timer exists, else `purpose`, `status` `running`\|`paused`\|`done`, `isOvertime`, `isLongBreak`, `elapsedMs`, `remainingMs`, `durationMs`). It exposes no task content and no controls.

## Write rules

`POST /tasks` body:

- `title` is required (non-empty string).
- `parentId` creates a subtask of a **top-level** task. The subtask inherits the parent's `projectId` and has no own tags; sending `projectId` or `tagIds` with `parentId` returns `400 UNSUPPORTED_FIELD`. Missing parent, or parent that is itself a subtask, returns 404.
- `subTaskIds` is rejected on create. Create the parent first, then each child with `parentId`.
- Other allowed fields: `notes`, `isDone`, `timeEstimate`, `timeSpent`, `projectId`, `tagIds`, `dueDay`, `dueWithTime`, `plannedAt`, `deadlineDay`, `deadlineWithTime`, `deadlineRemindAt`.

`PATCH /tasks/:id`:

- `parentId` and `subTaskIds` return `400 UNSUPPORTED_FIELD`. Re-parenting is not supported; delete and recreate instead.
- Changing `projectId` on a top-level task moves it and its subtasks. The destination must be an existing active project, else `404 PROJECT_NOT_FOUND`. A subtask's `projectId` cannot be changed.

Values:

- Time fields (`timeEstimate`, `timeSpent`) are milliseconds.
- `deadlineDay` is `YYYY-MM-DD`. `deadlineWithTime` and `deadlineRemindAt` are positive Unix timestamps in milliseconds. The deadline types are mutually exclusive: both non-null in one request returns `400 INVALID_INPUT`. Changing a deadline clears its `deadlineRemindAt` unless a new reminder is sent in the same request. An explicit `null` on `deadlineRemindAt` clears only the reminder. Setting a deadline re-applies Today planning, so a deadline of today can rewrite `dueDay` and clear `dueWithTime`.
- `INBOX_PROJECT` is the inbox project ID.

## Error codes

| Code | HTTP | Meaning |
| --- | --- | --- |
| `UNAUTHORIZED` | 401 | Missing, malformed, or wrong access token |
| `TASK_NOT_FOUND` | 404 | Task does not exist |
| `PROJECT_NOT_FOUND` | 404 | Target project does not exist or is archived |
| `INVALID_INPUT` | 400 | Invalid body or wrong field type (see `error.details`) |
| `UNSUPPORTED_FIELD` | 400 | Field cannot be changed through this endpoint |
| `NOT_FOUND` | 404 | Route not found |
| `INTERNAL_ERROR` | 500 | Internal server error |

On 401, tell the user to check or regenerate the token in **Settings → Misc → Access Token** (regenerating invalidates the old token immediately).

## Safety

- Look up IDs with `GET` first. Never guess task or project IDs.
- Before `DELETE /tasks/:id`, show the task title and get explicit user confirmation. Prefer `archive`; `restore` undoes it.
- Renderer responses time out after 15 seconds. The port is fixed at 3876.

## Other Super Productivity APIs

Not covered by this skill; see [3.01-API.md](https://github.com/super-productivity/super-productivity/blob/master/docs/wiki/3.01-API.md):

- **Sync Server REST API**: SuperSync operation-based sync service, JWT Bearer auth.
- **Plugin API**: global `PluginAPI` inside SP plugins.
- **URL scheme actions**: `superproductivity://create-task?title=…` and `complete-task` on desktop.
