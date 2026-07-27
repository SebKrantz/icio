# Leather Example ICIO Data

An example 3 x 3 ICIO table describing a GVC for leather products with
industries 'Agriculture', 'Textile and Leather' and 'Transport
Equipment' for the countries 'Argentina', 'Turkey' and 'Germany'.

## Usage

``` r
data("leather")
```

## Format

A list of class 'iot' with the following elements:

- `inter`:

  9 x 9 input output matrix where each column gives the value of inputs
  supplied to the corresponding country-industry by each row
  country-industry.

- `final`:

  9 x 3 final demand matrix showing the final demand in each country
  (column) for each country-industry's (rows) produce.

- `countries`:

  character vector of country names (matching columns of `final`).

- `industries`:

  character vector of industries, such that
  `as.vector(t(outer(countries, industries, FUN = paste, sep = ".")))`
  generates the row- and column-names of `inter` and the rownames of
  `final`.

- `out`:

  A vector of gross country-industry output. In a complete productive
  system it should be equal to `rowSums(inter) + rowSums(final)`.

## See also

[`icio-package`](https://sebkrantz.github.io/icio/reference/icio-package.md)
