Pagy::OPTIONS[:limit] = 20

# Pagy 43.x defines `series` as protected in the NumericHelpers module.
# Our custom pagination view calls `pagy.series` directly, so we expose it publicly.
require "pagy/toolbox/helpers/support/series"

class Pagy
  public :series
end
