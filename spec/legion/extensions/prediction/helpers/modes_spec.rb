# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::Prediction::Helpers::Modes do
  describe 'REASONING_MODES' do
    it 'is a frozen array of symbols' do
      expect(described_class::REASONING_MODES).to be_a(Array)
      expect(described_class::REASONING_MODES).to be_frozen
    end

    it 'contains exactly four modes' do
      expect(described_class::REASONING_MODES.size).to eq(4)
    end

    it 'includes fault_localization' do
      expect(described_class::REASONING_MODES).to include(:fault_localization)
    end

    it 'includes functional_mapping' do
      expect(described_class::REASONING_MODES).to include(:functional_mapping)
    end

    it 'includes boundary_testing' do
      expect(described_class::REASONING_MODES).to include(:boundary_testing)
    end

    it 'includes counterfactual' do
      expect(described_class::REASONING_MODES).to include(:counterfactual)
    end

    it 'contains only symbols' do
      expect(described_class::REASONING_MODES).to all(be_a(Symbol))
    end
  end

  describe 'PREDICTION_CONFIDENCE_MIN' do
    it 'is 0.65' do
      expect(described_class::PREDICTION_CONFIDENCE_MIN).to eq(0.65)
    end

    it 'is a float' do
      expect(described_class::PREDICTION_CONFIDENCE_MIN).to be_a(Float)
    end

    it 'is in the valid 0.0-1.0 range' do
      expect(described_class::PREDICTION_CONFIDENCE_MIN).to be_between(0.0, 1.0)
    end
  end

  describe 'MAX_PREDICTIONS_PER_TICK' do
    it 'is 5' do
      expect(described_class::MAX_PREDICTIONS_PER_TICK).to eq(5)
    end

    it 'is an integer' do
      expect(described_class::MAX_PREDICTIONS_PER_TICK).to be_an(Integer)
    end

    it 'is positive' do
      expect(described_class::MAX_PREDICTIONS_PER_TICK).to be > 0
    end
  end

  describe 'PREDICTION_HORIZON' do
    it 'is 3600' do
      expect(described_class::PREDICTION_HORIZON).to eq(3600)
    end

    it 'is an integer' do
      expect(described_class::PREDICTION_HORIZON).to be_an(Integer)
    end

    it 'represents one hour in seconds' do
      expect(described_class::PREDICTION_HORIZON).to eq(60 * 60)
    end
  end

  describe '.valid_mode?' do
    it 'returns true for fault_localization' do
      expect(described_class.valid_mode?(:fault_localization)).to be true
    end

    it 'returns true for functional_mapping' do
      expect(described_class.valid_mode?(:functional_mapping)).to be true
    end

    it 'returns true for boundary_testing' do
      expect(described_class.valid_mode?(:boundary_testing)).to be true
    end

    it 'returns true for counterfactual' do
      expect(described_class.valid_mode?(:counterfactual)).to be true
    end

    it 'returns false for an unknown mode symbol' do
      expect(described_class.valid_mode?(:neural_network)).to be false
    end

    it 'returns false for a string form of a valid mode' do
      expect(described_class.valid_mode?('fault_localization')).to be false
    end

    it 'returns false for nil' do
      expect(described_class.valid_mode?(nil)).to be false
    end

    it 'returns false for an integer' do
      expect(described_class.valid_mode?(42)).to be false
    end

    it 'returns true for all REASONING_MODES members' do
      described_class::REASONING_MODES.each do |mode|
        expect(described_class.valid_mode?(mode)).to be true
      end
    end
  end
end
