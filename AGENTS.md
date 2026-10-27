# Stick development instructions

Stick helps people rotate through their interests with one daily focus.
Read README.md and development-notes.md before working. Keep confirmed
requirements separate from proposed product choices.

Keep README.md focused on setup, architecture, functionality, tests, and
technical limitations. Do not include timelines, delivery milestones, decision
history, learning assessments, blog plans, or review workflow in the README.

Render the illustrated world with SpriteKit beneath native SwiftUI controls.
Keep app state and navigation outside the scene. The transition to Focus Flower
is daily usability with ordered interests, a stable daily topic, an animated
home scene, and one reminder; blog publication and App Store release can follow.

Keep current work, validation, limitations, and pending review state in
`development-notes.md`. Preserve unrelated changes. Never push without
authorization.

## Learning hub

This public app is checked out at apps/stick-app in the private swifty-apple
hub. Read hub instructions for context, but keep app work within this app
repository. The only permitted writes outside it are automatic notes under
the hub's `notes/<track>/auto/` directories.

Do not update the hub's cycles, knowledge ledger, decision log, question log,
app index, submodule pointer, or any other outer file as part of app work.
Do not make hub commits for app approvals or merges. Keep implementation
progress, decisions, validation, and review state in this app's development
notes; automatic learning notes may use the permitted notes directories.

For Swift/iOS learning work, finish with the user explaining the main
decision and a failure case. Keep any learning observations in the app's
development notes or permitted automatic notes; a completed PR alone does
not establish mastery.

Run checks relevant to changed behavior. Run Swift tests when Swift source,
Swift tests, or Package.swift change. Verify Apple API claims against primary
Apple documentation, WWDC, Swift Evolution, or official samples.
