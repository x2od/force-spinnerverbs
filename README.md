# force-spinnerverbs 🌀

**A community-driven collection of spinner verbs for Claude.**

Ever wondered what Claude is up to while it thinks? It's *Trailblazing*, *Sandboxing*, or *Soql-querying*, of course. This repo is where those verbs live, and anyone can suggest new ones, rename old ones, or retire the ones that don't spark joy.

Every verb is a little joke about the Salesforce world, so if you've ever watched a deploy crawl or a flow debug itself at 2 a.m., you're in the right place.

## Add it to your Claude

Claude Code reads spinner verbs from the `spinnerVerbs` setting. It works in any settings file, and this repo's [`forceSpinning.json`](forceSpinning.json) has the block ready to go. The setting is documented in the [settings reference](https://code.claude.com/docs/en/settings-reference#spinnerverbs).

### Option 1: Copy and paste

1. Open [`forceSpinning.json`](forceSpinning.json) and copy the whole `spinnerVerbs` object.
2. Open `~/.claude/settings.json` and paste it in as a top-level key. If the file already has other settings, add a comma after the last existing key.
3. Save the file. The next spinner picks up the new verbs without a restart.

### Option 2: One command (macOS / Linux)

This needs `jq` installed. It backs up your settings, then merges the verbs in and leaves your other settings alone:

```bash
mkdir -p ~/.claude
[ -f ~/.claude/settings.json ] || echo '{}' > ~/.claude/settings.json
cp ~/.claude/settings.json ~/.claude/settings.backup.json
curl -fsSL https://raw.githubusercontent.com/x2od/force-spinnerverbs/main/forceSpinning.json \
  | jq -s '.[0] * .[1]' ~/.claude/settings.json - > ~/.claude/settings.new.json \
  && mv ~/.claude/settings.new.json ~/.claude/settings.json \
  || { rm -f ~/.claude/settings.new.json; echo "Install failed. Your settings are unchanged." >&2; }
```

If anything fails, your settings file is left as it was. A copy of the previous version is also saved as `~/.claude/settings.backup.json`.

### Verify what gets installed

Want to see exactly what this script installs before running it? View the [`forceSpinning.json` file on GitHub](https://raw.githubusercontent.com/x2od/force-spinnerverbs/main/forceSpinning.json). The file is read-only and contains only spinner verb names—nothing malicious or unexpected.

### Replace or append?

The file uses `"mode": "append"`, so these verbs are added alongside Claude's built-in verbs. If you want only our verbs, change the mode to `"replace"`:

```json
"spinnerVerbs": {
  "mode": "append",
  "verbs": [ "..." ]
}
```

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
