# <><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
# AUTHOR:       Philippe Massicotte
#
# DESCRIPTION:  Visualize AVW.
# <><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>

rm(list = ls())

source(here("R", "zzz.R"))

df <- read_csv(here("data","clean","apparent_visible_wavelength.csv"))

aphy <- read_csv(here("data", "clean", "merged_dataset.csv")) |>
  select(sample_id, bioregion_name, season, wavelength, aphy, anap)  |>
  filter(between(wavelength, 400, 700)) |>
  collect()

df_viz <- df  |>
  dtplyr::lazy_dt()  |>
  inner_join(aphy, by = c("sample_id", "bioregion_name"))  |>
  group_by(sample_id)  |>
  mutate(across(c(aphy, anap),
    ~ . / pracma::trapz(wavelength, .),
    .names = "normalized_{.col}"
  ))  |>
  ungroup()  |>
  as_tibble() |>
  filter(normalized_aphy <= 0.03)

df_viz <- df_viz  |>
  group_by(sample_id)  |>
  filter(all(normalized_aphy[between(wavelength, 400, 600)] > 0))  |>
  ungroup()

df_viz

# Export the data for later use
df_viz  |>
  write_csv(here(
    "data",
    "clean",
    "apparent_visible_wavelength_normalized_spectra.csv"
  ))

# What is the range of PAAW?

paaw <- df_viz  |>
  distinct(sample_id, .keep_all = TRUE)  |>
  pull(avw_aphy)

range(paaw)
quantile(paaw)

# Reorder by season and bioregion -----------------------------------------

df_viz <- df_viz  |>
  mutate(season = factor(season,
    levels = c("Spring", "Summer", "Autumn", "Winter")
  ))  |>
  mutate(bioregion_name = factor(
    bioregion_name,
    levels = c(
      "Scotian Shelf",
      "NAB",
      "Labrador"
    )
  ))

# Mean PAAW spectra -------------------------------------------------------

df_viz

mean_paaw <- df_viz  |>
  group_by(bioregion_name, wavelength)  |>
  summarise(mean_normalized_aphy = mean(normalized_aphy))  |>
  ungroup()

mean_paaw

# Plot --------------------------------------------------------------------

p1 <- df_viz  |>
  ggplot(aes(x = wavelength, y = normalized_aphy, color = avw_aphy, group = sample_id)) +
  geom_line(size = 0.1) +
  geom_line(
    data = mean_paaw,
    aes(x = wavelength, y = mean_normalized_aphy, group = bioregion_name),
    inherit.aes = FALSE,
    size = 0.5
  ) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.01))) +
  paletteer::scale_color_paletteer_c(
    "pals::kovesi.rainbow_bgyr_35_85_c72",
    breaks = scales::breaks_pretty(n = 4),
    guide = guide_colorbar(
      direction = "horizontal",
      title.position = "top",
      title.hjust = 0.5,
      barwidth = unit(4, "cm"),
      barheight = unit(0.2, "cm"),
      label.theme = element_text(size = 7, family = "Montserrat Light"),
      title.theme = element_text(size = 9, family = "Montserrat")
    )
  ) +
  facet_wrap(~bioregion_name, ncol = 1) +
  labs(
    x = "Wavelength (nm)",
    y = quote(Normalized~a[phi]~(nm^-1)),
    color = "PAAW (nm)"
  ) +
  theme(
    strip.text = element_blank(),
    legend.justification = c(1, 1),
    legend.position = c(0.99, 0.96),
    panel.spacing.y = unit(3, "lines", data = NULL)
  )

# https://wilkelab.org/ggridges/articles/introduction.html
p2 <- df_viz  |>
  distinct(sample_id, .keep_all = TRUE)  |>
  ggplot(aes(avw_aphy, bioregion_name, fill = stat(x))) +
  geom_density_ridges_gradient(
    rel_min_height = 0.01,
    size = 0.25,
    quantile_lines = TRUE,
    quantiles = c(0.025, 0.5, 0.975)
  ) +
  # scale_fill_viridis_c(option = "C", direction = -1) +
  paletteer::scale_fill_paletteer_c("pals::kovesi.rainbow_bgyr_35_85_c72") +
  scale_x_continuous(limits = c(460, 502)) +
  scale_y_discrete(expand = expansion(mult = c(0, 0.01))) +
  labs(
    x = str_wrap("PAAW (nm)", 40),
    y = NULL
  ) +
  facet_wrap(~bioregion_name, ncol = 1, scales = "free", strip.position = "right") +
  coord_cartesian(clip = "off") +
  theme(
    legend.position = "none",
    axis.text.y = element_blank(),
    panel.spacing.y = unit(3, "lines", data = NULL),
    strip.text = element_text(size = 10)
  )

p <- p1 + p2 +
  plot_annotation(tag_levels = "A") &
  theme(
    plot.tag = element_text(face = "bold", size = 14)
  )

ggsave(
  here("graphs", "fig07.pdf"),
  device = cairo_pdf,
  width = 180,
  height = 180,
  units = "mm"
)

df_viz  |>
  group_by(bioregion_name)  |>
  summarise(mean_avw_aphy = mean(avw_aphy, na.rm = TRUE))


# Test --------------------------------------------------------------------

p3 <- df_viz  |>
  distinct(sample_id, .keep_all = TRUE)  |>
  ggplot(aes(avw_aphy, fct_rev(season), fill = stat(x))) +
  geom_density_ridges_gradient(
    rel_min_height = 0.005,
    size = 0.25,
    scale = 0.9,
    quantile_lines = TRUE,
    quantiles = 0.5
    # quantiles = c(0.025, 0.5, 0.975)
  ) +
  scale_fill_viridis_c() +
  scale_y_discrete(expand = expansion(mult = c(0, 0.01))) +
  labs(
    x = "Phytoplankton Apparent Absorption Wavelength (PAAW, nm)",
    y = NULL
  ) +
  facet_wrap(
    ~bioregion_name,
    ncol = 1,
    scales = "free_y",
    strip.position = "right"
  ) +
  theme(
    legend.position = "none",
    panel.spacing.y = unit(3, "lines", data = NULL)
  )

p <- p1 + p3 +
  plot_annotation(tag_levels = "A") &
  theme(
    plot.tag = element_text(face = "bold", size = 14)
  )

p

# ggsave(
#   here("graphs", "fig07b.pdf"),
#   device = cairo_pdf,
#   width = 7,
#   height = 8
# )
