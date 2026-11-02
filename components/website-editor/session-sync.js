// Each new top-level OpenCode chat is one editing session. Before its first
// prompt is admitted, move the checkout onto the latest published main.
import { execFile } from "node:child_process";
import { promisify } from "node:util";

const run = promisify(execFile);
const repo = "@repo@";
const sync = "@sync@";

export default {
  id: "grace-editor.session-sync",
  async setup(ctx) {
    if (ctx.location.directory !== repo) return;

    await ctx.session.hook("prompt", async (event) => {
      // Persisted so a server restart doesn't re-sync an ongoing chat.
      const key = "session:" + event.sessionID;
      if ((await ctx.storage.get(key)) !== undefined) return;
      const session = await ctx.session.get({ sessionID: event.sessionID });
      if (session.parentID) return; // subagent chats belong to their parent's session
      await ctx.storage.set(key, "syncing");
      try {
        await run(sync, [], { timeout: 15 * 60 * 1000 });
        await ctx.storage.set(key, "ok");
      } catch (error) {
        const output = [error.stdout, error.stderr].filter(Boolean).join("\n").trim();
        await ctx.storage.set(key, output || String(error));
      }
    });

    await ctx.session.hook("context", async (event) => {
      const state = await ctx.storage.get("session:" + event.sessionID);
      if (state === undefined || state === "ok" || state === "syncing") return;
      event.system.push({
        type: "text",
        text:
          "This chat did NOT start from the latest published website, because the automatic sync " +
          "did not run:\n\n" + state + "\n\nIn your first reply, explain this to the user in plain " +
          "words before anything else. If earlier edits were never published, offer to publish or " +
          "discard them; after that, a new chat will start from the live site. Say it once only.",
      });
    });
  },
};
