<p align="center">
  <img src="https://capsule-render.vercel.app/api?type=waving&color=0:7dd3fc,100:8b5cf6&height=180&section=header&text=AnalyticsWithSushil&fontSize=52" alt="AnalyticsWithSushil banner" />
</p>

<p align="center">
  <a href="https://github.com/sushil6666/AnalyticsWithSushil/stargazers"><img src="https://img.shields.io/github/stars/sushil6666/AnalyticsWithSushil?style=for-the-badge&color=F97316" alt="GitHub stars" /></a>
  <a href="https://github.com/sushil6666/AnalyticsWithSushil/network/members"><img src="https://img.shields.io/github/forks/sushil6666/AnalyticsWithSushil?style=for-the-badge&color=22C55E" alt="GitHub forks" /></a>
  <a href="https://github.com/sushil6666/AnalyticsWithSushil/issues"><img src="https://img.shields.io/github/issues/sushil6666/AnalyticsWithSushil?style=for-the-badge&color=EF4444" alt="GitHub issues" /></a>
  <a href="https://github.com/sushil6666/AnalyticsWithSushil/pulls"><img src="https://img.shields.io/github/issues-pr/sushil6666/AnalyticsWithSushil?style=for-the-badge&color=8B5CF6" alt="GitHub pull requests" /></a>
  <a href="LICENSE.txt"><img src="https://img.shields.io/badge/license-MIT-8B5CF6?style=for-the-badge" alt="MIT License" /></a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/dbt-FF694B?style=for-the-badge&logo=dbt&logoColor=white" alt="dbt" />
  <img src="https://img.shields.io/badge/Snowflake-29B5E8?style=for-the-badge&logo=snowflake&logoColor=white" alt="Snowflake" />
  <img src="https://img.shields.io/badge/SQL-4479A1?style=for-the-badge&logo=postgresql&logoColor=white" alt="SQL" />
  <img src="https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white" alt="Python" />
</p>

<p align="center">
  <img src="https://readme-typing-svg.herokuapp.com?font=Fira+Code&size=18&pause=1000&color=7DD3FC&center=true&vCenter=true&width=650&lines=Data+driven.+Insight+led.+Action+focused.;dbt+%2B+Snowflake+analytics+engineering+demos.;Built+by+Sushil+Behera." alt="Typing SVG" />
</p>

<h1 align="center">AnalyticsWithSushil</h1>

<p align="center">
  A hands on analytics engineering repository showcasing production style <strong>dbt</strong> and <strong>Snowflake</strong> patterns,
  built to demonstrate real problems (data quality, alerting, error handling) with real, runnable solutions.
</p>

---

## 📖 Table of contents

- [About this project](#-about-this-project)
- [Featured demo: on_error_continue](#-featured-demo-on_error_continue-payment-feed)
- [Repository structure](#-repository-structure)
- [Tech stack](#️-tech-stack)
- [Getting started](#-getting-started)
- [Contributing](#-contributing)
- [About me](#-about-me)
- [Connect](#-connect)
- [License](#-license)

## ✨ About this project

`AnalyticsWithSushil` is where I build and document analytics engineering work end to end, not just queries, but the
operational concerns that come with running dbt in production: data quality gates, alerting strategy, incident
auditing, and notification design.

Each demo in this repo is:

- **Self-contained**: seeded data, models, macros, and tests you can run immediately with no external dependencies.
- **Documented**: a dedicated `README.md` and demo guide walk through exactly what to run and what to expect.
- **Realistic**: modeled on problems analytics engineers actually hit (malformed source data, silent pipeline
  failures, alert fatigue), not toy examples.

## 🚦 Featured demo: `on_error_continue` payment feed

The flagship demo lives in [`models/on_error_continue_demo/`](models/on_error_continue_demo) and shows how to keep a
pipeline delivering data and surface data quality incidents, without one blocking the other.

**What it demonstrates:**

- **`on_error: continue`** on a Snowflake load so a single malformed row doesn't take down the whole batch.
- **Safe vs. strict parsing** (`TRY_TO_DECIMAL` vs. `TO_DECIMAL`), toggled with a project var, to compare graceful
  degradation against hard failure.
- **A dedicated review queue model** that reads the raw seed directly, so alert evidence stays current even if the
  validator itself fails.
- **An incident audit model** that declares its DAG dependency without querying the (possibly broken) validator.
- **Two job alerting pattern**: a delivery job that can succeed with a warning, and a separate monitoring job that
  promotes that warning to a job level error for Slack/email routing, so alerting logic never blocks delivery.

Start here: [`models/on_error_continue_demo/README.md`](models/on_error_continue_demo/README.md) for the full
walkthrough, and [`DEMO_GUIDE.md`](models/on_error_continue_demo/DEMO_GUIDE.md) for a presenter style script.

```bash
dbt seed --select on_error_continue_payment_events
dbt build --select on_error_continue_payment_events+
```

Expected result: **26 passed, 1 warned, 0 failed.**

## 🧩 Repository structure

```text
AnalyticsWithSushil/
├── models/
│   └── on_error_continue_demo/     # payment feed quality & alerting demo
│       ├── on_error_continue_payment_validation.sql
│       ├── on_error_continue_payment_review_queue.sql
│       ├── on_error_continue_incident_audit.sql
│       ├── on_error_continue_feed_quality.sql
│       ├── schema.yml / groups.yml
│       ├── README.md
│       └── DEMO_GUIDE.md
├── macros/
│   └── on_error_continue_demo/     # feed policy macro & custom generic test
├── seeds/
│   └── on_error_continue_demo/     # seeded payment events (incl. bad rows)
├── dbt_project.yml
├── LICENSE.txt
└── README.md
```

## 🛠️ Tech stack

| Layer                    | Tool                                        |
| ------------------------- | -------------------------------------------- |
| Transformation             | [dbt](https://www.getdbt.com/) (v2 Stable)  |
| Warehouse                  | [Snowflake](https://www.snowflake.com/)     |
| Orchestration & alerting   | dbt Platform jobs, Slack & email notifications |
| Language                   | SQL, Jinja, Python                          |

## 🚀 Getting started

```bash
git clone https://github.com/sushil6666/AnalyticsWithSushil.git
cd AnalyticsWithSushil

dbt deps
dbt seed --select on_error_continue_payment_events
dbt build --select on_error_continue_payment_events+
```

From there, follow [`models/on_error_continue_demo/README.md`](models/on_error_continue_demo/README.md) to walk
through strict validation failures, Jinja warning/error modes, and the Slack/email alerting setup.

## 🤝 Contributing

Contributions, ideas, and improvements are welcome, especially new demos that showcase analytics engineering
patterns worth sharing. `main` is protected: nothing lands there without a pull request, a passing CI run, and an
approving review, so open changes safely rather than pushing straight to it.

**Workflow:**

1. Fork the repository (or branch directly if you have write access)
2. Create a feature branch off `main`, named `feat/`, `fix/`, `refactor/`, `docs/`, `test/`, or `chore/` followed by
   a short, specific slug, for example `feat/customer-ltv-demo`
3. Commit your changes using [Conventional Commits](https://www.conventionalcommits.org/) (`feat:`, `fix:`, `docs:`,
   and so on); the PR title is checked against the same convention
4. Run `dbt build` locally against your own dev schema before opening a PR
5. Push your branch and open a pull request against `main` using the PR template; fill in the validation section
   with real `dbt build`/`dbt test` output, not a placeholder
6. For a forked PR, static checks run without secrets. A maintainer must review the code and recreate the approved
   commits on a trusted branch in this repository before warehouse-backed CI can run
7. Address CI failures and reviewer feedback; once required checks pass and a code owner approves, the PR can merge


**What gates a merge:**

- **Required status checks** (see [`.github/workflows/ci.yml`](.github/workflows/ci.yml)): YAML lint, SQL lint
  (`sqlfluff`, config in [`.sqlfluff`](.sqlfluff)), a conventional PR title check, and a dbt Platform build using
  the project's dbt v2 Stable engine against Snowflake.

- **A dbt Platform CI job** (`CI - pull request checks`, configured in dbt Cloud, not in this repo) that runs
  `dbt build --select state:modified+` against a real, ephemeral Snowflake schema deferred to `stg_env`. This
  account's plan doesn't expose dbt Platform's native "Triggered by pull requests" webhook, so the
  `dbt-platform-ci` job in [`ci.yml`](.github/workflows/ci.yml) triggers it via the Admin API instead and polls
  until it finishes, surfacing the result as a normal GitHub status check. The `Trusted branch policy` check blocks
  forked PRs before secrets or warehouse execution are exposed.

- **Code owner review**: [`.github/CODEOWNERS`](.github/CODEOWNERS) requires an approval from a maintainer on every
  PR, and branch protection is configured to dismiss stale approvals when new commits are pushed.
- **No direct pushes to `main`** and no force-pushes; history stays linear and reviewable.

Merging to `main` triggers [`.github/workflows/cd.yml`](.github/workflows/cd.yml), which kicks off the production
dbt Platform job so deployment is automatic once a PR is approved and merged, not a manual follow-up step.

> **Repo admin setup note:** GitHub branch protection rules and repository secrets are account/repo-settings
> changes that have to be made once by hand; see the checklist below.

<details>
<summary><strong>One-time repo admin checklist</strong> (click to expand)</summary>

In **GitHub → Settings → Branches → Branch protection rules** (or Rulesets) for `main`:

- Require a pull request before merging; require at least 1 approval; require review from Code Owners
- Dismiss stale pull request approvals when new commits are pushed
- Require status checks to pass before merging, and select the displayed check names: `Lint YAML`,
  `Lint SQL (sqlfluff)`, `Conventional PR title`, `Trusted branch policy`,
  `dbt Platform CI (build + test)`, and `Required checks summary` (these only appear in the picker after
  `ci.yml` has run at least once)


- Require branches to be up to date before merging
- Require linear history
- Do not allow force pushes; do not allow deletions
- Apply the rule to administrators too, no bypass (otherwise it's decorative)

In **dbt Platform → Deploy → Jobs**, the `CI - pull request checks` job should have:

- Job type `ci`, in the `stg_env` environment
- `dbt build --select state:modified+` as its command
- Deferral enabled against `stg_env` (required for `state:modified+` to resolve at all)
- Run timeout set explicitly (e.g. `1800` seconds); don't leave it at the 24-hour default
- Native "Triggered by pull requests" left off (unavailable on this plan); `ci.yml` calls it via API instead

In **GitHub → Settings → Secrets and variables → Actions**, add:

- `DBT_CLOUD_API_TOKEN`: an account-scoped dbt Platform personal access token created under
  **Account Settings → API tokens → Personal tokens** for account `70506183163940`. The workflows send it with
  the documented `Bearer` authorization scheme. It is used by both [`cd.yml`](.github/workflows/cd.yml) (trigger
  the production run on merge) and the `dbt-platform-ci` job in [`ci.yml`](.github/workflows/ci.yml) (trigger and
  poll the CI job per PR). Do not use a GitHub PAT or a Semantic Layer-only dbt service token.

No Snowflake credentials are needed in GitHub. Static linting runs without warehouse access, and the real parse,
build, and test run executes inside dbt Platform using the project's dbt v2 Stable engine and centrally managed
Snowflake credentials.



</details>



## 👋 About me

Hi, I'm **Sushil Behera**, an analytics engineer who works at the intersection of data modeling, warehouse
engineering, and pipeline reliability. This repo is my public workspace for turning day to day analytics engineering
problems into clear, reproducible demos.

I care about pipelines that fail loudly in the right places and quietly in the wrong ones. That's the thinking
behind the `on_error_continue` demo above, and the lens I bring to most of the work here: build things that are
transparent when they break, and honest about the tradeoffs behind every "safe" default.

If you're exploring dbt on Snowflake, thinking through alerting strategy, or just want to compare notes on analytics
engineering practices, feel free to reach out using any of the channels below.

## 📬 Connect

<p align="left">
  <a href="mailto:analyticswithsushil@gmail.com"><img src="https://img.shields.io/badge/Email-D14836?style=for-the-badge&logo=gmail&logoColor=white" alt="Email" /></a>
  <a href="https://www.linkedin.com/in/sushil-behera/"><img src="https://img.shields.io/badge/LinkedIn-0A66C2?style=for-the-badge&logo=linkedin&logoColor=white" alt="LinkedIn" /></a>
  <a href="https://www.analyticswithsushil.com"><img src="https://img.shields.io/badge/Website-8B5CF6?style=for-the-badge&logo=googlechrome&logoColor=white" alt="Website" /></a>
  <a href="https://github.com/sushil6666/AnalyticsWithSushil"><img src="https://img.shields.io/badge/Repository-181717?style=for-the-badge&logo=github&logoColor=white" alt="Repository" /></a>
</p>

| | |
| --- | --- |
| ✉️ Email | [analyticswithsushil@gmail.com](mailto:analyticswithsushil@gmail.com) |
| 🌐 Website | [analyticswithsushil.com](https://www.analyticswithsushil.com) |
| 💼 LinkedIn | [sushil-behera](https://www.linkedin.com/in/sushil-behera/) |
| 💻 Repository | [AnalyticsWithSushil](https://github.com/sushil6666/AnalyticsWithSushil) |

## 📄 License

This project is licensed under the [MIT License](LICENSE.txt), copyright (c) 2026 Analytics with Sushil.

<p align="center">
  <img src="https://capsule-render.vercel.app/api?type=soft&color=0:0ea5e9,100:8b5cf6&height=90&section=footer&text=Built%20for%20insights%20and%20impact&fontSize=24" alt="footer banner" />
</p>

