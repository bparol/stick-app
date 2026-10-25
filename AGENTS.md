# Stick development instructions

Stick helps people rotate through their interests with one daily focus.
Read README.md and development-notes.md before working. Keep confirmed
requirements separate from proposed product choices.

## Pair programming and review

Use pair programming and small, self-contained increments. Before coding,
agree with the user on one observable outcome, sketch the interface, discuss
the main tradeoff, and set focused acceptance checks. Do not implement an
entire feature autonomously while the user expects to pair. Explain unfamiliar
behavior and pause at useful decisions for the user's reasoning.

Group branches under feature/<feature-name>/. The base branch is
feature/<feature-name>/00-base; iteration branches are
feature/<feature-name>/<descriptive-name>, with iteration names starting
with lowercase letters. Never use a bare feature/<feature-name> branch.

Branch each iteration from the latest approved base. The agent writes the
code, runs relevant checks, and makes a separate local iteration commit.
Explain the change and checks, provide its branch and commit identifier,
then stop for the user's explicit review in the conversation.

Approval authorizes merging that iteration into its base. Merge before
starting the next iteration. On rejection, revise and present it again or
abandon it as directed; leave the base unchanged. Merging the completed
feature into main requires separate user approval. Change the driver only
when requested. Preserve unrelated changes. Never push without authorization.

Keep the current increment, validation, limitations, and pending review in
development-notes.md. Prepare a concise PR description covering the problem,
resulting behavior, validation, and remaining limits.

## Learning hub

This public app is checked out at apps/stick-app in the private swifty-apple
hub. Follow its AGENTS.md when working through that hub. Keep app and hub
commits and pushes separate. After app approval and merge, update the hub's
submodule pointer to the approved app commit.

For Swift/iOS learning work, finish with the user explaining the main
decision and a failure case. Record assessed learning in the hub's current
cycle and ledger; a completed PR alone does not establish mastery.

Run checks relevant to changed behavior. Run Swift tests when Swift source,
Swift tests, or Package.swift change. Verify Apple API claims against primary
Apple documentation, WWDC, Swift Evolution, or official samples.
