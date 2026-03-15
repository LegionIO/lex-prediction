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

  describe '#expire_stale_predictions' do
    it 'returns zero expired when no pending predictions' do
      result = client.expire_stale_predictions
      expect(result[:expired_count]).to eq(0)
      expect(result[:remaining_pending]).to eq(0)
    end

    it 'expires predictions older than their horizon' do
      client.predict(mode: :fault_localization)
      client.predict(mode: :boundary_testing)

      # Simulate staleness by back-dating created_at beyond the horizon
      store = client.send(:prediction_store)
      store.predictions.each_value do |pred|
        pred[:created_at] = Time.now.utc - pred[:horizon] - 1
      end

      result = client.expire_stale_predictions
      expect(result[:expired_count]).to eq(2)
      expect(result[:remaining_pending]).to eq(0)
    end

    it 'preserves predictions that have not exceeded their horizon' do
      client.predict(mode: :fault_localization)
      # created_at is just now, horizon is 3600s — not stale
      result = client.expire_stale_predictions
      expect(result[:expired_count]).to eq(0)
      expect(result[:remaining_pending]).to eq(1)
    end

    it 'only expires stale predictions when mixed with fresh ones' do
      client.predict(mode: :fault_localization)
      stale = client.predict(mode: :boundary_testing)

      store = client.send(:prediction_store)
      stale_pred = store.predictions[stale[:prediction_id]]
      stale_pred[:created_at] = Time.now.utc - stale_pred[:horizon] - 1

      result = client.expire_stale_predictions
      expect(result[:expired_count]).to eq(1)
      expect(result[:remaining_pending]).to eq(1)
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
