# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FogOfWarTileJob, type: :job do
  describe '#perform' do
    subject(:perform_job) { described_class.new.perform(point.id) }

    let(:user) { create(:user) }
    let(:point) { create(:point, user:, fog_of_war_calculated_at: nil) }

    let(:expected_h3_index) { H3.from_geo_coordinates([point.latitude, point.longitude], 8).to_s(16) }

    it 'creates a fog of war tile with the correct H3 index' do
      expect { perform_job }
        .to change(FogOfWarTile, :count).by(1)

      tile = FogOfWarTile.last
      expect(tile.user_id).to eq(user.id)
      expect(tile.h3_index).to eq(expected_h3_index)
    end

    it 'updates fog_of_war_calculated_at on the point' do
      expect { perform_job }
        .to change { point.reload.fog_of_war_calculated_at }
        .from(nil)
        .to(be_within(1.second).of(Time.current))
    end

    context 'when a tile for the same user and H3 index already exists' do
      let!(:existing_tile) { create(:fog_of_war_tile, user:, h3_index: expected_h3_index) }

      it 'does not create a duplicate tile' do
        expect { perform_job }
          .not_to change(FogOfWarTile, :count)
      end

      it 'still updates fog_of_war_calculated_at' do
        expect { perform_job }
          .to change { point.reload.fog_of_war_calculated_at }
          .from(nil)
      end
    end

    context 'when the point has no lonlat' do
      let(:point) do
        p = create(:point, user:, fog_of_war_calculated_at: nil)
        p.update_column(:lonlat, nil)
        p
      end

      it 'does not create a fog of war tile' do
        expect { perform_job }
          .not_to change(FogOfWarTile, :count)
      end

      it 'does not update fog_of_war_calculated_at' do
        expect { perform_job }
          .not_to change { point.reload.fog_of_war_calculated_at }
      end
    end
  end
end