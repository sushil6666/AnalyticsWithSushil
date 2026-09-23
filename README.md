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
  with runnable solutions for static SQL analysis, data quality, alerting, and resilient error handling.
</p>

---

## 📖 Table of contents

- [About this project](#-about-this-project)
- [Featured demos](#-featured-demos)
- [Repository structure](#-repository-structure)
- [Tech stack](#️-tech-stack)
- [Getting started](#-getting-started)
- [Contributing](#-contributing)
- [About me](#-about-me)
- [Connect](#-connect)
- [License](#-license)

## ✨ About this project

`AnalyticsWithSushil` is where I build and document end-to-end analytics engineering patterns, including queries and
the operational concerns that come with running dbt in production: data quality gates, static analysis, alerting
strategy, incident auditing, and notification design.

Each demo in this repository is:

- **Self-contained**: seeded data, models, and tests you can run immediately, with macros included where needed.
- **Documented**: a dedicated `README.md` and demo guide explain what to run and what to expect.
- **Realistic**: modeled on problems analytics engineers encounter in production, including malformed source data,
  SQL mistakes, pipeline failures, and alert fatigue.

## 🚦 Featured demos

### 1. `on_error_continue` payment feed

The demo in [`models/on_error_continue_demo/`](models/on_error_continue_demo) shows how to preserve useful incident
evidence when validation fails without hiding the original failure.

It covers `on_error: continue`, safe and strict parsing, an independent review queue, incident auditing, warning-level
data tests, and separate delivery and monitoring jobs for Slack or email routing.

```bash
dbt build --select on_error_continue_payment_events+
```

Expected result: **26 passed, 1 warned, 0 failed.**

Read the [walkthrough](models/on_error_continue_demo/README.md) and
[presenter guide](models/on_error_continue_demo/DEMO_GUIDE.md).

### 2. dbt v2 Stable static analysis

This demo shows how dbt catches SQL mistakes before Snowflake runs the query.

It demonstrates two common errors:

- `payment_amunt`, a misspelling of `payment_amount`
- `sqrt(event_timestamp)`, which passes a timestamp to a numeric function

The normal command builds successfully:

```bash
dbt build --select dbt_v2_static_analysis_payment_events+
```

The error modes are activated with a project variable, so the committed project
remains safe by default and can be reset without editing code.

Read the [simple walkthrough](models/dbt_v2_static_analysis_demo/README.md) and
[presenter guide](models/dbt_v2_static_analysis_demo/DEMO_GUIDE.md).

### 3. dbt v2 Stable column-level lineage

This demo shows where each output column comes from.

It follows three small data steps:

```text
dbt_v2_cll_order_items
        ↓
dbt_v2_cll_enriched_order_items
        ↓
dbt_v2_cll_customer_order_summary
```

The first step loads sample order items from a CSV file. The second step
calculates `line_amount` from `quantity * unit_price`. The final step adds the
line amounts together to create `gross_revenue` for each customer.

dbt can trace the full path:

```text
quantity and unit_price
          ↓
      line_amount
          ↓
     gross_revenue
```

Build the demo and ask dbt to record the column connections:

```bash
dbt build --select dbt_v2_cll_order_items+ --write-index --generate-info-schema --static-analysis strict
```

Show the recorded column connections:

```bash
dbt show --info column_lineage --limit 100
```

Read the [beginner walkthrough](models/dbt_v2_column_lineage_demo/README.md) and
[presenter guide](models/dbt_v2_column_lineage_demo/DEMO_GUIDE.md).

## 🧩 Repository structure

```text
AnalyticsWithSushil/
├── models/
│   ├── on_error_continue_demo/
│   │   ├── schema.yml / groups.yml
│   │   ├── README.md
│   │   └── DEMO_GUIDE.md
│   ├── dbt_v2_static_analysis_demo/
│   │   ├── dbt_v2_static_analysis_typed_payments.sql
│   │   ├── dbt_v2_static_analysis_daily_quality.sql
│   │   ├── schema.yml
│   │   ├── README.md
│   │   └── DEMO_GUIDE.md
│   └── dbt_v2_column_lineage_demo/
│       ├── dbt_v2_cll_enriched_order_items.sql
│       ├── dbt_v2_cll_customer_order_summary.sql
│       ├── schema.yml
│       ├── README.md
│       └── DEMO_GUIDE.md
├── macros/
│   └── on_error_continue_demo/
├── seeds/
│   ├── on_error_continue_demo/
│   ├── dbt_v2_static_analysis_demo/
│   └── dbt_v2_column_lineage_demo/
├── dbt_project.yml
├── LICENSE.txt
└── README.md
```

## 🛠️ Tech stack

| Layer                    | Tool                                        |
| ------------------------ | ------------------------------------------- |
| Transformation           | [dbt](https://www.getdbt.com/) (v2 Stable) |
| Warehouse                | [Snowflake](https://www.snowflake.com/)    |
| Orchestration & alerting | dbt Platform jobs, Slack & email notifications |
| Language                 | SQL, Jinja, Python                          |

## 🚀 Getting started

Clone the repository:

```bash
git clone https://github.com/sushil6666/AnalyticsWithSushil.git
cd AnalyticsWithSushil
```

Run the `on_error_continue` demo:

```bash
dbt build --select on_error_continue_payment_events+
```

Then follow its [walkthrough](models/on_error_continue_demo/README.md) to test strict validation, Jinja warning and
error modes, and Slack or email alerting.

Run the dbt v2 Stable static-analysis demo:

```bash
dbt build --select dbt_v2_static_analysis_payment_events+
```

Then follow its [walkthrough](models/dbt_v2_static_analysis_demo/README.md) to test the missing-column and wrong-type
failure modes. The demo defaults to safe behavior.

Run the dbt v2 Stable column-level-lineage demo:

```bash
dbt build --select dbt_v2_cll_order_items+ --write-index --generate-info-schema --static-analysis strict
```

Then follow its [walkthrough](models/dbt_v2_column_lineage_demo/README.md) to inspect passthrough, rename,
transformation, and aggregation lineage in dbt Docs v2 or from the generated Information Schema.

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
engineering, and pipeline reliability. This repo is my public workspace for turning day-to-day analytics engineering
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
