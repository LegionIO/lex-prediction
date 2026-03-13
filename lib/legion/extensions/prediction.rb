# frozen_string_literal: true

require 'legion/extensions/prediction/version'
require 'legion/extensions/prediction/helpers/modes'
require 'legion/extensions/prediction/helpers/prediction_store'
require 'legion/extensions/prediction/runners/prediction'

module Legion
  module Extensions
    module Prediction
      extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core
    end
  end
end
