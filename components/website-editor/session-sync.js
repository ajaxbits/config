// Each new top-level OpenCode chat is one editing session. Before its first
// prompt is admitted, move the checkout onto the latest published main. If
// that is refused (earlier edits were never published), the agent loses its
// tools until the user answers, so it has to ask instead of carrying on.
import { execFile } from "node:child_process";
import { promisify } from "node:util";

const run = promisify(execFile);
const repo = "@repo@";
const sync = "@sync@";

export default {
  id: "grace-editor.session-sync",
  async setup(ctx) {
    if (ctx.location.directory !== repo) return;
    // Persisted so a server restart neither re-syncs an ongoing chat nor
    // forgets that it is waiting for an answer.
    const key = (sessionID) => "session:" + sessionID;

    await ctx.session.hook("prompt", async (event) => {
      const state = await ctx.storage.get(key(event.sessionID));
      if (state?.status === "waiting") {
        // This prompt is the user's answer.
        await ctx.storage.set(key(event.sessionID), { ...state, status: "answered" });
        return;
      }
      if (state !== undefined) return;
      const session = await ctx.session.get({ sessionID: event.sessionID });
      if (session.parentID) return; // subagent chats belong to their parent's session
      await ctx.storage.set(key(event.sessionID), { status: "syncing" });
      try {
        await run(sync, [], { timeout: 15 * 60 * 1000 });
        await ctx.storage.set(key(event.sessionID), { status: "ok" });
      } catch (error) {
        const reason = [error.stdout, error.stderr].filter(Boolean).join("\n").trim() || String(error);
        await ctx.storage.set(key(event.sessionID), { status: "waiting", reason });
      }
    });

    await ctx.session.hook("context", async (event) => {
      const state = await ctx.storage.get(key(event.sessionID));
      if (state?.status === "waiting") {
        for (const tool of Object.keys(event.tools)) delete event.tools[tool];
        event.system.push({
          type: "text",
          text:
            "This chat did NOT start from the latest published website, because the automatic " +
            "sync did not run:\n\n" + state.reason + "\n\nYour tools are switched off until the " +
            "user answers. Do not start on their request. In plain words, explain this in one " +
            "sentence, then ask them to choose: publish the earlier edits, throw them away and " +
            "start from the live site, or keep working on top of them. Then stop.",
        });
      } else if (state?.status === "answered") {
        await ctx.storage.set(key(event.sessionID), { ...state, status: "done" });
        event.system.push({
          type: "text",
          text:
            "You asked the user what to do with earlier unpublished edits (" + state.reason +
            "). Their latest message is the answer. Act on it first, as your instructions say; " +
            "if it is unclear, ask again. Then continue with their original request.",
        });
      }
    });
  },
};
