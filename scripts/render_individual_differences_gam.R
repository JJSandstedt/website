# ============================================================================
#  Render the two-participant GAMM individual-differences figure for the
#  MInDReading page.
#
#  This is a trimmed version of the full 3-subject GAMM panel code:
#    - keeps ONLY S412 (Sunnmøre, Bokmål-aligned) and S278 (Northern
#      Norway, Bokmål-conflict)
#    - retains the 3-row layout (waveforms / difference / topographies)
#      and both the right-side Agreement legend + bottom Amplitude
#      colourbar
#    - writes a single transparent PNG straight into the personal
#      webpage's images/ folder
#
#  Run this inside the analysis project where `significant_electrodes`,
#  `GAM_smooth()`, `plot_gam_subject()`, and `create_topomap()` are
#  already loaded. Adjust OUT_PNG if your webpage repo lives somewhere
#  else.
# ============================================================================
library(tidyverse); library(here); library(mgcv); library(itsadug)
library(patchwork); library(cowplot)

# --- USER KNOBS -------------------------------------------------------------
OUT_PNG <- "/Users/jadesandstedt/Library/CloudStorage/Dropbox/R_projects/Personal_webpage_development/Personal webpage/images/individual_differences_gam.png"
PNG_W   <- 12    # inches — 2 subjects side-by-side
PNG_H   <- 8.0    # inches — 3 rows (waves / diff / topos) + legends
PNG_DPI <- 200

# --- Shared settings (unchanged from full version) --------------------------
condition_id  <- "Adj.Num"
search_window <- c(0, 1200)
narrow_window <- c(500, 1000)
plot_xlim     <- c(-100, 1200)
wave_ylim     <- c(-5, 12)
diff_ylim     <- c(-6, 6)
topo_window_1 <- c(300, 500)
topo_window_2 <- c(800, 1000)
topo_limits   <- c(-6, 6)

# Reference electrodes to drop from the topographies. (The waveform and
# difference panels already restrict to `significant_electrodes`, so they
# aren't affected; only the full-head topomaps need this filter.)
EXCLUDE_ELECTRODES <- c("FCz", "TP9", "TP10")

gramm_col   <- "steelblue4"
ungramm_col <- "red4"

output_dir <- here(
  "data", "erp_data", "full_individ_raw_data_by_condition", "Bokmål",
  "Single_subject", "outputs"
)

jet.colors <- colorRampPalette(c(
  "#00007F", "blue", "#007FFF", "cyan", "#7FFF7F",
  "yellow", "#FF7F00", "red", "#7F0000"
))

base_plot_theme <- theme_minimal(base_size = 12) +
  theme(
    panel.grid.minor   = element_blank(),
    plot.title         = element_text(face = "bold", size = 12, hjust = 0.5),
    plot.subtitle      = element_blank(),
    legend.position    = "bottom",
    legend.key.width   = grid::unit(1.2, "cm"),
    plot.background    = element_rect(fill = "transparent", colour = NA),
    panel.background   = element_rect(fill = "transparent", colour = NA),
    legend.background  = element_rect(fill = "transparent", colour = NA)
  )

# --- ONLY the first two subjects --------------------------------------------
subject_info <- tibble(
  subject_id    = c("S412", "S278"),
  subject_label = c("S412: Sunnmøre (dialect–standard aligned)",
                    "S278: Northern Norway (dialect–standard conflict)"),
  effect_fill   = c("red4", "steelblue4")
)

# --- Helpers (unchanged from your full version) -----------------------------
get_subject_file <- function(subject_id, condition_id) {
  here(
    "data", "erp_data", "full_individ_raw_data_by_condition", "Bokmål", "Single_subject",
    paste0("processed_data_subject_", subject_id,
           "_New Reference_TP9_TP10_", condition_id, ".csv")
  )
}

read_subject_df <- function(subject_id, condition_id, electrodes = NULL) {
  dat <- readr::read_csv(get_subject_file(subject_id, condition_id),
                         show_col_types = FALSE) %>%
    mutate(
      Subject        = subject_id,
      Condition      = condition_id,
      Electrode      = as.character(Electrode),
      electrode      = Electrode,
      IsIncorrect    = as.numeric(Agreement == "Non-Agreement"),
      AgreementLabel = if_else(IsIncorrect == 1, "Non-Agreement", "Agreement")
    )
  if (!is.null(electrodes)) {
    dat <- dat %>% filter(Electrode %in% as.character(electrodes))
  }
  dat
}

apply_topomap_scale <- function(p, show_legend = FALSE,
                                legend_position = "bottom") {
  p +
    scale_fill_gradientn(
      colours = jet.colors(10),
      limits  = topo_limits,
      guide   = guide_colourbar(
        title     = "Amplitude",
        barwidth  = grid::unit(5.5, "cm"),
        barheight = grid::unit(0.35, "cm")
      ),
      oob  = scales::squish,
      name = "Amplitude"
    ) +
    coord_equal(xlim = c(-0.75, 0.75), ylim = c(-0.75, 0.75),
                expand = FALSE, clip = "off") +
    theme(
      legend.position = if (show_legend) legend_position else "none",
      legend.title    = element_text(size = 10),
      legend.text     = element_text(size = 9),
      plot.margin     = margin(1, 1, 1, 1)
    )
}

make_p_waves <- function(subject_id, subject_label, condition_id,
                         significant_electrodes, effect_fill,
                         plot_xlim = c(-100, 1200), wave_ylim = c(-5, 12),
                         show_y_axis = TRUE, show_legend = FALSE) {
  illustr_df <- read_subject_df(subject_id, condition_id, significant_electrodes)
  illustr_mod <- setNames(
    lapply(as.character(significant_electrodes), function(elec) {
      subdata  <- illustr_df %>% filter(Electrode == elec)
      amp_mean <- mean(subdata$Amplitude, na.rm = TRUE)
      amp_sd   <- sd(subdata$Amplitude,   na.rm = TRUE)
      subdata  <- subdata %>%
        filter(abs(Amplitude - amp_mean) <= 3 * amp_sd)
      mgcv::bam(
        Amplitude ~ s(Time, k = 10) +
          s(Time, by = IsIncorrect, k = 10) +
          s(Time, Item, bs = "fs", m = 1),
        data = subdata, discrete = TRUE, nthreads = 2
      )
    }),
    as.character(significant_electrodes)
  )
  time_grid <- seq(min(illustr_df$Time, na.rm = TRUE),
                   max(illustr_df$Time, na.rm = TRUE), by = 1)
  pred_waves_avg <- purrr::imap_dfr(illustr_mod, function(mod, elec) {
    itsadug::get_predictions(
      mod,
      cond = list(Time = time_grid, IsIncorrect = c(0, 1)),
      rm.ranef = TRUE, print.summary = FALSE
    ) %>% mutate(Electrode = elec)
  }) %>%
    mutate(AgreementLabel = if_else(IsIncorrect == 0, "Agreement", "Non-Agreement")) %>%
    group_by(Time, AgreementLabel) %>%
    summarise(fit = mean(fit, na.rm = TRUE),
              CI  = mean(CI,  na.rm = TRUE), .groups = "drop") %>%
    mutate(lwr = fit - CI, upr = fit + CI)
  pred_waves_wide <- pred_waves_avg %>%
    tidyr::pivot_wider(names_from = AgreementLabel,
                       values_from = c(fit, CI, lwr, upr))
  raw_waves_avg <- illustr_df %>%
    group_by(Time, AgreementLabel) %>%
    summarise(amplitude = mean(Amplitude, na.rm = TRUE), .groups = "drop")

  p <- ggplot(pred_waves_wide %>%
                filter(Time >= plot_xlim[1], Time <= plot_xlim[2]),
              aes(x = Time)) +
    geom_hline(yintercept = 0, colour = "grey50", linewidth = 0.5) +
    geom_vline(xintercept = 0, colour = "grey50", linewidth = 0.5) +
    geom_ribbon(aes(ymin = fit_Agreement, ymax = `fit_Non-Agreement`),
                fill = effect_fill, alpha = 0.25) +
    geom_ribbon(aes(ymin = lwr_Agreement, ymax = upr_Agreement),
                fill = gramm_col, alpha = 0.20) +
    geom_ribbon(aes(ymin = `lwr_Non-Agreement`, ymax = `upr_Non-Agreement`),
                fill = ungramm_col, alpha = 0.20) +
    geom_line(data = raw_waves_avg %>%
                filter(AgreementLabel == "Agreement",
                       Time >= plot_xlim[1], Time <= plot_xlim[2]),
              aes(x = Time, y = amplitude), colour = gramm_col,
              linewidth = 0.3, alpha = 0.45, inherit.aes = FALSE) +
    geom_line(data = raw_waves_avg %>%
                filter(AgreementLabel == "Non-Agreement",
                       Time >= plot_xlim[1], Time <= plot_xlim[2]),
              aes(x = Time, y = amplitude), colour = ungramm_col,
              linewidth = 0.3, alpha = 0.45, inherit.aes = FALSE) +
    geom_line(aes(y = fit_Agreement, colour = "Agreement",
                  linetype = "Agreement"), linewidth = 1) +
    geom_line(aes(y = `fit_Non-Agreement`, colour = "Non-Agreement",
                  linetype = "Non-Agreement"), linewidth = 1) +
    scale_colour_manual(name = "Agreement",
                        values = c(Agreement = gramm_col,
                                   `Non-Agreement` = ungramm_col),
                        breaks = c("Agreement", "Non-Agreement")) +
    scale_linetype_manual(name = "Agreement",
                          values = c(Agreement = "solid",
                                     `Non-Agreement` = "longdash"),
                          breaks = c("Agreement", "Non-Agreement")) +
    guides(colour = guide_legend(
      title = "Agreement",
      override.aes = list(linetype = c("solid", "longdash"),
                          linewidth = c(1, 1), alpha = 1)),
      linetype = "none") +
    coord_cartesian(xlim = plot_xlim, ylim = wave_ylim,
                    expand = TRUE, clip = "on") +
    labs(title = subject_label, x = NULL,
         y = if (show_y_axis) "Amplitude (µV)" else NULL) +
    base_plot_theme
  if (!show_y_axis) p <- p + theme(axis.title.y = element_blank(),
                                   axis.text.y  = element_blank(),
                                   axis.ticks.y = element_blank())
  if (!show_legend)  p <- p + theme(legend.position = "none")
  p
}

make_p_diff <- function(subject_id, condition_id, significant_electrodes,
                        effect_fill, search_window = c(0, 1200),
                        narrow_window = c(500, 1000),
                        plot_xlim = c(-100, 1200), diff_ylim = c(-6, 6),
                        show_y_axis = TRUE) {
  illustr_smoothed <- GAM_smooth(
    file_paths         = get_subject_file(subject_id, condition_id),
    output_dir         = output_dir,
    grammaticality_col = "Agreement",
    incorrect_label    = "Non-Agreement",
    electrodes         = significant_electrodes,
    average_electrodes = FALSE,
    amplitude_sd_trim  = 3
  )
  p <- plot_gam_subject(
    metrics_df = illustr_smoothed, subject = subject_id,
    condition = condition_id, electrodes = significant_electrodes,
    metrics_file = NULL, data_dir = NULL, file_pattern = NULL,
    recursive_file_search = TRUE, ignore_case_file_search = FALSE,
    search_window = search_window, narrow_window = narrow_window,
    polarity = "flexible",
    xlim = plot_xlim, ylim = diff_ylim,
    coord_expand = TRUE, coord_clip = "on",
    show_raw = TRUE, show_derivative = FALSE, show_ci = TRUE,
    show_area = TRUE, show_search_window = FALSE,
    show_reference_lines = TRUE, show_peak_line = TRUE,
    show_fal_line = TRUE,
    raw_color = "grey60", raw_alpha = 0.6, raw_size = 0.5,
    raw_linetype = "solid",
    smooth_color = "black", smooth_alpha = 1, smooth_size = 1.2,
    smooth_linetype = "solid",
    derivative_color = "firebrick", derivative_alpha = 0.6,
    derivative_size = 0.7, derivative_linetype = "dashed",
    derivative_scale = 100,
    ci_fill = "grey40", ci_alpha = 0.2,
    area_fill = effect_fill, area_alpha = 0.20,
    search_window_fill = "grey95", search_window_alpha = 0.5,
    zero_line_color = "grey50", zero_line_alpha = 1,
    zero_line_size = 0.5, zero_line_linetype = "solid",
    peak_line_color = "black", peak_line_alpha = 0.7,
    peak_line_size = 0.6, peak_line_linetype = "dashed",
    fal_line_color = "black", fal_line_alpha = 0.7,
    fal_line_size = 0.6, fal_line_linetype = "dotted",
    x_label = "Time (ms)",
    y_label = if (show_y_axis) "Δ Amplitude (µV)" else NULL,
    show_title = FALSE, title_stats = TRUE, title_prefix = NULL,
    base_size = 12, title_size = 12, print_plot = FALSE
  ) +
    base_plot_theme +
    theme(legend.position = "none",
          plot.title = element_blank(),
          plot.subtitle = element_blank())
  if (!show_y_axis) p <- p + labs(y = NULL) +
      theme(axis.title.y = element_blank(),
            axis.text.y  = element_blank(),
            axis.ticks.y = element_blank())
  p
}

make_subject_topomap_df <- function(subject_id, condition_id) {
  read_subject_df(subject_id, condition_id, electrodes = NULL) %>%
    filter(!electrode %in% EXCLUDE_ELECTRODES) %>%
    group_by(Subject, Condition, Time, electrode, AgreementLabel) %>%
    summarise(Amplitude = mean(Amplitude, na.rm = TRUE), .groups = "drop") %>%
    tidyr::pivot_wider(names_from = AgreementLabel,
                       values_from = Amplitude) %>%
    mutate(Amplitude = `Non-Agreement` - Agreement, Group = Subject) %>%
    dplyr::select(Group, Condition, Time, electrode, Amplitude)
}

make_topomap_pair <- function(subject_id, condition_id, topo_df) {
  topo_300_500 <- create_topomap(
    data = topo_df, group = subject_id, condition = condition_id,
    time_start = topo_window_1[1], time_end = topo_window_1[2]
  ) + labs(title = "300–500 ms") +
    theme(plot.title = element_text(size = 10, face = "bold", hjust = 0.5))
  topo_800_1000 <- create_topomap(
    data = topo_df, group = subject_id, condition = condition_id,
    time_start = topo_window_2[1], time_end = topo_window_2[2]
  ) + labs(title = "800–1000 ms") +
    theme(plot.title = element_text(size = 10, face = "bold", hjust = 0.5))
  topo_300_500   <- apply_topomap_scale(topo_300_500,   show_legend = FALSE)
  topo_800_1000  <- apply_topomap_scale(topo_800_1000,  show_legend = FALSE)
  patchwork::wrap_plots(list(topo_300_500, topo_800_1000),
                        nrow = 1, widths = c(1, 1))
}

# --- Build the two columns --------------------------------------------------
subject_panels <- subject_info %>%
  mutate(
    topo_df     = map(subject_id, ~ make_subject_topomap_df(.x, condition_id)),
    show_y_axis = subject_id == "S412",
    p_waves = pmap(
      list(subject_id, subject_label, effect_fill, show_y_axis),
      ~ make_p_waves(subject_id = ..1, subject_label = ..2,
                     condition_id = condition_id,
                     significant_electrodes = significant_electrodes,
                     effect_fill = ..3, plot_xlim = plot_xlim,
                     wave_ylim = wave_ylim, show_y_axis = ..4,
                     show_legend = FALSE)
    ),
    p_diff = pmap(
      list(subject_id, effect_fill, show_y_axis),
      ~ make_p_diff(subject_id = ..1, condition_id = condition_id,
                    significant_electrodes = significant_electrodes,
                    effect_fill = ..2, search_window = search_window,
                    narrow_window = narrow_window, plot_xlim = plot_xlim,
                    diff_ylim = diff_ylim, show_y_axis = ..3)
    ),
    p_topo = pmap(
      list(subject_id, topo_df),
      ~ make_topomap_pair(subject_id = ..1,
                           condition_id = condition_id,
                           topo_df = ..2)
    )
  )

# --- Side legends (unchanged) -----------------------------------------------
agreement_legend_plot <- tibble(
  Time = rep(c(0, 1), 2),
  Amplitude = c(0, 1, 0, 1),
  AgreementLabel = rep(c("Agreement", "Non-Agreement"), each = 2)
) %>%
  ggplot(aes(x = Time, y = Amplitude,
             colour = AgreementLabel, linetype = AgreementLabel)) +
  geom_line(linewidth = 1) +
  scale_colour_manual(name = "Agreement",
                      values = c(Agreement = gramm_col,
                                 `Non-Agreement` = ungramm_col),
                      breaks = c("Agreement", "Non-Agreement")) +
  scale_linetype_manual(name = "Agreement",
                        values = c(Agreement = "solid",
                                   `Non-Agreement` = "longdash"),
                        breaks = c("Agreement", "Non-Agreement")) +
  guides(colour = guide_legend(
    title = "Agreement",
    override.aes = list(linetype = c("solid", "longdash"),
                        linewidth = c(1, 1), alpha = 1)),
    linetype = "none") +
  theme_void() +
  theme(legend.position    = "right",
        legend.title       = element_text(size = 10),
        legend.text        = element_text(size = 9),
        legend.background  = element_rect(fill = "transparent", colour = NA),
        plot.background    = element_rect(fill = "transparent", colour = NA),
        panel.background   = element_rect(fill = "transparent", colour = NA))

agreement_legend_panel <- cowplot::get_legend(agreement_legend_plot) %>%
  patchwork::wrap_elements()

right_legend_col <- patchwork::wrap_plots(
  list(patchwork::plot_spacer(), agreement_legend_panel,
       patchwork::plot_spacer()),
  ncol = 1, heights = c(1, 0.45, 1)
)

topo_legend_plot <- tibble(x = 1, y = 1, Amplitude = 0) %>%
  ggplot(aes(x, y, fill = Amplitude)) + geom_tile() +
  scale_fill_gradientn(
    colours = jet.colors(10), limits = topo_limits,
    guide = guide_colourbar(
      title = "Amplitude",
      barwidth = grid::unit(5.5, "cm"),
      barheight = grid::unit(0.35, "cm"),
      title.position = "left", title.vjust = 0.8
    ),
    oob = scales::squish, name = "Amplitude"
  ) +
  theme_void() +
  theme(legend.position    = "bottom",
        legend.title       = element_text(size = 10),
        legend.text        = element_text(size = 9),
        legend.background  = element_rect(fill = "transparent", colour = NA),
        plot.background    = element_rect(fill = "transparent", colour = NA),
        panel.background   = element_rect(fill = "transparent", colour = NA))

topo_legend_panel <- cowplot::get_legend(topo_legend_plot) %>%
  patchwork::wrap_elements()

# --- Assemble ----------------------------------------------------------------
waves_row <- patchwork::wrap_plots(subject_panels$p_waves, nrow = 1)
diff_row  <- patchwork::wrap_plots(subject_panels$p_diff,  nrow = 1)
topo_row  <- patchwork::wrap_plots(subject_panels$p_topo,  nrow = 1)

main_panel <- patchwork::wrap_plots(
  list(waves_row, diff_row, topo_row),
  ncol = 1, heights = c(1, 1, 1.25)
)

main_with_agreement_legend <- patchwork::wrap_plots(
  list(main_panel, right_legend_col),
  nrow = 1, widths = c(1, 0.13)
)

combined_plot <- patchwork::wrap_plots(
  list(main_with_agreement_legend, topo_legend_panel),
  ncol = 1, heights = c(1, 0.08)
) &
  theme(plot.background   = element_rect(fill = "transparent", colour = NA),
        panel.background  = element_rect(fill = "transparent", colour = NA),
        legend.background = element_rect(fill = "transparent", colour = NA))

# --- Save as transparent PNG -------------------------------------------------
dir.create(dirname(OUT_PNG), recursive = TRUE, showWarnings = FALSE)
ggsave(OUT_PNG, combined_plot,
       width = PNG_W, height = PNG_H, units = "in", dpi = PNG_DPI,
       bg = "transparent")
message("Wrote ", OUT_PNG)
