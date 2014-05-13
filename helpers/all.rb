# encoding: UTF-8 (magic comment)

require_relative 'init'

module CTT2013::Helpers
  require_relative 'url_helpers'
  require_relative 'html_helpers'
  require_relative 'form_helpers'
  require_relative 'localisation_helpers'
  require_relative 'data_presentation_helpers'
  require_relative 'model_presentation_helpers'
  require_relative 'collection_filtering_helpers'
  require_relative 'view_pagination_helpers'
  require_relative 'view_presentation_choice_helpers'
  require_relative 'google_maps_helpers'

  ALL = [ URL,
          HTML,
          Form,
          Localisation,
          DataPresentation,
          ModelPresentation,
          CollectionFiltering,
          ViewPagination,
          ViewPresentationChoice,
          GoogleMaps ]
end
