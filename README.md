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
  A hands-on analytics engineering repository showcasing production-style <strong>dbt</strong> and <strong>Snowflake</strong> patterns,
  with runnable solutions for data quality, alerting, and resilient error handling.
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

`AnalyticsWithSushil` is where I build and document end-to-end analytics engineering patterns—not just queries, but
also the operational concerns that come with running dbt in production: data quality gates, alerting strategy,
incident auditing, and notification design.

Each demo in this repository is:

- **Self-contained**: seeded data, models, macros, and tests you can run immediately without external data dependencies.
- **Documented**: a dedicated `README.md` and demo guide explain what to run and what to expect.
- **Realistic**: modeled on problems analytics engineers encounter in production, including malformed source data,
  pipeline failures, and alert fatigue.

## 🚦 Featured demo: `on_error_continue` payment feed

The flagship demo lives in [`models/on_error_continue_demo/`](models/on_error_continue_demo). It shows how to preserve
useful incident evidence when validation fails, without hiding the original failure.

**What it demonstrates:**

- **`on_error: continue`** allows eligible downstream nodes to keep running after the validator fails.
- **Safe vs. strict parsing** (`TRY_TO_DECIMAL` vs. `TO_DECIMAL`), toggled with a project variable, compares graceful
  degradation with a hard failure.
- **A dedicated review queue model** reads the raw seed directly, keeping alert evidence current even if the validator
  fails before producing a usable relation.
- **An incident audit model** declares the required DAG dependency without querying the potentially failed validator.
- **A two-job alerting pattern** separates delivery from monitoring: the delivery job can succeed with a warning, while
  the monitoring job promotes that warning to a job-level error for Slack or email routing.

Start with [`models/on_error_continue_demo/README.md`](models/on_error_continue_demo/README.md) for the full walkthrough
and [`DEMO_GUIDE.md`](models/on_error_continue_demo/DEMO_GUIDE.md) for a presenter-style script.

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

Thoughtful contributions are welcome when they improve this demo or add a clearly documented analytics engineering
pattern. To keep the repository focused and maintainable, unrelated changes, generated files, credentials, and
unvalidated code will not be accepted.

1. Fork the repository or create a focused feature branch
2. Keep the change limited to one clear purpose
3. Run the relevant `dbt build` and data tests in your own development environment
4. Update the documentation when behavior or setup changes
5. Open a pull request that explains what changed, why it is useful, and how it was validated

Every contribution is reviewed by the repository maintainer before acceptance. Submitting a pull request does not
guarantee that it will be merged.


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

