select *,
case when variant_total <> 100
    then "Variant Split Does Not Add Up."
    else ''
    end as comment_
from (
select
    planner_campaign.id as 'campaign_id'
    ,planner_campaign.name as 'campaign_name'
    ,planner_tactic.id as 'tactic_id'
    ,planner_tactic.name as 'tactic_name'
    ,planner_cell.id as 'cell_id'
    ,planner_cell.name as 'cell_name'
    ,sum(planner_variant.population_split) as variant_total

from planner_marketingprogram
left join planner_initiative on planner_initiative.marketing_program_id = planner_marketingprogram.id
left join planner_campaign on planner_initiative.id = planner_campaign.initiative_id
left join planner_distributionchannel  on planner_campaign.distribution_channel_id = planner_distributionchannel.id
left join planner_campaigntype on planner_campaign.campaign_type_id = planner_campaigntype.id
left join planner_tactic on planner_campaign.id = planner_tactic.campaign_id
left join planner_tactictype on planner_tactictype.id = planner_tactic.type_id
left join planner_cell on planner_tactic.id = planner_cell.tactic_id
left join planner_variant on planner_cell.id = planner_variant.cell_id
where planner_campaign.name = '{}'
group by
    planner_campaign.id
    ,planner_campaign.name
    ,planner_tactic.id
    ,planner_tactic.name
    ,planner_cell.id
    ,planner_cell.name
) var_check
order by
    case when variant_total <> 100
    then "Variant Split Does Not Add Up."
    else ''
    end desc,
    tactic_name,
    cell_id
