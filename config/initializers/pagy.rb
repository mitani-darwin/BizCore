require "pagy/extras/array"
require "pagy/extras/overflow"

Pagy::DEFAULT[:limit] = 30
Pagy::DEFAULT[:overflow] = :last_page
