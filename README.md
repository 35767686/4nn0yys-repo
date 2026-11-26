# 4nn0yys — Sileo Repository

A community-maintained Sileo source for iOS packages, translations and projects.

**Repository URL:** https://35767686.github.io/4nn0yys-repo/

## Featured package: Translated Mochy iOS

A community-maintained Turkish localization of Mochy Music for iOS. Explore music and use YouTube Music browsing and playback features through a translated interface with language and region preferences.

## Apply this update

1. Keep your existing `.deb` file in `pool/`.
2. Extract this patch ZIP.
3. Copy the patch's contents into the root of your existing `4nn0yys-repo` repository. Preserve the `.github` folder structure and replace the existing `README.md`, `index.html`, and `.github/workflows/publish.yml`.
4. Commit and push to `main`, or run **Publish Sileo Repository** manually from GitHub Actions.
5. The workflow regenerates the APT indexes and applies the Sileo display name, English description and package icon to package ID `com.puc.mochyios` on every publish.
6. Refresh the source in Sileo. If the old icon is cached, remove the source and add `https://35767686.github.io/4nn0yys-repo/` again.

## Branding files

- `CydiaIcon.png` and `CydiaIcon@2x.png` / `CydiaIcon@3x.png`: source icon shown by Sileo and other package managers.
- `PackageIcon.png`: icon shown on the Translated Mochy iOS package page.
- `index.html`: English repository landing page.

The repository workflow does not rebuild the `.deb`; it changes the published APT metadata Sileo reads. The original package's internal maintainer and executable files remain unchanged.

## GitHub repository About text

Set the repository's **About** description to:

`A community-run Sileo source for Translated Mochy iOS and other iOS packages.`

Set its website to the repository URL above.
