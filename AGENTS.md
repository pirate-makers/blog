# Agent instructions

## About page — project lists are hand-curated

`content/about.en.md` and `content/about.fr.md` contain a "Projects" section
(project cards, styled by `static/css/custom.css`). The selection of projects
shown there is **deliberate and manually curated** by the author.

Rules:

- **Never re-add, restore, or regenerate projects that are not already listed
  in the file.** The author removed them on purpose.
- Do not "sync" the lists against GitHub repositories, stars, or any API —
  the file is the single source of truth.
- When editing other parts of the about page, preserve the existing project
  selections, wording, and structure exactly.
- If asked to touch the Projects section at all, re-read the current file
  first and work from that, never from memory or from git history.

Reference — repos that exist on GitHub but were deliberately left OFF the
page (as of 2026-10-25). Do not add them back:

- pirate-makers: `drone-k8test`
- prune998: `argocd-2.10-ssd`, `aws-go-sdk-test`, `blog`, `bloomskyapi`,
  `codingtest`, `devops`, `goHelloGrpcStream`, `google-drive`, `hwfrontend`,
  `IstioTesting`, `piratemakersblog`, `st2influx`, `tenantOperator`,
  `test-argocd`, `ticketmaster`, `vuedash`

(`prune998/influxdb-0.8-0.9-proxy` IS listed under "Selected earlier
projects". Archived repos and forks are naturally excluded too.)
