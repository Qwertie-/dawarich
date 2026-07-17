# frozen_string_literal: true

class FogOfWarTileJob < ApplicationJob
  queue_as :default
  sidekiq_options retry: 3

  H3_RESOLUTION = 8

  def perform(point_id)
    point = Point.find(point_id)
    return if point.lonlat.blank?

    lat = point.lonlat.y
    lng = point.lonlat.x

    h3_index = H3.from_geo_coordinates([lat, lng], H3_RESOLUTION).to_s(16)

    FogOfWarTile.find_or_create_by!(user_id: point.user_id, h3_index: h3_index)

    point.update_column(:fog_of_war_calculated_at, Time.current)
  end
end