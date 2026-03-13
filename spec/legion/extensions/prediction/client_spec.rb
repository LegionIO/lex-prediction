# frozen_string_literal: true

require 'legion/extensions/prediction/client'

RSpec.describe Legion::Extensions::Prediction::Client do
  it 'responds to prediction runner methods' do
    client = described_class.new
    expect(client).to respond_to(:predict)
    expect(client).to respond_to(:resolve_prediction)
    expect(client).to respond_to(:pending_predictions)
    expect(client).to respond_to(:prediction_accuracy)
    expect(client).to respond_to(:get_prediction)
  end
end
