-- FINAL PROJECT-> "Auction strategies for new IPL franchise"

-- Creating table for total matches played from 2008 to 2020
create table ipl_matches(
	match_id integer,
    match_city varchar,
    match_date date,
	player_of_the_match varchar, 
	match_venue varchar,
	match_neutral_venue integer,
    team1 varchar, 
    team2 varchar, 
    toss_winner varchar, 
    toss_decision varchar, 
	winner varchar,
    result varchar,
    win_by_runs integer, 
    win_by_wickets integer, 
	match_tied integer,
	result_margin integer,
	eliminator_match varchar,
	method varchar,
	dl_applied integer, 
    umpire1 varchar, 
    umpire2 varchar
)


--Creating table for total balls delivered from 2008 to 2020
create table deliveries_in_matches (
  match_id integer, 
  inning integer, 
  over integer, 
  ball integer, 
  batsman varchar, 
  non_striker varchar, 
  bowler varchar, 
  batsman_runs integer, 
  extra_runs integer, 
  total_runs integer, 
  is_wicket integer,
  dismissal_kind varchar, 
  player_dismissed varchar,
  fielder varchar, 
  extras varchar,
  batting_team varchar, 
  bowling_team varchar
)


--Imported Data for both the tables from the csv file
copy ipl_matches from 'C:\Program Files\PostgreSQL\16\data\final project data\ipl_matches.csv' delimiter ',' csv header;
copy deliveries_in_matches from 'C:\Program Files\PostgreSQL\16\data\final project data\IPL_Ball.csv' delimiter ',' csv header;


--Viewing the table created to check whether the input data is correct or not
select * from ipl_matches limit 5;
select * from deliveries_in_matches limit 5;


--FIRST QUESTION
/*Your first priority is to get 2-3 players with high S.R who have faced at least 500 balls.
And to do that you have to make a list of 10 players you want to bid in the auction so that when
you try to grab them in auction you should not pay the amount greater than you have in the purse 
for a particular player.*/

--FIRST QUESTION'S SOLUTION
/*STEP 1: Strike rate = (total_runs * 100.0 / total_balls).
  STEP 2: Used HAVING COUNT(*) >= 500 to filter batsmen who have faced at least 500 balls.
  STEP 3: Order the results by strike rate in descending order and limit the results to the top 10 players.*/

with player_strike_rate as (
    select
        batsman,
        sum(batsman_runs) as total_runs,
        count(*) as total_balls,
        (sum(batsman_runs) * 100.0 / count(*)) as strike_rate
    from deliveries_in_matches
    group by batsman
    having count(*) >= 500
)
select 
    batsman,
    total_runs,
    total_balls,
    strike_rate
from player_strike_rate
order by strike_rate desc
limit 10;


--SECOND QUESTION
/*Now you need to get 2-3 players with good Average who have played more the 2 ipl seasons.
And to do that you have to make a list of 10 players you want to bid in the auction so that 
when you try to grab them in auction you should not pay the amount greater than you have in 
the purse for a particular player.*/

--SECOND QUESTION'S SOLUTION
/*STEP 1: To get the players who have more than 2 seasons first we have to identify different
seasons using "MATCH_DATE" column.*/

-- Adding "SEASON" column to the "DELIVERIES_IN_MATCH" table using ALTER TABLE command.
alter table deliveries_in_matches add column season integer;

--Updating the "SEASON" column in the "DELIVERIES_IN_MATCH" table by joining it with the "IPL_MATCHES" table.
update deliveries_in_matches d
set season = extract(year from m.match_date)
from ipl_matches m
where d.match_id = m.match_id;

--Checking the update
select match_id, inning, batsman, bowler, season from deliveries_in_matches limit 10;

/*STEP 2: After lenghty step 1 we need to calculate the batting average for each player to make our list.
  STEP 3: Find the players who have played more than two IPL seasons.
  STEP 4: Also find the players with consistent strike rate
  STEP 5: Select the top 10 players*/

with player_stats as (
    select
        batsman,
        count(distinct season) as seasons_played,
        sum(batsman_runs) as total_runs,
        count(*) as total_balls,
        count(case when dismissal_kind is not NULL then 1 end) as outs,
        (sum(batsman_runs) * 100.0 / count(*)) as strike_rate,
        (sum(batsman_runs) * 1.0 / nullif(count(case when dismissal_kind is not NULL then 1 end), 0)) as average
    from
        deliveries_in_matches d
        join ipl_matches m on d.match_id = m.match_id
    group by batsman
    having 
        count(distinct season) > 2
        and count(*) >= 500
),
consistent_players as (
    select
        batsman,
        total_runs,
        total_balls,
        outs,
        strike_rate,
        average
    from player_stats
    where 
        strike_rate >= 130 -- Assuming a consistent strike rate threshold
    ORDER BY average DESC
    LIMIT 10
)
SELECT
    batsman,
    total_runs,
    total_balls,
    outs,
    strike_rate,
    average
from consistent_players;


--THIRD QUESTION
/*Now you need to get 2-3 Hard-hitting players who have scored most runs in boundaries and 
have played more the 2 ipl season. To do that you have to make a list of 10 players you want
to bid in the auction so that when you try to grab them in auction you should not pay the 
amount greater than you have in the purse for a particular player.*/

--THIRD QUESTION'S SOLUTION
/*STEP 1: Calculated the total runs scored from boundaries (fours and sixes) for each player.
  STEP 2: Filtered players who have played more than two IPL seasons.
  STEP 3: Selected the top 10 players based on the total runs scored from boundaries.*/

with player_boundaries as (
    select
        batsman,
        count(distinct season) as seasons_played,
        sum(case when batsman_runs = 4 then 4 else 0 end) as runs_from_fours,
        sum(case when batsman_runs = 6 then 6 else 0 end) as runs_from_sixes,
        sum(case when batsman_runs in (4, 6) then batsman_runs else 0 end) as total_boundary_runs
    from
        deliveries_in_matches
    group by batsman
    having count(distinct season) > 2
),
top_hard_hitters as (
    select
        batsman,
        runs_from_fours,
        runs_from_sixes,
        total_boundary_runs
    from player_boundaries
    order by total_boundary_runs desc
    limit 10
)
select
    batsman,
    runs_from_fours,
    runs_from_sixes,
    total_boundary_runs
from top_hard_hitters;



--FOURTH QUESTION
/*Your first priority is to get 2-3 bowlers with good economy who have bowled at least 500 balls 
in IPL so far.To do that you have to make a list of 10 players you want to bid in the auction 
so that when you try to grab them in auction you should not pay the amount greater than you have
in the purse for a particular player.*/

--FOURTH QUESTION'S SOLUTION
/*STEP 1: Calculated the total runs conceded by each bowler.
  STEP 2: Calculated the total balls bowled by each bowler and convert it to overs.
  STEP 3: Calculate the economy rate for each bowler "ECONOMY RATE = total runs conceded / total overs bowled".
  STEP 4: Filtered bowlers who have bowled at least 500 balls.
  STEP 5: Selected the top 10 bowlers based on their economy rates.*/

with bowler_stats as (
    select
        bowler,
        count(*) as total_balls,
        sum(total_runs) as total_runs_conceded,
        (sum(total_runs) * 1.0 / (count(*) / 6.0)) as economy_rate
    from
        deliveries_in_matches
    group by bowler
    having count(*) >= 500
)
select
    bowler,
    total_balls,
    total_runs_conceded,
    economy_rate
from bowler_stats
order by economy_rate asc
limit 10;



--FIFTH QUESTION
/*Now you need to get 2-3 bowlers with the best strike rate and who have bowled at
least 500 balls in IPL so far.To do that you have to make a list of 10 players you
want to bid in the auction so that when you try to grab them in auction you should 
not pay the amount greater than you have in the purse for a particular player.*/

--FIFTH QUESTION'S SOLUTION
/*STEP 1: Calculated the total balls bowled by each bowler.
  STEP 2: Calculated the total wickets taken by each bowler.
  STEP 3: Calculated the strike rate for each bowler. "STRIKE RATE = total number of balls/ wicket taken "
  STEP 4: Filtered bowlers who have bowled at least 500 balls.
  STEP 5: Selected the top 10 bowlers based on their strike rates. */

with bowler_stats as (
    select
        bowler,
        count(*) as total_balls,
        count(case when dismissal_kind is not NULL then 1 end) as total_wickets,
        (count(*) * 1.0 / nullif(count(case when dismissal_kind is not NULL then 1 end), 0)) as strike_rate
    from
        deliveries_in_matches
    group by bowler
    having count (*) >= 500
)
select
    bowler,
    total_balls,
    total_wickets,
    strike_rate
from bowler_stats
order by strike_rate asc
limit 10;



--SIXTH QUESTION
/*Now you need to get 2-3 All_rounders with the best batting as well as bowling strike
rate and who have faced at least 500 balls in IPL so far and have bowled minimum 300 balls.
To do that you have to make a list of 10 players you want to bid in the auction so that
when you try to grab them in auction you should not pay the amount greater than you have
in the purse for a particular player.*/

--SIXTH QUESTION'S SOLUTION
/*STEP 1: Calculated the batting strike rate for each player who has faced at least 500 balls.
  STEP 2: Calculated the bowling strike rate for each player who has bowled at least 300 balls.
  STEP 3: Identified players who meet both criteria.
  STEP 4: Selected the top 10 all-rounders based on a combined ranking of their batting and bowling strike rates.*/

--STEP 1
with batting_stats as (
    select 
        batsman,
        sum(batsman_runs) as total_runs,
        count(*) as total_balls_faced,
        (sum(batsman_runs) * 100.0 / count(*)) as batting_strike_rate
    from 
        deliveries_in_matches
    group by 
        batsman
    having 
        count(*) >= 500
),

--STEP 2
bowling_stats as (
    select
        bowler,
        count(*) as total_balls_bowled,
        count(case when dismissal_kind is not null then 1 end) as total_wickets,
        (count(*) * 1.0 / nullif(count(case when dismissal_kind is not null then 1 end), 0)) as bowling_strike_rate
    from
        deliveries_in_matches
    group by
        bowler
    having
        count(*) >= 300
),

--STEP 3
all_rounder_stats as (
    select
        b.batsman as player,
        b.total_runs,
        b.total_balls_faced,
        b.batting_strike_rate,
        bw.total_balls_bowled,
        bw.total_wickets,
        bw.bowling_strike_rate
    from
        batting_stats b
    join
        bowling_stats bw
    on
        b.batsman = bw.bowler
)

--STEP 4
select
    player,
    total_runs,
    total_balls_faced,
    batting_strike_rate,
    total_balls_bowled,
    total_wickets,
    bowling_strike_rate
from
    all_rounder_stats
order by
    batting_strike_rate desc, bowling_strike_rate asc
limit 10;



--SEVENTH QUESTION
/*After doing all that you have the list of all the players you are going to bid 
in the auction so create a visual representation in the form of graphs , tables and charts 
to present in front of team management before the auction.*/

--SEVENTH QUESTION'S SOLUTION
/*Bar Chart for Batting Strike Rate vs. Bowling Strike Rate:
Create a bar chart where each player is represented by a bar, with one side of the bar representing 
the batting strike rate and the other side representing the bowling strike rate.

Scatter Plot for Batting Average vs. Economy Rate:
Use a scatter plot to show each player's batting average against their economy rate.
This can help identify players who excel in both batting and bowling.

Table of Player Statistics: 
Present a table listing each player along with their batting strike rate, 
bowling strike rate, total runs, total wickets, etc.

Pie Chart for Player Distribution by Role: 
Create a pie chart to show the distribution of players by their primary role
(batsman, bowler, all-rounder).

Line Chart for Player Performance Over Seasons: 
If data is available, create a line chart showing each player's performance 
(e.g., batting average, bowling strike rate) over different IPL seasons.

Bubble Chart for Player Value: 
Use a bubble chart where the size of the bubble represents the player's auction
value and the position on the chart represents their batting and bowling performance.

Heatmap of Strike Rates: 
Create a heatmap where each player's batting and bowling strike rates are 
represented by colors, allowing for quick comparison.

Comparison Radar Chart: 
Use a radar chart to compare multiple player attributes such as batting average, 
bowling strike rate, economy rate, etc., for each player.

Stacked Bar Chart for Boundary Runs vs. Wickets: 
Display a stacked bar chart showing the breakdown of each player's runs 
scored from boundaries and wickets taken.

Histogram for Player Frequency by Strike Rate: 
Create a histogram showing the frequency distribution of players based on their
batting and bowling strike rates.
*/

/* STEPS TO VISUALIZE THE DATA
STEP 1: First we need to extract the data in the form through which later it can be visualized such as ".csv" exttension.
STEP 2: Then we need to use either python libraries or excel to visulize the data.
Step 3: We can make all the graphs mentioned above*/

/* ----------------*********-----------------********-------------------- */





--Additional Questions for Final Assessment
/*NOTE: Instead of deliveries I created the "deliveries_in_matches" table and 
instead of "Matches" I created the "ipl_matches". I chose this names
because I wanted to add my touch in naming the tables.*/

--Additional Question 1
/*Get the count of cities that have hosted an IPL match*/

--Additional Question's Solution 1
select count(distinct match_city) as city_count
from ipl_matches;

--Additional Question 2
/*Create table deliveries_v02 with all the columns of the table ‘deliveries’
and an additional column ball_result containing values boundary, dot or other
depending on the total_run (boundary for >= 4, dot for 0 and other for any other number)*/

--Additional Question's Solution 2
create table deliveries_v02 as
select *,
       case
           when total_runs >= 4 then 'boundary'
           when total_runs = 0 then 'dot'
           else 'other'
       end as ball_result
from deliveries_in_matches;

--Additional Question 3
/*Write a query to fetch the total number of boundaries and dot balls from the deliveries_v02 table*/

--Additional Question's Solution 3
select
    count(case when ball_result = 'boundary' then 1 end) as total_boundaries,
    count(case when ball_result = 'dot' then 1 end) as total_dot_balls
from deliveries_v02;

--Additional Question 4
/*Write a query to fetch the total number of boundaries scored by each team 
from the deliveries_v02 table and order it in descending order of the number of boundaries scored.*/

--Additional Question's Solution 4
select batting_team,
       count(case when ball_result = 'boundary' then 1 end) as total_boundaries
from deliveries_v02
group by batting_team
order by total_boundaries desc;

--Additional Question 5
/*Write a query to fetch the total number of dot balls bowled by each team
and order it in descending order of the total number of dot balls bowled*/

--Additional Question's Solution 5
select bowling_team,
       count(case when ball_result = 'dot' then 1 end) as total_dot_balls
from deliveries_v02
group by bowling_team
order by total_dot_balls desc;

--Additional Question 6
/*Write a query to fetch the total number of dismissals by dismissal kinds where dismissal kind is not NA*/

--Additional Question's Solution 6
select dismissal_kind,
       count(*) as total_dismissals
from deliveries
where dismissal_kind is not NULL and dismissal_kind != 'NA'
group by dismissal_kind;

--Additional Question 7
/*Write a query to get the top 5 bowlers who conceded maximum extra runs from the deliveries table*/

--Additional Question's Solution 7
select bowler,
       sum(extra_runs) as total_extra_runs
from deliveries_in_matches
group by bowler
order by total_extra_runs desc
limit 5;

--Additional Question 8
/*Write a query to create a table named deliveries_v03 with all the columns of 
deliveries_v02 table and two additional columns (venue and match_date) from table ipl_matches*/

--Additional Question's Solution 8
create table deliveries_v03 as
select d2.*, m.match_venue, m.match_date as match_date
from deliveries_v02 as d2
join ipl_matches as m on d2.match_id = m.match_id;

--Additional Question 9
/*Write a query to fetch the total runs scored for each venue and order it 
in the descending order of total runs scored*/

--Additional Question's Solution 9
select match_venue,
       sum(total_runs) as total_runs_scored
from deliveries_v03
group by match_venue
order by total_runs_scored desc;

--Additional Question 10
/*Write a query to fetch the year-wise total runs scored at Eden Gardens 
and order it in the descending order of total runs scored*/

--Additional Question's Solution 10
select extract(year from match_date) as year,
       sum(total_runs) as total_runs_scored
from deliveries_v03
where match_venue = 'Eden Gardens'
group by year
order by total_runs_scored desc;
