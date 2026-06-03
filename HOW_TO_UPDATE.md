# How to update jadesandstedt.com

Whenever you change a `.qmd` file (or any content) and want it to appear
on the live website, do the following.

You only need a terminal. In RStudio you can use the **Terminal** tab
(next to the Console), or open the macOS **Terminal** app.

---

## Step 1 — Go to the project folder

Copy-paste this exact line (the quotes matter because the path has spaces):

    cd "/Users/jadesandstedt/Library/CloudStorage/Dropbox/R_projects/Personal_webpage_development/Personal webpage"

## Step 2 — Publish to the live site

    quarto publish gh-pages

- This rebuilds the whole site and pushes it to the live web address.
- If it asks "Publish update to ... ? (Y/n)", type **Y** and press Enter.
- Your changes appear at https://jadesandstedt.com within about a minute
  (sometimes you need to refresh / hard-refresh the page).

That's the only step required to update the live website.

## Step 3 (recommended) — Back up your source code on GitHub

This saves a version-history copy of your editable files. It does NOT
affect the live site, but it's good insurance.

    git add .
    git commit -m "Describe what you changed, e.g. Add n = 105 to SPR section"
    git push

---

## Quick reference (all together)

    cd "/Users/jadesandstedt/Library/CloudStorage/Dropbox/R_projects/Personal_webpage_development/Personal webpage"
    quarto publish gh-pages
    git add .
    git commit -m "What I changed"
    git push

---

## Notes & troubleshooting

- **The live site = the `gh-pages` branch.** `quarto publish gh-pages`
  is what regenerates it. Saving a `.qmd` in RStudio alone changes nothing
  online until you run that command.

- **Git asks for a password?** Use your GitHub *Personal Access Token*
  (not your account password) as the password. If the token is lost,
  make a new one at github.com → Settings → Developer settings →
  Personal access tokens → Tokens (classic), with the `repo` scope.

- **A file shows up as "deleted" in `git status` but you didn't delete it?**
  This can happen with Dropbox if the file hasn't fully synced/downloaded.
  Don't commit that deletion — right-click the file in Finder and choose
  "Make available offline" (or just open the folder so Dropbox downloads it),
  then try again. The big video file `images/erp_unfolding.mp4` is the most
  likely one to do this.

- **Custom domain stops working?** The file named `CNAME` in this folder
  (containing `jadesandstedt.com`) must stay there — it's what keeps the
  custom domain attached. It's already set up; just don't delete it.
