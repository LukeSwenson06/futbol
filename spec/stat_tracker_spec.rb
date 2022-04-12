require 'simplecov'
SimpleCov.start
require './lib/stat_tracker'
require './lib/game_team'
require 'pry'

describe StatTracker do
  before :each do
    @game_path = './data/games.csv'
    @team_path = './data/teams.csv'
    @game_teams_path = './data/game_teams.csv'

    @locations = {
      games: @game_path,
      teams: @team_path,
      game_teams: @game_teams_path
    }
    @stat_tracker = StatTracker.from_csv(@locations)
  end
  it 'exists' do

  expect(@stat_tracker).to be_an_instance_of(StatTracker)
  end

  it 'has game_teams' do
    expect(@stat_tracker.game_teams[0]).to be_a(GameTeam)
  end
end