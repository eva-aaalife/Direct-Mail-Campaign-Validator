with tab1 as (Select  Distinct
    (planner_marketingprogram.id) as 'marketing_program_id'
    , planner_marketingprogram.NAME as 'marketing_program_name'
    ,planner_marketingprogram.description as 'marketing_program_desc'
    , planner_marketingprogram.created_date as 'marketing_program_created_date'
    , planner_initiative.id as 'planner_initiative_id'
    , planner_initiative.name as 'planner_initiative_name'
    , planner_initiative.description as 'planner_initiative_description'
    , planner_initiative.start_date as 'planner_initiative_start_date'
    ,planner_initiative.end_date as 'planner_initiative_end_date'
    , planner_initiative.created_date as 'planner_initiative_created_date'
    ,planner_campaign.id as 'planner_campaign_id'
    ,planner_campaign.name as 'planner_campaign_name'
    ,planner_campaign.description as 'planner_campaign_description'
    ,planner_campaign.start_date as 'planner_campaign_start_date'
    ,planner_campaign.end_date as 'planner_campaign_end_date'
    ,planner_campaign.finance_year as 'planner_campaign_finance_year'
    ,planner_campaign.finance_month as 'planner_campaign_finance_month'
    ,case when length(planner_campaign.keycode_campaign_number) > 1 then null else planner_campaign.keycode_campaign_number end as 'planner_campaign_keycode_camp_number'
    ,planner_campaign.created_date as 'planner_campaign_created_date'
    ,planner_campaigntype.id as 'planner_campaigntype_id'
    ,planner_campaigntype.name as 'planner_campaigntype_name'
    ,planner_campaigntype.description as 'planner_campaigntype_description'
    ,planner_campaigntype.created_date as 'planner_campaigntype_created_date'
    ,planner_distributionchannel.id as 'planner_distributionchannel_id'
    ,planner_distributionchannel.name as 'planner_distributionchannel_name'
    ,planner_distributionchannel.description as 'planner_distributionchannel_description'
    ,planner_distributionchannel.created_date as 'planner_distributionchannel_created_date'
    ,planner_tactic.id as 'planner_tactic_id'
    ,planner_tactic.name as 'planner_tactic_name'
    ,planner_tactic.created_date as 'planner_tactic_created_date'
    , planner_cell.id as 'planner_cell_id'
    , planner_cell.name as 'planner_cell_name'
    , left(planner_cell.description,29) as 'planner_cell_description'
    , planner_cell.created_date as 'planner_cell_created_date'
    , planner_variant.id as 'planner_variant_id'
    , planner_variant.name as 'planner_variant_name'
    , planner_variant.created_date as 'planner_variant_created_date'
    , planner_touch.id as 'planner_touch_id'
    , planner_touch.name as 'planner_touch_name'
    , planner_touch.created_date as 'planner_touch_created_date'
    , planner_touch.variant_id as 'planner_touch_variant_id'

from planner_marketingprogram
left join planner_initiative on planner_initiative.marketing_program_id = planner_marketingprogram.id
left join planner_campaign on planner_initiative.id = planner_campaign.initiative_id
left join planner_distributionchannel  on planner_campaign.distribution_channel_id = planner_distributionchannel.id
left join planner_campaigntype on planner_campaign.campaign_type_id = planner_campaigntype.id
left join planner_tactic on planner_campaign.id = planner_tactic.campaign_id
left join planner_tactictype on planner_tactictype.id = planner_tactic.type_id
left join planner_cell on planner_tactic.id = planner_cell.tactic_id
left join planner_variant on planner_cell.id = planner_variant.cell_id
left join planner_touch on planner_variant.id = planner_touch.variant_id
)
select distinct
    'Orphan Touch' as orphan_type,
    planner_touch_id as orphan_id,
    planner_touch_name as orphan_name,
    planner_touch_created_date as orphan_created_date,
    'Not attached to any variant' as explainer,
    '' as sign_off
from tab1
where planner_touch_variant_id is null
and planner_distributionchannel_id <> 2
and planner_touch_id is not null
union
select distinct
    'Orphan Cell' as orphan_type,
    planner_cell_id as orphan_id,
    planner_cell_name as orphan_name,
    planner_cell_created_date as orphan_created_date,
    'No variant attached' as explainer,
    '' as sign_off
from tab1
where planner_variant_id is null
and planner_distributionchannel_id <> 2
and planner_cell_id is not null

union

select distinct
    'Orphan Tactic' as orphan_type,
    planner_tactic_id as orphan_id,
    planner_tactic_name as orphan_name,
    planner_tactic_created_date as orphan_created_date,
    'No cell attached' as explainer,
    '' as sign_off
from tab1
where planner_cell_id is null
and planner_distributionchannel_id <> 2
and planner_tactic_id is not null

union

select distinct
    'Orphan Campaign' as orphan_type,
    planner_campaign_id as orphan_id,
    planner_campaign_name as orphan_name,
    planner_campaign_created_date  as orphan_created_date,
    'No tactic attached' as explainer,
    '' as sign_off
from tab1
where planner_tactic_id is null
and planner_distributionchannel_id <> 2
and planner_campaign_id is not null
