## Summary

<!-- What does this change do, and why? -->

## Type of change

- [ ] New demo / feature
- [ ] Bug fix
- [ ] Documentation only
- [ ] Refactor (no behavior change)
- [ ] CI/CD or tooling

## How was this validated?

<!-- Paste the relevant `dbt build` / `dbt test` output, or describe the manual check. -->

```text

```

## Checklist

- [ ] Branch is named `feat/`, `fix/`, `refactor/`, `docs/`, `test/`, or `chore/` followed by a short, specific slug
- [ ] `dbt build --select state:modified+` (or the full project) passes locally against a dev schema
- [ ] New or changed models have `schema.yml` entries: description, columns, and at least one data test
- [ ] No secrets, credentials, or warehouse-specific hardcoded values were added
- [ ] Docs (`README.md` / demo guide) updated if behavior or setup steps changed
- [ ] This PR is scoped to one logical change (no unrelated file churn)

## Related issue

<!-- Closes #123, or "N/A" -->
