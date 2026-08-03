---
name: actionable
description: "Extract only the steps a human has to do personally from a wall of text, output, or long explanation."
disable-model-invocation: true
---

# Actionable

Reduce something long to the short list of things the **user personally** has to do. Everything else is noise or is your job.

Typical triggers: a long build/deploy explanation, a README, a migration guide, an error dump, a spec, or your own previous answer that ran long.

## Source

- No argument: the immediately preceding content in this conversation.
- A file path or URL: that content.
- Pasted text after the command: that text.

## The filter

An item makes the list only if it needs a human. Almost always that means one of:

- A credential, key, or secret the user must obtain or paste
- A click in a web console the user is logged into (Vercel, Porter, Cloudflare, Stripe, a cloud provider)
- A purchase, plan upgrade, quota increase, or billing change
- An approval, signature, invite, or permission grant
- A physical or account action (plug in a device, verify an email, enable 2FA)
- A decision only the user can make, where you genuinely cannot pick a default

Everything else — installing packages, editing config, running migrations, writing code, starting a local service — is **yours**. It does not go on the user's list.

## Verify before listing

Check each candidate against reality before you print it. Most of the value is in the items you *remove*.

- Env var: grep `.env`, `.env.local`, the deploy config. Already set? Drop it.
- Service to run: check whether it's already listening (`lsof -nP -iTCP -sTCP:LISTEN`) or already in compose.
- Package or CLI: check whether it's installed.
- File to create: check whether it exists.

If a check needs a command you can just run, run it. Never list something you haven't confirmed is actually outstanding, and never pad the list with steps from the source that don't apply here.

## Output

Terse. Numbered. Ordered so nothing blocks the next thing. No preamble, no restating what the source said, no closing summary.

Each item is one imperative line, plus — only when needed — the exact place and the exact value on its own line:

```
1. Add ANTHROPIC_API_KEY to Vercel (marquee → Settings → Environment Variables, all envs)
2. Create the Discord webhook and send me the URL
   Server Settings → Integrations → Webhooks → New
3. Upgrade the Neon plan to Scale — the branch limit is the blocker
```

Make values paste-ready. If a command is the fastest path, give the exact command, not a description of it.

Then, if there are things you can do yourself, one line:

```
I can handle the rest (install deps, wire the client, run the migration) — say go.
```

If nothing needs the user, say so in one line and stop:

```
Nothing needs you. I can do all of it — say go.
```

## Length

Under ten items. If the honest list is longer, the work needs splitting into stages — give the first stage's items and name what the next stage covers in one line.

## Common mistakes

- **Listing your own work.** "Install the dependency" is not a human step.
- **Copying the source's structure.** You are replacing it, not summarizing it.
- **Listing things already done.** Check first. A list of already-done items destroys trust in the whole list.
- **Vague placement.** "Set the env var in your hosting provider" — name the provider, the project, and the screen.
- **Explaining why.** Only if the user cannot act without it, and then in a clause, not a paragraph.
- **Adding a recap.** The point is that the user is not reading the long version.
