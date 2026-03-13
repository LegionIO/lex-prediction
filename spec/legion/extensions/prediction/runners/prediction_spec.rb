# frozen_string_literal: true

require 'legion/extensions/prediction/client'

RSpec.describe Legion::Extensions::Prediction::Runners::Prediction do
  let(:client) { Legion::Extensions::Prediction::Client.new }

  describe '#predict' do
    it 'creates a prediction with valid mode' do
      result = client.predict(mode: :fault_localization, description: 'test')
      expect(result[:prediction_id]).to match(/\A[0-9a-f-]{36}\z/)
      expect(result[:mode]).to eq(:fault_localization)
    end

    it 'rejects invalid mode' do
      result = client.predict(mode: :invalid)
      expect(result[:error]).to eq(:invalid_mode)
    end

    it 'marks actionable predictions above confidence threshold' do
      result = client.predict(mode: :fault_localization, confidence: 0.9)
      expect(result[:actionable]).to be true
    end

    it 'marks non-actionable predictions below threshold' do
      result = client.predict(mode: :counterfactual, confidence: 0.3)
      expect(result[:actionable]).to be false
    end

    it 'estimates confidence based on mode' do
      fault = client.predict(mode: :fault_localization)
      counterfactual = client.predict(mode: :counterfactual)
      expect(fault[:confidence]).to be > counterfactual[:confidence]
    end
  end

  describe '#resolve_prediction' do
    it 'resolves a pending prediction' do
      pred = client.predict(mode: :functional_mapping)
      result = client.resolve_prediction(prediction_id: pred[:prediction_id], outcome: :correct)
      expect(result[:resolved]).to be true
    end

    it 'returns not_found for missing prediction' do
      result = client.resolve_prediction(prediction_id: 'nonexistent', outcome: :correct)
      expect(result[:resolved]).to be false
    end
  end

  describe '#pending_predictions' do
    it 'lists pending predictions' do
      client.predict(mode: :fault_localization)
      client.predict(mode: :boundary_testing)
      result = client.pending_predictions
      expect(result[:count]).to eq(2)
    end
  end

  describe '#prediction_accuracy' do
    it 'computes accuracy' do
      3.times do
        pred = client.predict(mode: :fault_localization)
        client.resolve_prediction(prediction_id: pred[:prediction_id], outcome: :correct)
      end
      pred = client.predict(mode: :fault_localization)
      client.resolve_prediction(prediction_id: pred[:prediction_id], outcome: :incorrect)

      result = client.prediction_accuracy
      expect(result[:accuracy]).to eq(0.75)
    end
  end
end
