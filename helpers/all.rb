# encoding: UTF-8 (magic comment)

require_relative 'init'

module CTT2013::Helpers
  require_relative 'url'
  require_relative 'html'
  require_relative 'form'
  require_relative 'localisation'
  require_relative 'data_presentation'
  require_relative 'model_presentation'
  require_relative 'collection_filtering'
  require_relative 'view_pagination'
  require_relative 'view_presentation_choice'
  require_relative 'google_maps'

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
