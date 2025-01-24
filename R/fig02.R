# <><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
# AUTHOR:       Philippe Massicotte
#
# DESCRIPTION:  Boxplot showing the seasonal evolution of selected variables.
# <><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>

rm(list = ls())

source(here("R", "zzz.R"))
source(here("R", "zzz_ggboxplot.R"))

# Load data ---------------------------------------------------------------

df <- open_dataset(here("data", "clean", "merged_dataset")) |>
  filter(wavelength %in% c(443, 675)) |>
  collect()

# PAAW

paaw <- read_csv(here("data", "clean", "apparent_visible_wavelength.csv"))

df <- df |>
  left_join(paaw, by = c("sample_id", "bioregion_name")) |>
  mutate(season = factor(season,
    levels = c("Spring", "Summer", "Autumn", "Winter")
  )) |>
  mutate(bioregion_name = factor(bioregion_name,
    levels = c(
      "Scotian Shelf",
      "NAB",
      "Labrador"
    )
  ))

df |>
  count(sample_id, wavelength) |>
  assertr::verify(n == 1)

# Range
df |>
  filter(snap > 0.001) |>
  pull(snap) |>
  range() |>
  round(digits = 3)

# Fig 7 Boxplots on absorption --------------------------------------------

p1 <- ggboxlpot(
  filter(df, wavelength == 443),
  season,
  aphy,
  strip.text = element_text(size = 10),
  ylab = "a[phi]~(443)~(m^{-1})"
)

p2 <- ggboxlpot(
  filter(df, wavelength == 675),
  season,
  aphy,
  strip.text = element_blank(),
  ylab = "a[phi]~(675)~(m^{-1})"
)

p3 <- ggboxlpot(
  filter(df, wavelength == 443),
  season,
  aphy_specific,
  strip.text = element_blank(),
  ylab = "a[phi]^'*'~(443)~(m^{2}~mg^{-1})"
)

p4 <- ggboxlpot(
  filter(df, wavelength == 443),
  season,
  anap,
  strip.text = element_blank(),
  ylab = "a[NAP]~(443)~(m^{-1})"
)

# There is 1 obvious outlier
p5 <- ggboxlpot(df |> filter(snap > 0.00100),
  season,
  snap,
  strip.text = element_blank(),
  ylab = "s[NAP]~(nm^{-1})"
)

p6 <- ggboxlpot(
  df,
  season,
  avw_aphy,
  strip.text = element_blank(),
  ylab = "PAAW~(nm)"
)

p <- p1 + p2 + p3 + p4 + p5 + p6 +
  plot_layout(ncol = 1) +
  plot_annotation(tag_levels = "A") &
  theme(plot.tag = element_text(size = 16, face = "bold"))

ggsave(
  here("graphs", "fig02.pdf"),
  device = cairo_pdf,
  width = 190,
  height = 330,
  units = "mm"
)

# Anova asked by Emmanuel -------------------------------------------------

df

unique(df$wavelength)

my_aov <-
  aov(
    log10(anap) ~ season,
    data = filter(df, wavelength == 443),
    subset = bioregion_name == "NAB"
  )

summary(my_aov)

df |>
  filter(str_detect(bioregion_name, "Scotian")) |>
  group_by(season) |>
  summarise(mean_avw = mean(avw_aphy, na.rm = TRUE))

df |>
  filter(str_detect(bioregion_name, "Labrador")) |>
  pull(avw_aphy) |>
  range()
