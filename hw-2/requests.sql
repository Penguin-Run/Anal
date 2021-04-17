-- Тема исследования:
-- Изучение игроков в разных регионах


--- ОБЩИЕ МЕТРИКИ
-- популярность героев среди всех игроков
select hn.localized_name, count(*)
from players left join hero_names hn on players.hero_id = hn.hero_id
group by hn.localized_name
order by count(*) desc

-- герои, по эффективности игроков
select hn.localized_name,
   round(avg(pr.trueskill_mu), 1) as skill_mu,
   sum(pr.total_matches) as matches
from players p
    left join player_ratings pr on p.account_id = pr.account_id
    left join hero_names hn on p.hero_id = hn.hero_id
group by p.hero_id, hn.localized_name
order by skill_mu desc


-- межквартильный размах по умению играть среди всех игроков
select percentile_cont(0.75) within group (order by trueskill_mu) -
       percentile_cont(0.25) within group (order by trueskill_mu) as iqr
from player_ratings;


--- С ДЕЛЕНИЕМ ПО РЕГИОНАМ
-- умение играть по регионам по регионам
with cte as (
    select c.region,
       count(*) as matches_count,
       round(avg(pr.trueskill_mu), 1) as avg_player_skill
    from players p left join match m on p.match_id = m.match_id
        left join cluster_regions c on m.cluster = c.cluster
        left join player_ratings pr on p.account_id = pr.account_id
    group by c.region

)
select * from cte
where matches_count > 500
order by avg_player_skill desc;


-- популярные герои по регионам
with region_group as (
    select cr.region as region,
       hn.localized_name as name,
       count(p.hero_id) as hero_count
from players p left join hero_names hn on p.hero_id = hn.hero_id
               left join match m on p.match_id = m.match_id
               left join cluster_regions cr on m.cluster = cr.cluster
group by cr.region, hn.localized_name
), region_hero_popularity_ranking as (
    select *,
       row_number() over (partition by region order by hero_count desc) as popularity_rank
from region_group
)
select region, name, hero_count
from region_hero_popularity_ranking
where popularity_rank <= 5
order by region, hero_count desc;
