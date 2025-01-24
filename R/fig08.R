# <><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
# AUTHOR:       Philippe Massicotte
#
# DESCRIPTION:  Relationship between PAAW and aphy. I want to see if PAAW could
# be used as an index to eventually get information on phytoplankton cell size.
# <><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>

# Note that both aphy and aphy* ratio (443/675) give the same values. Here I
# will use aphy, but it can be compared with aphy* from other studies.

rm(list = ls())

source(here("R", "zzz.R"))

# Prepare the data --------------------------------------------------------

aphy <- open_dataset("data/clean/merged_dataset/") |>
  filter(wavelength %in% c(443, 675)) |>
  select(
    sample_id,
    bioregion_name,
    wavelength,
    season,
    aphy,
    aphy_specific,
    hplcchla
  ) |>
  collect()

paaw <- read_csv(here("data", "clean", "apparent_visible_wavelength.csv")) |>
  select(sample_id, bioregion_name, avw_aphy)

df <- inner_join(aphy, paaw, by = c("sample_id", "bioregion_name"))

df

# chla vs paaw ------------------------------------------------------------

p1 <- df |>
  filter(wavelength == 443) |>
  ggplot(aes(x = avw_aphy, y = hplcchla)) +
  geom_point(
    aes(fill = season),
    size = 1.5,
    stroke = 0.1,
    pch = 21,
    alpha = 0.3,
    cex = 2.3
  ) +
  scale_fill_manual(
    breaks = season_breaks,
    values = season_colors,
    guide = guide_legend(
      override.aes = list(size = 2, alpha = 1),
      label.theme = element_text(size = 7, family = "Montserrat Light")
    )
  ) +
  scale_x_continuous(breaks = scales::breaks_pretty()) +
  scale_y_log10() +
  annotation_logticks(sides = "l", size = 0.1) +
  geom_smooth(
    color = "#3c3c3c",
    size = 0.5,
    alpha = 0.25,
    method = "lm"
  ) +
  labs(
    x = NULL,
    y = quote("[Chl-a]" ~ (mg ~ m^{
      -3
    }))
  ) +
  ggpmisc::stat_poly_eq(
    aes(label = ..eq.label..),
    parse = TRUE,
    coef.digits = 4,
    f.digits = 5,
    p.digits = 10,
    label.x.npc = 0.05,
    family = "Montserrat",
    size = 2.5
  ) +
  ggpmisc::stat_poly_eq(
    aes(
      label = paste(..rr.label.., after_stat(p.value.label), sep = "*\", \"*")
    ),
    label.x.npc = 0.05,
    label.y.npc = 0.88,
    coef.digits = 4,
    parse = TRUE,
    family = "Montserrat",
    size = 2.5,
    small.p = TRUE
  ) +
  theme(
    legend.title = element_blank(),
    legend.justification = c(1, 0),
    legend.position = c(0.98, 0.02),
    legend.key.size = unit(0.4, "cm"),
    legend.background = element_blank()
  )

# aphy* vs paaw -----------------------------------------------------------

p2 <- df |>
  filter(wavelength == 443) |>
  ggplot(aes(x = avw_aphy, y = aphy_specific)) +
  geom_point(
    aes(fill = season),
    size = 1.5,
    stroke = 0.1,
    pch = 21,
    alpha = 0.3,
    cex = 2.3
  ) +
  scale_fill_manual(
    breaks = season_breaks,
    values = season_colors,
    guide = guide_legend(
      override.aes = list(size = 2, alpha = 1),
      label.theme = element_text(size = 7, family = "Montserrat Light")
    )
  ) +
  scale_x_continuous(breaks = scales::breaks_pretty()) +
  scale_y_log10() +
  annotation_logticks(sides = "l", size = 0.1) +
  geom_smooth(
    color = "#3c3c3c",
    size = 0.5,
    alpha = 0.25,
    method = "lm"
  ) +
  labs(
    x = NULL,
    y = quote(a[phi]^"*" ~ (443) ~ (m^2 ~ mg^{
      -1
    }))
  ) +
  ggpmisc::stat_poly_eq(
    aes(label = ..eq.label..),
    parse = TRUE,
    coef.digits = 4,
    f.digits = 5,
    p.digits = 10,
    label.x.npc = 1,
    label.y.npc = 0.88,
    family = "Montserrat",
    size = 2.5
  ) +
  ggpmisc::stat_poly_eq(
    aes(
      label = paste(..rr.label.., after_stat(p.value.label), sep = "*\", \"*")
    ),
    label.x.npc = 1,
    label.y.npc = 0.8,
    coef.digits = 4,
    parse = TRUE,
    family = "Montserrat",
    size = 2.5,
    small.p = TRUE
  ) +
  theme(
    legend.position = "none"
  )

# Relation between aphy ratio and PAAW ------------------------------------

# It was shown that the aphy* 443/675 could be related to both as a function of
# cell size and irradiance (Fujiki2002).

df_viz <- df |>
  select(-aphy_specific, -hplcchla) |>
  pivot_wider(
    names_from = wavelength,
    values_from = aphy,
    names_prefix = "aphy_wl"
  ) |>
  mutate(aphy_ratio = aphy_wl443 / aphy_wl675)

df_viz

formula <- y ~ x + I(x^2)

p3 <- df_viz |>
  ggplot(aes(x = avw_aphy, y = aphy_ratio)) +
  geom_point(
    aes(fill = season),
    size = 1.5,
    stroke = 0.1,
    pch = 21,
    alpha = 0.3,
    cex = 2.3
  ) +
  geom_smooth(
    formula = formula,
    color = "#3c3c3c",
    size = 0.5,
    alpha = 0.25
  ) +
  scale_x_continuous(breaks = scales::breaks_pretty()) +
  ggpmisc::stat_poly_eq(
    formula = formula,
    aes(label = ..eq.label..),
    parse = TRUE,
    coef.digits = 4,
    f.digits = 5,
    p.digits = 10,
    label.x.npc = 1,
    label.y.npc = 0.88,
    family = "Montserrat",
    size = 2.5
  ) +
  ggpmisc::stat_poly_eq(
    aes(
      label = paste(..rr.label.., after_stat(p.value.label), sep = "*\", \"*")
    ),
    formula = formula,
    label.x.npc = 1,
    label.y.npc = 0.8,
    coef.digits = 4,
    parse = TRUE,
    family = "Montserrat",
    size = 2.5,
    small.p = TRUE
  ) +
  scale_fill_manual(
    breaks = season_breaks,
    values = season_colors,
    guide = guide_legend(
      override.aes = list(size = 2, alpha = 1),
      label.theme = element_text(size = 7, family = "Montserrat Light")
    )
  ) +
  labs(
    x = str_wrap("PAAW (nm)", 40),
    y = quote(a[phi] ~ (443) / a[phi] ~ (675))
  ) +
  theme(
    legend.position = "none"
  )

## Model to predict aphy* ratio from PAAW ----

df_model <- df_viz |>
  group_nest() |>
  mutate(model = map(data, ~ lm(
    aphy_ratio ~ avw_aphy + I(avw_aphy^2),
    data = .
  ))) |>
  mutate(tidied = map(model, tidy)) |>
  mutate(augmented = map(model, augment))

df_model

df_model$model[[1]]
summary(df_model$model[[1]])

## Average by season ----

df_viz

df_viz |>
  group_by(season) |>
  summarise(mean_aphy_ratio = mean(aphy_ratio)) |>
  arrange(mean_aphy_ratio)

range(df_viz$aphy_ratio)

## Save plots --------------------------------------------------------------

p <- p1 + p2 + p3 +
  plot_layout(ncol = 1, byrow = FALSE) +
  plot_annotation(tag_levels = "A") &
  theme(
    plot.tag = element_text(face = "bold")
  )

ggsave(
  here("graphs", "fig08.pdf"),
  device = cairo_pdf,
  width = 90,
  height = 200,
  units = "mm"
)
