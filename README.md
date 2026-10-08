# force-spinnerverbs 🌀

**A community-driven collection of spinner verbs for Claude.**

Ever wondered what Claude is up to while it thinks? It's *Trailblazing*, *Sandboxing*, or *Soql-querying*, of course. This repo is where those verbs live, and anyone can suggest new ones, rename old ones, or retire the ones that don't spark joy.

Every verb is a little joke about the Salesforce world, so if you've ever watched a deploy crawl or a flow debug itself at 2 a.m., you're in the right place.

## Add it to your Claude

Claude Code reads spinner verbs from the `spinnerVerbs` setting in `~/.claude/settings.json`. This repo's [`forceSpinning.json`](forceSpinning.json) has that block ready to go.

### Option 1: Copy and paste

1. Open [`forceSpinning.json`](forceSpinning.json) and copy the whole `spinnerVerbs` object.
2. Open `~/.claude/settings.json` and paste it in as a top-level key. If the file already has other settings, add a comma after the last existing key.
3. Save the file. The next spinner picks up the new verbs.

### Option 2: One command (macOS / Linux)

Back up your settings first, then run:

```bash
cp ~/.claude/settings.json ~/.claude/settings.backup.json
curl -fsSL https://raw.githubusercontent.com/x2od/force-spinnerverbs/main/forceSpinning.json \
  | jq -s '.[0] * .[1]' ~/.claude/settings.json - > ~/.claude/settings.new.json \
  && mv ~/.claude/settings.new.json ~/.claude/settings.json
```

This needs `jq` installed. It merges the verbs into your existing settings and leaves the rest alone.

### Replace or append?

The file uses `"mode": "replace"`, so only these verbs show up. If you'd rather keep Claude's built-in verbs and add ours to them, change the mode to `"append"`:

```json
"spinnerVerbs": {
  "mode": "append",
  "verbs": [ "..." ]
}
```

Requires a recent Claude Code version. The `spinnerVerbs` setting is newer and community sources list v2.1.23 or later.

## Contribute a verb

Want to add your favorite? Read [CONTRIBUTING.md](CONTRIBUTING.md) for the rules, which boil down to:

- Capitalized first letter, letters/digits/hyphens only, e.g. `Data-loader-exporting`
- Ends in `ing`
- No duplicates, and keep the list alphabetized

Open a pull request. A bot checks your verbs and comments on your PR with the results, so you'll know right away if something needs fixing.

Got a feature idea or a verb you can't stand? Open an issue using one of the templates.

## Who made this?

Everyone who has had a verb merged. See [CONTRIBUTORS.md](CONTRIBUTORS.md).

## License

Free to use without limit. Credit is required for commercial use and for closed-source use. See [LICENSE](LICENSE).
