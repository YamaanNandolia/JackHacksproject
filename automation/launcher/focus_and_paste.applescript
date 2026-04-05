(*
  focus_and_paste.applescript
  ───────────────────────────
  macOS-only fallback for the JacCoder Companion VS Code extension.

  What it does (in order):
    1. Reads the full contents of PROMPT.md from the given file path
    2. Locates the running VS Code process (handles stable / Insiders / OSS)
    3. Focuses the VS Code window
    4. Opens the Command Palette (⌘⇧P)
    5. Types the JacCoder command query and presses Return
    6. Waits for the chat input to become ready
    7. Pastes the prompt via the clipboard
    8. Presses Return to submit

  Usage:
    osascript focus_and_paste.applescript \
        <prompt_file_path>             (required) \
        [<command_palette_query>]      (optional, default: "JacCoder: New Session") \
        [<post_open_delay_seconds>]    (optional, default: 1.5)

  Arguments:
    prompt_file_path       – Absolute POSIX path to PROMPT.md
    command_palette_query  – Exact title shown in the Command Palette
    post_open_delay        – Seconds to wait after pressing Return before pasting
                             (increase if JacCoder takes longer to open its panel)

  Exit codes:
    0  – success
    1  – missing argument
    2  – prompt file unreadable
    3  – VS Code process not found
    4  – unexpected error

  Permissions required (macOS System Preferences › Privacy & Security):
    • Accessibility  – to send keystrokes via System Events
    • Automation     – to control "System Events" and "Visual Studio Code"
*)

-- ─── Entry point ─────────────────────────────────────────────────────────────

on run argv
  -- ── Parse arguments ──────────────────────────────────────────────────────
  if (count of argv) < 1 then
    logMsg("ERROR: Missing required argument: <prompt_file_path>")
    logMsg("Usage: osascript focus_and_paste.applescript <prompt_file_path> [<command_query>] [<delay>]")
    error "Missing prompt_file_path argument." number 1
  end if

  set promptFilePath to item 1 of argv

  set paletteQuery to "JacCoder: New Session"
  if (count of argv) >= 2 then
    set paletteQuery to item 2 of argv
  end if

  set postOpenDelay to 1.5
  if (count of argv) >= 3 then
    set postOpenDelay to (item 3 of argv) as real
  end if

  logMsg("──────────────────────────────────────────")
  logMsg("JacCoder AppleScript Fallback — Starting")
  logMsg("──────────────────────────────────────────")
  logMsg("Prompt file   : " & promptFilePath)
  logMsg("Palette query : " & paletteQuery)
  logMsg("Post-open wait: " & postOpenDelay & "s")

  -- ── Step 1: Read PROMPT.md ────────────────────────────────────────────────
  logMsg("Step 1: Reading prompt file…")
  set promptText to ""
  try
    set promptText to read POSIX file promptFilePath as «class utf8»
  on error readErr
    logMsg("ERROR: Cannot read prompt file: " & readErr)
    error "Cannot read prompt file: " & readErr number 2
  end try
  set charCount to count of promptText
  logMsg("Read " & charCount & " characters from prompt file.")

  -- ── Step 2: Find VS Code process ─────────────────────────────────────────
  logMsg("Step 2: Locating VS Code process…")
  set vsApp to findVSCodeProcess()
  if vsApp is "" then
    logMsg("ERROR: No running VS Code process found.")
    logMsg("Tried: Visual Studio Code, Code - Insiders, VSCodium, Code")
    error "VS Code is not running." number 3
  end if
  logMsg("Found VS Code process: " & vsApp)

  -- ── Step 3: Focus VS Code ─────────────────────────────────────────────────
  logMsg("Step 3: Focusing VS Code…")
  try
    tell application vsApp
      activate
    end tell
    delay 0.8
  on error focusErr
    logMsg("ERROR: Failed to activate VS Code: " & focusErr)
    error "Could not focus VS Code." number 4
  end try
  logMsg("VS Code focused.")

  -- ── Step 4: Open Command Palette ──────────────────────────────────────────
  logMsg("Step 4: Opening Command Palette (⌘⇧P)…")
  try
    tell application "System Events"
      tell process vsApp
        keystroke "p" using {command down, shift down}
      end tell
    end tell
    delay 0.6
  on error paletteErr
    logMsg("ERROR: Could not open Command Palette: " & paletteErr)
    error "Could not open Command Palette." number 4
  end try
  logMsg("Command Palette opened.")

  -- ── Step 5: Type command query ────────────────────────────────────────────
  logMsg("Step 5: Typing palette query: "" & paletteQuery & """)
  try
    tell application "System Events"
      tell process vsApp
        -- Clear any pre-filled text before typing
        keystroke "a" using {command down}
        delay 0.1
        keystroke paletteQuery
      end tell
    end tell
    delay 0.4
  on error typeErr
    logMsg("ERROR: Could not type into Command Palette: " & typeErr)
    error "Could not type into Command Palette." number 4
  end try

  -- ── Step 6: Press Return to run the command ───────────────────────────────
  logMsg("Step 6: Pressing Return to execute command…")
  try
    tell application "System Events"
      tell process vsApp
        key code 36 -- Return
      end tell
    end tell
  on error returnErr
    logMsg("ERROR: Could not press Return: " & returnErr)
    error "Could not press Return in Command Palette." number 4
  end try

  logMsg("Command executed. Waiting " & postOpenDelay & "s for JacCoder panel to open…")
  delay postOpenDelay

  -- ── Step 7: Paste prompt via clipboard ────────────────────────────────────
  logMsg("Step 7: Setting clipboard to prompt content…")
  set the clipboard to promptText
  delay 0.2

  logMsg("Step 7: Pasting prompt (⌘V)…")
  try
    tell application "System Events"
      tell process vsApp
        keystroke "v" using {command down}
      end tell
    end tell
    delay 0.3
  on error pasteErr
    logMsg("ERROR: Could not paste prompt: " & pasteErr)
    error "Could not paste prompt." number 4
  end try
  logMsg("Prompt pasted.")

  -- ── Step 8: Press Return to submit ───────────────────────────────────────
  logMsg("Step 8: Pressing Return to submit prompt…")
  try
    tell application "System Events"
      tell process vsApp
        key code 36 -- Return
      end tell
    end tell
  on error submitErr
    logMsg("ERROR: Could not press Return to submit: " & submitErr)
    error "Could not submit prompt." number 4
  end try

  logMsg("──────────────────────────────────────────")
  logMsg("Done. Prompt submitted to JacCoder.")
  logMsg("──────────────────────────────────────────")
  return "OK"
end run


-- ─── Helpers ─────────────────────────────────────────────────────────────────

(*
  Return the name of the running VS Code variant process, or "" if none found.
  Checks: stable → Insiders → VSCodium → bare "Code" process.
*)
on findVSCodeProcess()
  set candidates to {"Visual Studio Code", "Code - Insiders", "VSCodium", "Code"}
  repeat with candidate in candidates
    try
      tell application "System Events"
        if exists process candidate then
          return candidate as string
        end if
      end tell
    end try
  end repeat
  return ""
end findVSCodeProcess

(*
  Minimal structured logger — writes to stderr so the caller (Node execFile)
  can capture it separately from stdout.
*)
on logMsg(msg)
  set ts to do shell script "date '+%H:%M:%S'"
  log "[" & ts & "] " & msg
end logMsg
