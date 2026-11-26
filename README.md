# 4nn0yys-repo: Sileo Release metadata fix

This patch updates the publishing workflow so the deployed site includes a root-level `Release` file as well as `Packages`, `Packages.gz`, `Packages.bz2`, and `Packages.xz`.

## Apply it

1. Download and extract this ZIP.
2. Copy the `.github/workflows/publish.yml` file into the same path in your existing `4nn0yys-repo` repository, replacing the old file.
3. Commit and push the change to `main`.
4. Wait for `Publish Sileo Repository` to complete successfully.
5. In Safari, open `https://35767686.github.io/4nn0yys-repo/Release`. It should display APT release metadata. Open `/Packages` too; it should list the Mochy package.
6. In Sileo, remove the old failed source and add `https://35767686.github.io/4nn0yys-repo/` again.

## Security note

This workflow creates unsigned Release metadata. It is intended to fix repository discovery. APT clients may still warn about an unsigned repository or refuse package refreshes unless the repository is signed and its public key is trusted. Do not ignore a signature or `NO_PUBKEY` warning; use a signed repository setup before distributing packages broadly.
