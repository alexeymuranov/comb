# encoding: UTF-8 (magic comment)

class CTT2013
  require_relative 'url_helpers'
  helpers URLHelpers

  require_relative 'html_helpers'
  helpers HTMLHelpers

  require_relative 'form_helpers'
  helpers FormHelpers

  require_relative 'localisation_helpers'
  helpers LocalisationHelpers

  require_relative 'data_presentation_helpers'
  helpers DataPresentationHelpers

  require_relative 'model_presentation_helpers'
  helpers ModelPresentationHelpers

  require_relative 'collection_filtering_helpers'
  helpers CollectionFilteringHelpers

  require_relative 'view_pagination_helpers'
  helpers ViewPaginationHelpers
end
