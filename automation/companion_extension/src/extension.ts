import * as vscode from "vscode";
import * as fs from "fs";
import * as path from "path";
import * as os from "os";
import { execFile } from "child_process";

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------
const JOB_FILE = ".jaccoder-job.json";
const CHANNEL_NAME = "JacCoder";

/**
 * Keywords used to score candidate extensions during discovery.
 * Order matters: earlier = higher match priority.
 */
const JACCODER_ID_KEYWORDS = [
  "jaccoder", "jac-coder", "jac_coder",
  "jaseci", "jaclang",
  "claude", "anthropic",
];

/**
 * Substring patterns (lowercase) that identify a command as "open/start" intent.
 * Used to rank commands extracted from a discovered extension.
 */
const OPEN_INTENT_PATTERNS = [
  "newchat", "new-chat", "new_chat",
  "newsession", "new-session", "new_session",
  "newconversation",
  "openchat", "open-chat", "open_chat",
  "openpanel", "open-panel", "open_panel",
  "startchat", "start-chat", "start_chat",
  "startsession",
  "focus", "show", "open", "launch", "start", "new",
];

/**
 * Command Palette query candidates for each known JacCoder-style extension.
 * Tried in order; the first one that resolves the command is used.
 */
const PALETTE_QUERY_CANDIDATES: Record<string, string[]> = {
  claude:      ["Claude: New Chat", "Claude Code: New Chat", "Claude: Open"],
  anthropic:   ["Claude: New Chat", "Claude Code: New Chat"],
  jaccoder:    ["JacCoder: New Session", "JacCoder: New Chat", "JacCoder: Open"],
  jaseci:      ["JacCoder: New Session", "Jaseci: New Session"],
};

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------
interface JacCoderJob {
  id: string;
  slug: string;
  prompt?: string;
  build_spec?: {
    app_name?: string;
    language?: string;
    entry_point?: string;
    features?: string[];
    [key: string]: unknown;
  };
  _meta?: {
    launched_at?: string;
    source_job_file?: string;
    workspace?: string;
    launcher_version?: string;
  };
}

interface DiscoveredExtension {
  ext: vscode.Extension<unknown>;
  score: number;
  commands: string[];
}

// ---------------------------------------------------------------------------
// Module-level state
// ---------------------------------------------------------------------------
let out: vscode.OutputChannel;
let ctxExtensionPath: string; // set in activate(); used by AppleScript fallback

// ---------------------------------------------------------------------------
// Activation
// ---------------------------------------------------------------------------
export function activate(context: vscode.ExtensionContext): void {
  out = vscode.window.createOutputChannel(CHANNEL_NAME);
  context.subscriptions.push(out);
  ctxExtensionPath = context.extensionPath;

  log("JacCoder Companion activated.");
  log(`VS Code version : ${vscode.version}`);
  log(`Extension host  : ${context.extensionPath}`);
  log(`Platform        : ${os.platform()} ${os.release()}`);

  const job = detectJobWorkspace();

  if (job) {
    handleJobWorkspace(job);
  } else {
    log("No .jaccoder-job.json found in the current workspace — standing by.");
  }
}

// ---------------------------------------------------------------------------
// Deactivation
// ---------------------------------------------------------------------------
export function deactivate(): void {
  log("JacCoder Companion deactivated.");
}

// ---------------------------------------------------------------------------
// Workspace detection
// ---------------------------------------------------------------------------

function detectJobWorkspace(): JacCoderJob | null {
  const folders = vscode.workspace.workspaceFolders;
  if (!folders || folders.length === 0) {
    log("No workspace folder open.");
    return null;
  }

  for (const folder of folders) {
    const candidate = path.join(folder.uri.fsPath, JOB_FILE);
    if (fs.existsSync(candidate)) {
      log(`Found ${JOB_FILE} in: ${folder.uri.fsPath}`);
      return parseJobFile(candidate);
    }
  }

  return null;
}

function parseJobFile(filePath: string): JacCoderJob | null {
  try {
    const raw = fs.readFileSync(filePath, "utf8");
    const job = JSON.parse(raw) as JacCoderJob;
    log(`Parsed job file: ${filePath}`);
    return job;
  } catch (err) {
    log(`ERROR: Could not parse ${JOB_FILE}: ${String(err)}`);
    return null;
  }
}

// ---------------------------------------------------------------------------
// Job workspace handler
// ---------------------------------------------------------------------------

function handleJobWorkspace(job: JacCoderJob): void {
  const appName = job.build_spec?.app_name ?? job.slug ?? "unknown";
  const language = job.build_spec?.language ?? "jac";
  const entryPoint = job.build_spec?.entry_point ?? "main.jac";
  const features = job.build_spec?.features ?? [];
  const launchedAt = job._meta?.launched_at ?? "unknown";
  const launcherVersion = job._meta?.launcher_version ?? "unknown";

  log("─────────────────────────────────────────");
  log("JacCoder Job Workspace Detected");
  log("─────────────────────────────────────────");
  log(`  Job ID        : ${job.id}`);
  log(`  App Name      : ${appName}`);
  log(`  Slug          : ${job.slug}`);
  log(`  Language      : ${language}`);
  log(`  Entry Point   : ${entryPoint}`);
  log(`  Features      : ${features.length > 0 ? features.join(", ") : "none specified"}`);
  log(`  Launched At   : ${launchedAt}`);
  log(`  Launcher Ver  : ${launcherVersion}`);
  log("─────────────────────────────────────────");

  if (job.prompt) {
    const preview = job.prompt.length > 120
      ? job.prompt.slice(0, 120) + "…"
      : job.prompt;
    log(`  Prompt preview: ${preview}`);
    log("─────────────────────────────────────────");
  }

  out.show(/* preserveFocus */ true);

  vscode.window.showInformationMessage(
    `JacCoder: workspace ready for "${appName}" (job ${job.id}). See Output › ${CHANNEL_NAME}.`
  );

  const discovered = discoverJacCoderExtension();
  if (discovered) {
    logExtensionMetadata(discovered);
    void tryTriggerJacCoder(discovered, job);
  } else {
    log("JacCoder extension not found — cannot auto-trigger.");
    log("Install the JacCoder extension and reload the window to enable auto-trigger.");
  }
}

// ---------------------------------------------------------------------------
// Extension discovery
// ---------------------------------------------------------------------------

function discoverJacCoderExtension(): DiscoveredExtension | null {
  log("─────────────────────────────────────────");
  log("Scanning installed extensions for JacCoder…");

  const all = vscode.extensions.all;
  log(`Total installed extensions: ${all.length}`);

  const candidates: DiscoveredExtension[] = [];

  for (const ext of all) {
    const id = ext.id.toLowerCase();
    const displayName = (
      (ext.packageJSON as { displayName?: string }).displayName ?? ""
    ).toLowerCase();

    let score = 0;
    JACCODER_ID_KEYWORDS.forEach((kw, idx) => {
      if (id.includes(kw) || displayName.includes(kw)) {
        score += Math.max(10 - idx, 1);
      }
    });

    if (score === 0) { continue; }

    const commands = extractContributedCommands(ext);
    candidates.push({ ext, score, commands });
  }

  if (candidates.length === 0) {
    log("No candidate extensions matched the JacCoder keyword list.");
    log(`Keywords searched: ${JACCODER_ID_KEYWORDS.join(", ")}`);
    return null;
  }

  candidates.sort((a, b) => b.score - a.score);

  log(`Found ${candidates.length} candidate extension(s):`);
  candidates.forEach((c, i) => {
    log(`  [${i + 1}] ${c.ext.id}  score=${c.score}  commands=${c.commands.length}`);
  });

  return candidates[0];
}

function extractContributedCommands(ext: vscode.Extension<unknown>): string[] {
  try {
    const pkg = ext.packageJSON as {
      contributes?: { commands?: Array<{ command: string; title?: string }> };
    };
    return (pkg.contributes?.commands ?? []).map((c) => c.command);
  } catch {
    return [];
  }
}

// ---------------------------------------------------------------------------
// Metadata logging
// ---------------------------------------------------------------------------

function logExtensionMetadata(found: DiscoveredExtension): void {
  const pkg = found.ext.packageJSON as Record<string, unknown>;

  log("─────────────────────────────────────────");
  log("JacCoder Extension — Metadata");
  log("─────────────────────────────────────────");
  log(`  Extension ID  : ${found.ext.id}`);
  log(`  Display Name  : ${String(pkg.displayName ?? "—")}`);
  log(`  Version       : ${String(pkg.version ?? "—")}`);
  log(`  Publisher     : ${String(pkg.publisher ?? "—")}`);
  log(`  Description   : ${String(pkg.description ?? "—")}`);
  log(`  Active        : ${found.ext.isActive}`);
  log(`  Install path  : ${found.ext.extensionPath}`);
  log(`  Discovery score: ${found.score}`);
  log("─────────────────────────────────────────");

  if (found.commands.length === 0) {
    log("  Contributed commands: none found in package.json");
  } else {
    log(`  Contributed commands (${found.commands.length}):`);
    found.commands.forEach((cmd) => log(`    • ${cmd}`));
  }

  log("─────────────────────────────────────────");
}

// ---------------------------------------------------------------------------
// Command execution — direct attempts then AppleScript fallback
// ---------------------------------------------------------------------------

async function tryTriggerJacCoder(
  found: DiscoveredExtension,
  job: JacCoderJob
): Promise<void> {
  const ranked = rankCommandsForOpenIntent(found.commands);
  const fallbacks = buildFallbackCommands(found.ext.id);
  const toTry: string[] = [
    ...ranked,
    ...fallbacks.filter((f) => !ranked.includes(f)),
  ];

  if (toTry.length === 0) {
    log("No command candidates to attempt — skipping direct trigger.");
  } else {
    log("─────────────────────────────────────────");
    log("Attempting to trigger JacCoder (direct)…");
    log(`  Commands to try (${toTry.length}), in order:`);
    toTry.forEach((cmd, i) => log(`    [${i + 1}] ${cmd}`));
    log("─────────────────────────────────────────");

    const prompt = job.prompt ?? "";

    for (const cmd of toTry) {
      const succeeded = await attemptCommand(cmd, prompt);
      if (succeeded) {
        log(`✓ Successfully triggered: ${cmd}`);
        vscode.window.showInformationMessage(
          `JacCoder auto-triggered via "${cmd}".`
        );
        return; // done — no fallback needed
      }
    }

    log("✗ All direct command attempts failed.");
  }

  // ── AppleScript fallback ─────────────────────────────────────────────────
  await runAppleScriptFallback(found, job);
}

function rankCommandsForOpenIntent(commands: string[]): string[] {
  const score = (cmd: string): number => {
    const lower = cmd.toLowerCase();
    for (let i = 0; i < OPEN_INTENT_PATTERNS.length; i++) {
      if (lower.includes(OPEN_INTENT_PATTERNS[i])) {
        return OPEN_INTENT_PATTERNS.length - i;
      }
    }
    return 0;
  };
  return [...commands].sort((a, b) => score(b) - score(a));
}

function buildFallbackCommands(extensionId: string): string[] {
  const prefix = extensionId.split(".")[1] ?? extensionId;
  const claudePatterns = [
    "claude.openChat", "claude.newChat", "claude.startSession",
    "claude-code.openChat", "claude-code.newChat", "claude-code.focus",
    "claude-code.openPanel", "anthropic.openChat", "anthropic.newSession",
  ];
  const derived = [
    `${prefix}.openChat`, `${prefix}.newChat`, `${prefix}.newSession`,
    `${prefix}.openPanel`, `${prefix}.focus`, `${prefix}.start`,
  ];
  return [...derived, ...claudePatterns];
}

async function attemptCommand(commandId: string, prompt: string): Promise<boolean> {
  log(`  → Trying: ${commandId}`);
  try {
    await vscode.commands.executeCommand(commandId, prompt);
    return true;
  } catch {
    try {
      await vscode.commands.executeCommand(commandId);
      return true;
    } catch (errNoArg) {
      log(`    ✗ Failed: ${String(errNoArg)}`);
      return false;
    }
  }
}

// ---------------------------------------------------------------------------
// AppleScript fallback
// ---------------------------------------------------------------------------

/**
 * Invoke focus_and_paste.applescript via osascript.
 * Only attempted on macOS; silently skipped on other platforms.
 */
async function runAppleScriptFallback(
  found: DiscoveredExtension,
  job: JacCoderJob
): Promise<void> {
  log("─────────────────────────────────────────");
  log("AppleScript fallback — evaluating…");

  // ── Guard: macOS only ────────────────────────────────────────────────────
  if (os.platform() !== "darwin") {
    log("Platform is not macOS — AppleScript fallback skipped.");
    log("Manual action: open JacCoder and paste the contents of PROMPT.md.");
    return;
  }

  // ── Locate the AppleScript ───────────────────────────────────────────────
  const scriptPath = resolveAppleScriptPath();
  if (!scriptPath) {
    log("ERROR: focus_and_paste.applescript not found.");
    log(`Searched relative to extension path: ${ctxExtensionPath}`);
    log("Manual action: open JacCoder and paste the contents of PROMPT.md.");
    return;
  }
  log(`AppleScript path : ${scriptPath}`);

  // ── Locate PROMPT.md ─────────────────────────────────────────────────────
  const promptFilePath = resolvePromptFilePath();
  if (!promptFilePath) {
    log("ERROR: PROMPT.md not found in any open workspace folder.");
    log("Manual action: open JacCoder and paste the job prompt manually.");
    return;
  }
  log(`PROMPT.md path   : ${promptFilePath}`);

  // ── Build Command Palette query ──────────────────────────────────────────
  const paletteQuery = derivePaletteQuery(found);
  log(`Palette query    : ${paletteQuery}`);

  // ── Run osascript ────────────────────────────────────────────────────────
  log("Invoking osascript…");
  log(`  osascript "${scriptPath}" "${promptFilePath}" "${paletteQuery}"`);

  return new Promise((resolve) => {
    execFile(
      "osascript",
      [scriptPath, promptFilePath, paletteQuery],
      { timeout: 30_000 },
      (err, stdout, stderr) => {
        if (stderr) {
          // AppleScript log() writes to stderr — surface every line
          stderr.split("\n").filter(Boolean).forEach((line) => log(`  [AS] ${line}`));
        }
        if (stdout.trim()) {
          log(`  [AS stdout] ${stdout.trim()}`);
        }

        if (err) {
          log(`✗ AppleScript exited with error: ${String(err)}`);
          log("  Check: Accessibility & Automation permissions in System Preferences.");
          vscode.window.showWarningMessage(
            "JacCoder companion: AppleScript fallback failed — see Output › JacCoder for details."
          );
        } else {
          log("✓ AppleScript fallback completed successfully.");
          vscode.window.showInformationMessage(
            `JacCoder: prompt submitted via AppleScript fallback for job ${job.id}.`
          );
        }

        resolve();
      }
    );
  });
}

/**
 * The AppleScript lives at  <extensionPath>/../../launcher/focus_and_paste.applescript
 * i.e. two directories up from companion_extension/ → back to automation/ → into launcher/.
 *
 * When sideloaded via symlink this resolves correctly.
 * Returns null if the file cannot be found.
 */
function resolveAppleScriptPath(): string | null {
  const candidate = path.resolve(
    ctxExtensionPath,
    "..",         // automation/
    "launcher",
    "focus_and_paste.applescript"
  );
  log(`Checking for AppleScript at: ${candidate}`);
  return fs.existsSync(candidate) ? candidate : null;
}

/**
 * Find PROMPT.md in the first workspace folder that has one.
 */
function resolvePromptFilePath(): string | null {
  const folders = vscode.workspace.workspaceFolders ?? [];
  for (const folder of folders) {
    const candidate = path.join(folder.uri.fsPath, "PROMPT.md");
    if (fs.existsSync(candidate)) {
      return candidate;
    }
  }
  return null;
}

/**
 * Map the discovered extension's ID keywords to a sensible Command Palette
 * query string.  Logs the decision process so it can be debugged.
 */
function derivePaletteQuery(found: DiscoveredExtension): string {
  const id = found.ext.id.toLowerCase();

  for (const [keyword, queries] of Object.entries(PALETTE_QUERY_CANDIDATES)) {
    if (id.includes(keyword)) {
      const chosen = queries[0];
      log(`Palette query derived from keyword "${keyword}": "${chosen}"`);
      log(`  Alternatives: ${queries.slice(1).join(", ") || "none"}`);
      return chosen;
    }
  }

  // Last resort: use the display name from the extension's package.json
  const displayName = String(
    (found.ext.packageJSON as Record<string, unknown>).displayName ?? found.ext.id
  );
  const fallback = `${displayName}: New Session`;
  log(`Palette query: no keyword matched — using fallback: "${fallback}"`);
  return fallback;
}

// ---------------------------------------------------------------------------
// Logging helper
// ---------------------------------------------------------------------------
function log(message: string): void {
  const ts = new Date().toISOString().replace("T", " ").slice(0, 19);
  out.appendLine(`[${ts}] ${message}`);
}
