# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::Prediction::Helpers::PredictionStore do
  subject(:store) { described_class.new }

  let(:basic_prediction) do
    {
      mode:        :fault_localization,
      confidence:  0.75,
      description: 'disk latency spike incoming',
      status:      :pending
    }
  end

  describe '#initialize' do
    it 'starts with empty predictions hash' do
      expect(store.predictions).to eq({})
    end

    it 'starts with empty outcomes array' do
      expect(store.outcomes).to eq([])
    end
  end

  describe '#store' do
    it 'returns a UUID string' do
      id = store.store(basic_prediction.dup)
      expect(id).to match(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/)
    end

    it 'stores the prediction under the returned id' do
      id = store.store(basic_prediction.dup)
      expect(store.predictions[id]).not_to be_nil
    end

    it 'sets prediction_id on the prediction hash' do
      prediction = basic_prediction.dup
      id = store.store(prediction)
      expect(prediction[:prediction_id]).to eq(id)
    end

    it 'preserves a caller-supplied prediction_id' do
      prediction = basic_prediction.merge(prediction_id: 'my-custom-id')
      returned_id = store.store(prediction)
      expect(returned_id).to eq('my-custom-id')
      expect(store.predictions['my-custom-id']).not_to be_nil
    end

    it 'sets created_at when not supplied' do
      prediction = basic_prediction.dup
      before = Time.now.utc
      store.store(prediction)
      expect(prediction[:created_at]).to be >= before
    end

    it 'preserves a caller-supplied created_at' do
      custom_time = Time.now.utc - 3600
      prediction  = basic_prediction.merge(created_at: custom_time)
      store.store(prediction)
      expect(prediction[:created_at]).to eq(custom_time)
    end

    it 'sets default status to :pending' do
      prediction = { mode: :counterfactual, confidence: 0.5 }
      store.store(prediction)
      expect(prediction[:status]).to eq(:pending)
    end

    it 'preserves a caller-supplied status' do
      prediction = basic_prediction.merge(status: :expired)
      store.store(prediction)
      expect(prediction[:status]).to eq(:expired)
    end

    it 'increments count with each stored prediction' do
      3.times { store.store(basic_prediction.dup) }
      expect(store.count).to eq(3)
    end
  end

  describe '#get' do
    it 'retrieves a stored prediction by id' do
      id = store.store(basic_prediction.dup)
      result = store.get(id)
      expect(result[:mode]).to eq(:fault_localization)
    end

    it 'returns nil for an unknown id' do
      expect(store.get('no-such-id')).to be_nil
    end
  end

  describe '#resolve' do
    let!(:prediction_id) { store.store(basic_prediction.dup) }

    it 'returns the updated prediction' do
      result = store.resolve(prediction_id, outcome: :correct)
      expect(result).to be_a(Hash)
      expect(result[:prediction_id]).to eq(prediction_id)
    end

    it 'sets status to the given outcome' do
      store.resolve(prediction_id, outcome: :incorrect)
      expect(store.get(prediction_id)[:status]).to eq(:incorrect)
    end

    it 'sets resolved_at timestamp' do
      before = Time.now.utc
      store.resolve(prediction_id, outcome: :correct)
      expect(store.get(prediction_id)[:resolved_at]).to be >= before
    end

    it 'stores actual value when provided' do
      store.resolve(prediction_id, outcome: :partial, actual: 'disk io at 80%')
      expect(store.get(prediction_id)[:actual]).to eq('disk io at 80%')
    end

    it 'stores nil actual when not provided' do
      store.resolve(prediction_id, outcome: :correct)
      expect(store.get(prediction_id)[:actual]).to be_nil
    end

    it 'appends to outcomes array' do
      store.resolve(prediction_id, outcome: :correct)
      expect(store.outcomes.size).to eq(1)
    end

    it 'records prediction_id in the outcome entry' do
      store.resolve(prediction_id, outcome: :correct)
      expect(store.outcomes.last[:prediction_id]).to eq(prediction_id)
    end

    it 'records outcome in the outcome entry' do
      store.resolve(prediction_id, outcome: :incorrect)
      expect(store.outcomes.last[:outcome]).to eq(:incorrect)
    end

    it 'returns nil for a non-existent prediction_id' do
      result = store.resolve('ghost-id', outcome: :correct)
      expect(result).to be_nil
    end

    it 'caps outcomes array at 500 entries' do
      501.times do
        id = store.store(basic_prediction.dup)
        store.resolve(id, outcome: :correct)
      end
      expect(store.outcomes.size).to eq(500)
    end
  end

  describe '#pending' do
    it 'returns only predictions with status :pending' do
      id1 = store.store(basic_prediction.dup)
      id2 = store.store(basic_prediction.dup)
      store.resolve(id1, outcome: :correct)

      result = store.pending
      expect(result.size).to eq(1)
      expect(result.first[:prediction_id]).to eq(id2)
    end

    it 'returns empty array when no pending predictions' do
      id = store.store(basic_prediction.dup)
      store.resolve(id, outcome: :correct)
      expect(store.pending).to be_empty
    end

    it 'returns all stored predictions when none are resolved' do
      3.times { store.store(basic_prediction.dup) }
      expect(store.pending.size).to eq(3)
    end
  end

  describe '#accuracy' do
    it 'returns 0.0 when no outcomes exist' do
      expect(store.accuracy).to eq(0.0)
    end

    it 'returns 1.0 when all outcomes are :correct' do
      3.times do
        id = store.store(basic_prediction.dup)
        store.resolve(id, outcome: :correct)
      end
      expect(store.accuracy).to eq(1.0)
    end

    it 'returns 0.0 when all outcomes are :incorrect' do
      3.times do
        id = store.store(basic_prediction.dup)
        store.resolve(id, outcome: :incorrect)
      end
      expect(store.accuracy).to eq(0.0)
    end

    it 'computes fractional accuracy correctly' do
      3.times do
        id = store.store(basic_prediction.dup)
        store.resolve(id, outcome: :correct)
      end
      id = store.store(basic_prediction.dup)
      store.resolve(id, outcome: :incorrect)
      expect(store.accuracy).to eq(0.75)
    end

    it 'defaults window to 100' do
      102.times do
        id = store.store(basic_prediction.dup)
        store.resolve(id, outcome: :incorrect)
      end
      2.times do
        id = store.store(basic_prediction.dup)
        store.resolve(id, outcome: :correct)
      end
      # window=100: last 100 contain 2 correct out of 100 = 0.02
      expect(store.accuracy(window: 100)).to eq(0.02)
    end

    it 'accepts a custom window parameter' do
      5.times do
        id = store.store(basic_prediction.dup)
        store.resolve(id, outcome: :incorrect)
      end
      5.times do
        id = store.store(basic_prediction.dup)
        store.resolve(id, outcome: :correct)
      end
      # window=5: last 5 are all :correct
      expect(store.accuracy(window: 5)).to eq(1.0)
    end

    it 'ignores non-:correct outcomes in numerator' do
      id = store.store(basic_prediction.dup)
      store.resolve(id, outcome: :partial)
      id = store.store(basic_prediction.dup)
      store.resolve(id, outcome: :expired)
      id = store.store(basic_prediction.dup)
      store.resolve(id, outcome: :correct)
      expect(store.accuracy).to be_within(0.001).of(1.0 / 3.0)
    end
  end

  describe '#count' do
    it 'returns 0 for a new store' do
      expect(store.count).to eq(0)
    end

    it 'returns the total number of stored predictions' do
      5.times { store.store(basic_prediction.dup) }
      expect(store.count).to eq(5)
    end

    it 'counts resolved predictions as well as pending ones' do
      id = store.store(basic_prediction.dup)
      store.resolve(id, outcome: :correct)
      store.store(basic_prediction.dup)
      expect(store.count).to eq(2)
    end
  end
end
