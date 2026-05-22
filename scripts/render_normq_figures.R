# ============================================================================
#  Render the NorMQ (WP1) figure for the MInDReading page as a single
#  transparent PNG: the Sunnmøre Nynorsk-engagement map (left) and the
#  individual factor-score plot (right), combined with patchwork so the
#  page embeds ONE image with ONE caption.
#
#  Run this inside the analysis project where the data objects already exist.
#  Required in the environment:
#    - reading_data_with_factors          (factor plot)
#    - bok_col, nyn_col                   (Bokmål / Nynorsk colours)
#    - mapdata, mapdata_full              (sf objects for the map)
#    - low_color, mid_color, high_color,
#      common_midpoint, common_limits     (map fill gradient settings)
#  Adjust OUT_COMBINED if your webpage repo lives somewhere else.
# ============================================================================
library(tidyverse); library(sf); library(patchwork)

# --- USER KNOBS -------------------------------------------------------------
WEB_IMG      <- "/Users/jadesandstedt/Library/CloudStorage/Dropbox/R_projects/Personal_webpage_development/Personal webpage/images"
OUT_COMBINED <- file.path(WEB_IMG, "normq_combined.png")

COMBINED_W <- 10.5    # inches — overall figure width
COMBINED_H <- 5.0     # inches — overall figure height
W_MAP      <- 1.2     # relative width of the map panel (its content is wide)
W_FACTOR   <- 0.9     # relative width of the factor panel (narrower → taller)
DPI        <- 200

dir.create(WEB_IMG, recursive = TRUE, showWarnings = FALSE)

# Preferred written language group colours (factor plot)
group_cols <- c(
  "Bokmål"  = bok_col,
  "Nynorsk" = nyn_col
)


# ============================================================================
#  1.  FACTOR-SCORE DENSITY PLOT  (p1: Factor 1 vs Factor 2, no legend)
# ============================================================================
subject_scores <- reading_data_with_factors %>%
  filter(!is.na(Nynorsk_vs_Bokmål)) %>%
  select(Subject, Age, Gender, Birthplace, Region, Preferred_lang,
         Dialect_Engagement, Nynorsk_vs_Bokmål, Nynorsk_Digital) %>%
  distinct()

density_gradient_smooth_12 <- ggplot(
  subject_scores,
  aes(x = Nynorsk_vs_Bokmål, y = Dialect_Engagement)
) +
  stat_density_2d(aes(fill = Preferred_lang, alpha = after_stat(level)),
                  geom = "polygon", bins = 10, color = "white",
                  linewidth = 0.3, h = c(0.75, 0.75)) +
  geom_point(aes(color = Preferred_lang), size = 3, alpha = 0.9,
             shape = 21, fill = "white", stroke = 1.5) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "gray30",
             alpha = 0.8, linewidth = 0.8) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray30",
             alpha = 0.8, linewidth = 0.8) +
  scale_fill_manual(values = group_cols, name = "Preferred language") +
  scale_color_manual(values = group_cols, name = "Preferred language") +
  scale_alpha_continuous(range = c(0.1, 0.5), guide = "none") +
  labs(
    x = "Factor 2: Bokmål (−) vs. Nynorsk (+) engagement",
    y = "Factor 1: Written dialect engagement"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    legend.position    = "none",
    panel.grid.minor   = element_blank(),
    panel.grid.major   = element_line(color = "gray85", linewidth = 0.3),
    plot.background     = element_rect(fill = "transparent", colour = NA),
    panel.background    = element_rect(fill = "transparent", colour = NA),
    legend.background   = element_rect(fill = "transparent", colour = NA)
  )

p1 <- density_gradient_smooth_12


# ============================================================================
#  2.  SUNNMØRE NYNORSK-ENGAGEMENT MAP  (legend underneath)
# ============================================================================
cities <- data.frame(
  name = c("Volda", "Ålesund", "Ulsteinvik", "Stranda", "Sykkylven",
           "Valldal", "Ørsta"),
  lon = c(
    6 + 4/60 + 5/3600,      # Volda
    6 + 9/60 + 15/3600,     # Ålesund
    5 + 50/60 + 55/3600,    # Ulsteinvik
    6 + 58/60 + 0/3600,     # Stranda
    6 + 38/60 + 39/3600,    # Sykkylven
    7 + 15/60 + 49/3600,    # Valldal
    6 + 7/60 + 56/3600      # Ørsta
  ),
  lat = c(
    62 + 8/60 + 48/3600,    # Volda
    62 + 28/60 + 16/3600,   # Ålesund
    62 + 20/60 + 35/3600,   # Ulsteinvik
    62 + 10/60 + 0/3600,    # Stranda
    62 + 22/60 + 32/3600,   # Sykkylven
    62 + 17/60 + 52/3600,   # Valldal
    62 + 12/60 + 1/3600     # Ørsta
  )
)
cities_sf <- st_as_sf(cities, coords = c("lon", "lat"), crs = 4326)
cities_sf <- st_transform(cities_sf, crs = st_crs(mapdata))

diagonal_distances <- c(
  "Volda"      = 33000,
  "Ålesund"    = 15000,
  "Ulsteinvik" = 0,
  "Stranda"    = 30000,
  "Sykkylven"  = 25000,
  "Valldal"    = 30000,
  "Ørsta"      = 0
)

cities_labels <- cities_sf %>%
  mutate(
    diagonal_dist = diagonal_distances[name],
    lon_offset = st_coordinates(.)[, 1] + case_when(
      name == "Volda"      ~ -diagonal_dist - 13000,
      name == "Ålesund"    ~ -diagonal_dist - 15000,
      name == "Ulsteinvik" ~ -40000,
      name == "Stranda"    ~  diagonal_dist + 13000,
      name == "Sykkylven"  ~  diagonal_dist + 15000,
      name == "Valldal"    ~  diagonal_dist + 13000,
      name == "Ørsta"      ~ -diagonal_dist - 52600,
      TRUE ~ 0
    ),
    lat_offset = st_coordinates(.)[, 2] + case_when(
      name == "Volda"      ~ -diagonal_dist,
      name == "Ålesund"    ~  diagonal_dist,
      name == "Ulsteinvik" ~  0,
      name == "Stranda"    ~ -diagonal_dist,
      name == "Sykkylven"  ~  diagonal_dist,
      name == "Valldal"    ~ -diagonal_dist,
      name == "Ørsta"      ~ -0,
      TRUE ~ 0
    )
  ) %>%
  st_drop_geometry() %>%
  st_as_sf(coords = c("lon_offset", "lat_offset")) %>%
  st_set_crs(st_crs(cities_sf))

create_bent_line <- function(city_name, cities_sf, cities_labels,
                             diagonal_distances) {
  city_coords  <- st_coordinates(cities_sf[cities_sf$name == city_name, ])
  label_coords <- st_coordinates(cities_labels[cities_labels$name == city_name, ])
  diagonal_dist <- diagonal_distances[city_name]

  if (city_name == "Ulsteinvik") {
    coords_matrix <- rbind(city_coords, label_coords)
  } else if (city_name %in% c("Volda", "Ørsta")) {
    mid_point <- c(city_coords[1] - diagonal_dist, city_coords[2] - diagonal_dist)
    coords_matrix <- rbind(city_coords, mid_point, label_coords)
  } else if (city_name == "Ålesund") {
    mid_point <- c(city_coords[1] - diagonal_dist, city_coords[2] + diagonal_dist)
    coords_matrix <- rbind(city_coords, mid_point, label_coords)
  } else if (city_name == "Sykkylven") {
    mid_point <- c(city_coords[1] + diagonal_dist, city_coords[2] + diagonal_dist)
    coords_matrix <- rbind(city_coords, mid_point, label_coords)
  } else if (city_name %in% c("Stranda", "Valldal")) {
    mid_point <- c(city_coords[1] + diagonal_dist, city_coords[2] - diagonal_dist)
    coords_matrix <- rbind(city_coords, mid_point, label_coords)
  } else {
    coords_matrix <- rbind(city_coords, label_coords)
  }
  st_linestring(coords_matrix)
}

city_lines <- do.call(st_sfc, lapply(cities$name, function(n) {
  create_bent_line(n, cities_sf, cities_labels, diagonal_distances)
}))
city_lines <- st_sf(name = cities$name, geometry = city_lines,
                    crs = st_crs(cities_sf))

sunn_nynorsk_map <- ggplot() +
  geom_sf(data = mapdata_full, aes(fill = nynorsk_centered),
          color = "grey30", linewidth = 0.1) +
  geom_sf(data = city_lines, linewidth = 0.15, color = "black") +
  geom_sf(data = cities_labels, shape = 21, fill = "white", size = 1) +
  geom_sf(data = cities_sf, size = 1) +
  geom_sf_text(data = cities_labels, aes(label = name),
               size = 3, vjust = -0.5,
               fun.geometry = st_centroid, colour = "black") +
  scale_fill_gradient2(
    low = low_color, mid = mid_color, high = high_color,
    midpoint = common_midpoint, limits = common_limits, na.value = NA
  ) +
  coord_sf(clip = "off") +
  labs(fill = "Nynorsk engagement") +
  # legend underneath, as a horizontal colour-bar
  guides(fill = guide_colorbar(
    title.position = "top", title.hjust = 0.5,
    barwidth = grid::unit(4.5, "cm"), barheight = grid::unit(0.3, "cm")
  )) +
  theme_minimal() +
  theme(
    legend.position    = "bottom",
    legend.direction   = "horizontal",
    legend.box.spacing = grid::unit(0.1, "cm"),  # pull legend close to the map
    legend.margin      = margin(0, 0, 0, 0),
    panel.grid.major   = element_blank(),
    panel.grid.minor   = element_blank(),
    legend.title       = element_text(size = 10),
    legend.text        = element_text(size = 7),
    axis.text.x        = element_blank(),
    axis.text.y        = element_blank(),
    axis.title.x       = element_blank(),
    axis.title.y       = element_blank(),
    axis.ticks         = element_blank(),
    plot.margin        = margin(2, 2, 2, 2),
    plot.background   = element_rect(fill = "transparent", colour = NA),
    panel.background  = element_rect(fill = "transparent", colour = NA),
    legend.background = element_rect(fill = "transparent", colour = NA)
  )


# ============================================================================
#  3.  COMBINE (map | factor) AND SAVE ONE TRANSPARENT PNG
# ============================================================================
# free() lets the map fill its cell without patchwork's panel-alignment
# slack, while keeping it a normal ggplot (so its transparent background is
# preserved — unlike wrap_elements(), which adds an opaque background).
# Requires patchwork >= 1.2.0.
# plot_annotation() sets the patchwork-level background transparent too.
combined_normq <- free(sunn_nynorsk_map) + p1 +
  plot_layout(widths = c(W_MAP, W_FACTOR)) +
  plot_annotation(theme = theme(
    plot.background  = element_rect(fill = "transparent", colour = NA),
    panel.background = element_rect(fill = "transparent", colour = NA)
  ))

ggsave(OUT_COMBINED, combined_normq,
       width = COMBINED_W, height = COMBINED_H, units = "in", dpi = DPI,
       bg = "transparent")
message("Wrote ", OUT_COMBINED)
