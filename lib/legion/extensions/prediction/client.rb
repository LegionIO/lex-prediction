# frozen_string_literal: true

require 'legion/extensions/prediction/helpers/modes'
require 'legion/extensions/prediction/helpers/prediction_store'
require 'legion/extensions/prediction/runners/prediction'

module Legion
  module Extensions
    module Prediction
      class Client
        include Runners::Prediction

        def initialize(**)
          @prediction_store = Helpers::PredictionStore.new
        end

        private

        attr_reader :prediction_store
      end
    end
  end
end
