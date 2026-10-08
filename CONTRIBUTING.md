# Contributing to force-spinnerverbs

Thanks for helping choose the spinner verbs! All verbs live in [`forceSpinning.json`](forceSpinning.json). Changes arrive as pull requests, and a code owner must approve each one before it merges to `main`.

## The rules

A PR is checked automatically by the **Validate spinner verbs** check. Every commit in your PR that touches `forceSpinning.json` must follow all of these rules:

1. **Wrapper lines stay the same.** The first four lines and the last three lines of the file must match the original exactly:
   ```
   {
     "spinnerVerbs": {
       "mode": "replace" or "append",
       "verbs": [
   ...
       ]
     }
   }
   ```
2. **Valid JSON.** The file must parse, and `spinnerVerbs.verbs` must be an array.
3. **Letters, digits, and hyphens only.** Replace spaces with hyphens: `Data-loader-exporting`, not `Data loader exporting`. No other punctuation, underscores, or accents.
4. **Start with a capital letter.** The first character of each verb must be `A`–`Z`. Other letters can be any case, so `Flow-Debugging` is fine.
5. **End in `ing`.** Each verb must end in lowercase `ing`, as in `Sandboxing`.
6. **No duplicates.** Duplicates are checked without regard to case, so `Apex-compiling` and `apex-compiling` count as the same verb.
7. **Alphabetical order.** Verbs must be sorted case-insensitively, A to Z. A new verb goes wherever it sorts.

Examples:

| Verb | Result | Why |
| --- | --- | --- |
| `Lead-converting` | ✅ | Capitalized, hyphenated, ends in `ing` |
| `Flow-Debugging` | ✅ | Only the first letter is checked for case |
| `Lead converting` | ❌ | Contains a space |
| `lead-converting` | ❌ | First letter is not capitalized |
| `Lead-convert` | ❌ | Does not end in `ing` |
| `Sand_boxing` | ❌ | Underscore is not allowed |
| `Apex-compiling` and `apex-compiling` | ❌ | Duplicates |

## How to sort the list

Running this from the repo root keeps the file sorted and formatted the same way:

```bash
jq '.spinnerVerbs.verbs |= sort_by(ascii_downcase)' forceSpinning.json > sorted.json && mv sorted.json forceSpinning.json
```

## Opening a pull request

1. Fork the repo and create a branch.
2. Make your change to `forceSpinning.json`. You do not need a linked issue.
3. Open a PR and fill in the template. Explain what you added, changed, or removed, and why.
4. Wait for the **Validate spinner verbs** check. A comment on your PR lists any problems, and it updates on each push. Fix the problems and push again.
5. A code owner will review your PR. Code owners are listed in [`.github/CODEOWNERS`](.github/CODEOWNERS).

You do not need to be quick about fixing rule violations. Every commit is checked, so a bad commit stays flagged until a later commit fixes the file. Squashing your PR into one clean commit is the easiest way to remove old problems.

## Feedback and complaints

- Feature ideas: open a **Feature request** issue.
- A verb you have a problem with: open a **Complaint** issue and list the verb or verbs.

## Licensing of contributions

By submitting a pull request or issue, you agree that your contribution is licensed under the terms in [LICENSE](LICENSE).
