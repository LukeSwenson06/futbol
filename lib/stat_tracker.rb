require_relative '../required_files'

class StatTracker
	include TeamModule
	include GameModule
	include LeagueModule
	include SeasonModule

	attr_reader :games, :teams, :game_teams

	def initialize(games_hash, teams_hash, game_teams_hash)
		@games = Game.create_games(games_hash)
		@teams = Team.create_teams(teams_hash)
		@game_teams = GameTeam.create_game_teams(game_teams_hash)
	end

	def self.from_csv(locations)
	 games_hash = CSV.open(locations[:games], headers: true, header_converters: :symbol)
	 teams_hash = CSV.open(locations[:teams], headers: true, header_converters: :symbol)
	 game_teams_hash = CSV.open(locations[:game_teams], headers: true, header_converters: :symbol)
	 stat_tracker1 = self.new(games_hash, teams_hash, game_teams_hash)
	end

	def game_count
		@games.count
	end

	def highest_total_score
		GameModule.total_score(@games).max
	end

	def lowest_total_score
		GameModule.total_score(@games).min
	end

	def percentage_visitor_wins
		return ((GameModule.total_visitor_wins(@games).count).to_f / (@games.count).to_f).round(2)
	end

	def percentage_home_wins
		return ((GameModule.total_home_wins(@games).count).to_f / game_count.to_f).round(2)
	end

	def average_goals_per_game
		(GameModule.total_score(@games).sum.to_f / game_count).round(2)
	end

	def average_goals_by_season
		season_goals_avg = GameModule.season_goals(@games)
		season_goals_avg.each do |season, goals|
			season_goals_avg[season] = (goals.sum.to_f / goals.count.to_f).round(2)
		end
		return season_goals_avg
	end

	def count_of_teams
		LeagueModule.total_team_count(@teams).count
	end

	def team_info(team_id)
		team_hash = {}
		team = @teams.find { |team| team.team_id.to_i == team_id.to_i }
		team_hash[:team_id] = team.team_id.to_i
		team_hash[:franchise_id] = team.franchise_id.to_i
		team_hash[:team_name] = team.team_name
		team_hash[:abbreviation] = team.abbreviation
		team_hash[:link] = team.link
		team_hash
	end

	def best_season(team_id)
		 season_win_percentage_hash = TeamModule.season_win_percentages(team_id.to_i, @game_teams)
		 best_season = season_win_percentage_hash.invert.max
		 best_game = @games.find do |game|
		  best_season[1] == game.season[0..3]
		end
		best_game.season
	end

	def worst_season(team_id)
		 season_win_percentage_hash = TeamModule.season_win_percentages(team_id.to_i, @game_teams)
	 	 best_season = season_win_percentage_hash.invert.min
	 	 best_game = @games.find do |game|
	 		best_season[1] == game.season[0..3]
	 	end
 		best_game.season
	end

	def most_tackles(season_id)
		tackles_hash = SeasonModule.tackles_hash(season_id, @game_teams)
		tackle_id = tackles_hash.sort_by{|team_id, tackles| tackles}.last[0]
		LeagueModule.team_name_by_id(tackle_id, @teams)
	end

	def least_tackles(season_id)
		tackles_hash = SeasonModule.tackles_hash(season_id, @game_teams)
		tackle_id = tackles_hash.sort_by{|team_id, tackles| tackles}.first[0]
		LeagueModule.team_name_by_id(tackle_id, @teams)
	end

	def average_win_percentage(team_id)
		games_by_team_arr = @game_teams.find_all { |game| game.team_id.to_i == team_id.to_i }
		results_arr = games_by_team_arr.map { |games| games.result }
		wins = results_arr.count("WIN")
		win_percentage = (wins.to_f / results_arr.count.to_f).round(2)
		return win_percentage
	end

	def best_offense
		team_goals = LeagueModule.get_team_goals(@game_teams)
		avg_goals = LeagueModule.goals_average(team_goals)
		name_of_teams = LeagueModule.team_names(@teams)
		team_id_to_team_names = LeagueModule.id_to_name(avg_goals, name_of_teams)
		LeagueModule.max_avg_goals(team_id_to_team_names)
	end

	def worst_offense
		team_goals = LeagueModule.get_team_goals(@game_teams)
		avg_goals = LeagueModule.goals_average(team_goals)
		name_of_teams = LeagueModule.team_names(@teams)
		team_id_to_team_names = LeagueModule.id_to_name(avg_goals, name_of_teams)
		LeagueModule.min_avg_goals(team_id_to_team_names)
	end

	def most_goals_scored(team_id)
		LeagueModule.goals_scored(team_id, @game_teams).max
	end

	def fewest_goals_scored(team_id)
		LeagueModule.goals_scored(team_id, @game_teams).min
  end

	def winningest_coach(season)
		SeasonModule.best_coach(season, @game_teams)
  end

	def worst_coach(season)
		SeasonModule.worst_coach(season, @game_teams)
	end

	def most_accurate_team(season)
		SeasonModule.best_team(season, @game_teams, @teams)
	end

	def least_accurate_team(season)
		SeasonModule.worst_team(season, @game_teams, @teams)
  end

	def percentage_ties
		ties = @games.select { |game| game.home_goals == game.away_goals }
		return ((ties.count.to_f / game_count.to_f)).round(2)
	end

	def count_of_games_by_season
		seasons_arr = @games.map { |game| game.season }
		game_count_by_season = Hash.new
		seasons_arr.uniq.each do |season|
			game_count_by_season[season] = seasons_arr.count(season)
		end
		return game_count_by_season
	end

  def favorite_opponent(team_id)
		TeamModule.find_fav_opponent(team_id, @teams, @game_teams)
  end

	def rival(team_id)
		TeamModule.find_rival(team_id, @teams, @game_teams)
	end

	def highest_scoring_visitor
		team_id = LeagueModule.average_visitor_scores(@games).invert.max.last
		LeagueModule.team_name_by_id(team_id.to_i, @teams)
	end

	def lowest_scoring_visitor
		team_id = LeagueModule.average_visitor_scores(@games).invert.min.last
		LeagueModule.team_name_by_id(team_id.to_i, @teams)
	end

	def highest_scoring_home_team
		team_id = LeagueModule.average_home_scores(@games).invert.max.last
		LeagueModule.team_name_by_id(team_id.to_i, @teams)
	end

	def lowest_scoring_home_team
		team_id = LeagueModule.average_home_scores(@games).invert.min.last
		LeagueModule.team_name_by_id(team_id.to_i, @teams)
	end

end
