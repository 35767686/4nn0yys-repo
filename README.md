# Mochy Music Sileo Repository template

This repository template publishes a simple APT repository for Sileo using GitHub Pages.

## Setup

1. Create a **public** GitHub repository (for example, `Mochy-Sileo-Repo`).
2. Copy the contents of this template into the repository's `main` branch.
3. Put the built `.deb` file in `pool/` (remove `PUT-DEB-FILES-HERE.txt`).
4. In GitHub, open **Settings → Pages** and set **Source** to **GitHub Actions**.
5. Commit and push. The `Publish Sileo Repository` workflow generates `Packages`, `Packages.gz`, `Packages.bz2`, and `Packages.xz`, then deploys the site.
6. When the workflow succeeds, the repository URL will be `https://GITHUB-USERNAME.github.io/REPOSITORY-NAME/`.
7. Add that URL in Sileo using **Sources → +**.

Whenever you add a new `.deb` to `pool/` and push, the repository index is regenerated automatically.

## Important

- Use a public repository if you are on GitHub Free and want a public Pages site.
- Public repositories and GitHub Pages are visible to everyone. Do not upload API keys, passwords, signing secrets, or personal information.
- The `.deb` must be a valid Debian package with package metadata. This workflow creates APT indexes; it does not build the `.deb`.
- If GitHub Pages does not deploy, check the `Publish Sileo Repository` run under **Actions**.
