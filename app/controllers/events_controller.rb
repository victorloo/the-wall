class EventsController < ApplicationController

  ALLOW_QUERIES = %w[s artist_name_cont title_cont city_cont date_cont time_cont stage_eq stage_cont views_count interests_count detail_cont artist_name_or_title_or_city_or_detail_cont].freeze

  def index
    @events = Event.all.order(date: :desc)
    # ransack
    @q = Event.ransack(ransack_params)
    @events = @q.result(distinct: true)

  end

  def show
    @event = Event.find(params[:id])

    # views count
    @event.count_views
    if current_user
      if current_user.viewed_events.include?(@event)
        @view = current_user.views.where(event_id: @event)
        @view.destroy_all
      end
      current_user.views.create(event_id: params[:id])
    end

    # spotify
    if @event.artist_name != nil
      artist_name = @event.artist_name
      
      if @event.spotify_artist_id == nil
        @spotify_data = Event.get_spotify_data(artist_name)
        if @spotify_data == nil
          @spotify_artist_id = nil
        else
          @spotify_artist_id = @spotify_data.id
          @event.spotify_artist_id = @spotify_artist_id
          @event.save
        end
      else
        @spotify_artist_id = @event.spotify_artist_id
      end
    end
  end

  private 

  def ransack_params
    if params[:q].present?
      params.require(:q).permit(*ALLOW_QUERIES)
    end
  end

end
