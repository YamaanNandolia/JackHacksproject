# JacCoder Handoff Automation

Bridges the agent pipeline (Agents 1–5) to the JacCoder VS Code extension.
When Agent 5 produces a software prompt, the launcher scaffolds a workspace,
opens it in VS Code, and the companion extension automatically surfaces the
prompt inside JacCoder — without any manual copy-paste.

---

## How it works end-to-end

```
Agent 5 output
     │
     ▼
jobs/<name>.json          ← job file: prompt + build spec
     │
     ▼  run_job.sh
launcher/
  launch_generated_app.py ← scaffolds generated_apps/job_<id>_<slug>/
     │                        writes PROMPT.md, BUILD_SPEC.json,
     │                        .jaccoder-job.json, main.jac, jac.toml
     │
     ▼  code --new-window
VS Code opens the workspace
     │
     ▼  (onStartupFinished)
companion_extension/      ← detects .jaccoder-job.json
     │                       logs job metadata
     │                       discovers JacCoder extension
     │                       attempts direct command trigger
     │
     ├─ success ──▶ JacCoder opens with prompt pre-filled
     │
     └─ failure ──▶ AppleScript fallback
                     focus_and_paste.applescript
                       • focuses VS Code
                       • opens Command Palette
                       • runs JacCoder: New Session
                       • pastes PROMPT.md contents
                       • presses Return
```

---

## One-time setup

### 1. Install system dependencies

| Requirement | Minimum | Check |
|-------------|---------|-------|
| Python 3 | 3.9 | `python3 --version` |
| Node.js | 18 | `node --version` |
| npm | 9 | `npm --version` |
| VS Code | 1.85 | `code --version` |
| VS Code `code` CLI | any | `which code` |

Install the `code` CLI if missing:
open VS Code → **⌘⇧P** → `Shell Command: Install 'code' command in PATH`

### 2. Build the companion extension

```bash
cd automation/companion_extension
npm install
npm run compile
```

### 3. Sideload the companion extension into VS Code

```bash
# From automation/companion_extension/
ln -s "$(pwd)" ~/.vscode/extensions/jaccoder-companion
```

Then reload VS Code: **⌘⇧P** → `Developer: Reload Window`

Verify it loaded: **View › Extensions** → search `JacCoder Companion` → should show as enabled.

### 4. Grant macOS accessibility permissions (first run only)

The AppleScript fallback uses System Events to send keystrokes.
macOS will prompt you automatically on first use, or you can pre-grant:

**System Preferences › Privacy & Security › Accessibility**
→ add **Visual Studio Code**

**System Preferences › Privacy & Security › Automation**
→ allow **osascript** (or **Terminal / iTerm**) to control **System Events**
→ allow **osascript** to control **Visual Studio Code**

If a permission prompt appears and you click "Don't Allow", the fallback will
fail silently. Re-grant from System Preferences and rerun the job.

---

## Running a job

```bash
# From the project root (Final1/)
./automation/launcher/run_job.sh jobs/sample_job.json
```

This will:
1. Read the job file
2. Create `generated_apps/job_001_cybersecurity-alert-tracker/`
3. Write all scaffold files into it
4. Open the folder in a new VS Code window

The companion extension takes over from there automatically.

### Dry run (no VS Code, no scaffold)

```bash
./automation/launcher/run_job.sh jobs/sample_job.json --no-scaffold --no-vscode
```

### Available flags

| Flag | Effect |
|------|--------|
| `--no-scaffold` | Skip writing `main.jac` / `jac.toml` |
| `--no-vscode` | Skip opening VS Code |

---

## Job file format

```json
{
  "id":    "string — unique job identifier",
  "slug":  "string — becomes the workspace folder name",
  "prompt": "string — full natural-language prompt for JacCoder",
  "build_spec": {
    "app_name":    "string",
    "language":    "jac",
    "entry_point": "main.jac",
    "features":    ["feature 1", "feature 2"],
    "ui":          "optional UI hint"
  }
}
```

`build_spec` is optional — sensible defaults are injected if missing.
See `jobs/sample_job.json` and `jobs/ai_trend_analyzer.json` for full examples.

---

## Inspecting logs

All companion extension activity is written to the VS Code output channel:

**View › Output** → select **JacCoder** from the dropdown

You will see:
- Job metadata (ID, app name, features, prompt preview)
- Full list of installed extensions scanned during discovery
- Every JacCoder command ID attempted and its result
- AppleScript invocation details and exit status

---

## File structure

```
automation/
  launcher/
    launch_generated_app.py   ← Python scaffolder (main logic)
    run_job.sh                ← shell entry point
    focus_and_paste.applescript ← macOS keystroke fallback
  companion_extension/
    src/extension.ts          ← all extension logic
    out/                      ← compiled JS (git-ignored)
    package.json
    tsconfig.json
    README.md                 ← extension-specific setup

generated_apps/               ← created workspaces land here (git-ignored)
jobs/                         ← job JSON files (committed as examples)
  sample_job.json
  ai_trend_analyzer.json
```

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| `code: command not found` | VS Code CLI not installed | Install via ⌘⇧P → `Shell Command: Install 'code'` |
| Extension not loading | Not compiled or not sideloaded | Run `npm run compile` then check symlink |
| JacCoder panel doesn't open | Extension command IDs changed | Check Output › JacCoder for attempted IDs; update `PALETTE_QUERY_CANDIDATES` in extension.ts |
| AppleScript fails silently | Accessibility permission denied | Grant in System Preferences › Privacy & Security |
| `osascript` timeout | JacCoder panel takes > 1.5s to open | Increase `postOpenDelay` arg in the AppleScript call or edit default in `.applescript` |
