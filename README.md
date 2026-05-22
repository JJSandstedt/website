# Jade Sandstedt — Personal Academic Website

A Quarto site to replace
[sites.google.com/view/jade-sandstedt](https://sites.google.com/view/jade-sandstedt/home).

> **Mental model in one sentence.** You write Markdown files (`.qmd`),
> Quarto turns them into a website, and a free host serves the site at a
> public URL. That's it.

---

## Step 0 — Install Quarto (one-time, ~3 minutes)

You already have RStudio, so this is fast.

1. Go to <https://quarto.org/docs/get-started/> and click the macOS / Windows
   installer for your computer.
2. Run the installer. No configuration choices to make — just click through.
3. Open RStudio. If Quarto installed correctly, going to
   **File → New File → Quarto Document…** should now work without errors.

(That's the whole "install" step — Quarto is just one program.)

---

## Step 1 — Open this folder as an RStudio project

1. Open RStudio.
2. **File → Open Project…** and pick this folder
   (`Personal webpage` inside `R_projects/Personal_webpage_development`).
3. If RStudio asks whether to create a `.Rproj` file, say yes. (Cosmetic.)

You should now see all the files in the bottom-right pane:
`_quarto.yml`, `index.qmd`, `cv.qmd`, `publications.qmd`,
`mindreading.qmd`, `publications.bib`, `styles.css`, etc.

---

## Step 2 — Preview the site locally

This is the magical moment where it stops being abstract.

1. In RStudio's **Terminal** tab (next to Console), type:

   ```
   quarto preview
   ```

   …and press Enter.

2. After a few seconds, RStudio's Viewer pane (or a new browser tab) will
   open the site. **It's running on your laptop.** Click around — the four
   tabs (About / CV / Publications / MInDReading) all work.

3. Now try changing some text. Open `index.qmd`, change a sentence, save
   the file. The preview reloads automatically. That's the whole authoring
   loop: edit → save → see the change.

To stop the preview, click in the Terminal pane and press **Ctrl + C**.

---

## Step 3 — Things you'll want to fix before publishing

Search for `TODO` in the project (RStudio's Find-in-Files, **Ctrl+Shift+F**)
— I've left small markers where your input is needed:

- **`index.qmd`** — drop a portrait photo at `images/jade.jpg`
  (the page is configured for a `~16em` square; any reasonable photo works).
- **`cv.qmd`** — fill in the education / languages stubs, and put your
  CV PDF at `pdfs/sandstedt_CV_may_2026.pdf` (create the `pdfs/` folder).
- **`mindreading.qmd`** — the figures are *placeholders* generated from
  simulated data. When you have real pilot results, replace the data inside
  each `r` chunk; the rest of the page stays the same.
- **`publications.bib`** — add new BibTeX entries here as papers come out.

When you change anything, just save the file — the preview reloads.

---

## Step 4 — Publish to the internet

When you're happy with the local preview, you have two options:

### Option A (recommended for your first site): **Quarto Pub**

Quarto Pub is free hosting by Posit — the makers of RStudio. It's the
lowest-friction way to get your site online. No Git, no GitHub.

1. Make a free account at <https://quartopub.com>.
2. In RStudio's Terminal, run:

   ```
   quarto publish quarto-pub
   ```

3. The first time, it'll open a browser to authorise. After that, every
   future update is just `quarto publish quarto-pub` again.
4. Your site will live at something like
   `https://jadesandstedt.quarto.pub/jade-sandstedt`.

### Option B (more "academic-standard"): **GitHub Pages**

This is what most academics use. Requires a GitHub account (free at
<https://github.com>), but you'd benefit from one anyway — it gives you
version history for everything you write.

You can come back to this later. The local files don't change, so there's
no rush. When you're ready, the Quarto docs walk through it well:
<https://quarto.org/docs/publishing/github-pages.html>.

---

## File map

```
.
├── _quarto.yml          # site config (navigation, theme)
├── index.qmd            # About page (homepage)
├── cv.qmd               # CV page
├── publications.qmd     # auto-generated list from publications.bib
├── mindreading.qmd      # MInDReading project page (with R viz)
├── publications.bib     # BibTeX — add new papers here
├── styles.css           # small CSS overrides (mostly optional)
├── images/              # put portraits, screenshots, etc. here
└── pdfs/                # put your CV PDF (and any other PDFs) here
```

## Notes on the R chunks

`mindreading.qmd` uses three R packages: `ggplot2`, `dplyr`, `plotly`.
If any of these aren't installed yet, run this once in the R Console:

```r
install.packages(c("ggplot2", "dplyr", "plotly"))
```

After that, `quarto preview` should render everything cleanly.

---

## When things go wrong

- **"Quarto: command not found" in Terminal.** Restart RStudio after the
  Quarto installer finished.
- **A page fails to render.** Look at the Terminal output — Quarto prints
  the line number and a short error message. The most common cause is a
  missing R package (see above) or a missing image file.
- **You want to ask Claude to change something.** Drop the file path
  (e.g. "in `mindreading.qmd`, can you …") and Claude can edit it directly.
