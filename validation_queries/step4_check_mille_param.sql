
with metadata as (
Select  Distinct
    planner_campaign.id as 'campaign_id'
    ,planner_campaign.name as 'campaign_name'
    ,planner_tactic.id as 'tactic_id'
    ,planner_tactic.name as 'tactic_name'
    ,planner_cell.id as 'cell_id'
    ,planner_cell.name as 'cell_name'
    ,predictive_models_predictivemodel.name as model_name
    ,predictive_models_predictivemodelselection.minimum_mille as 'model_min_mille'
    ,predictive_models_predictivemodelselection.maximum_mille as 'Model_max_mille'
    ,clubs_club.number as 'mtd_club_number'
    ,geo_state.abbreviation as 'mtd_st_cd'
from planner_marketingprogram
left join planner_initiative on planner_initiative.marketing_program_id = planner_marketingprogram.id
left join planner_campaign on planner_initiative.id = planner_campaign.initiative_id
left join planner_distributionchannel  on planner_campaign.distribution_channel_id = planner_distributionchannel.id
left join planner_campaigntype on planner_campaign.campaign_type_id = planner_campaigntype.id
left join planner_tactic on planner_campaign.id = planner_tactic.campaign_id
left join planner_tactictype on planner_tactictype.id = planner_tactic.type_id
left join planner_cell on planner_tactic.id = planner_cell.tactic_id
left join  campaign_parameters_selectionparameters
    on planner_cell.parameters_id = campaign_parameters_selectionparameters.id
left outer join predictive_models_predictivemodelbundle
on campaign_parameters_selectionparameters.predictive_models_id = predictive_models_predictivemodelbundle.id
left outer join predictive_models_predictivemodelbundle_selection
on predictive_models_predictivemodelbundle.id = predictive_models_predictivemodelbundle_selection.predictivemodelbundle_id
left outer join predictive_models_predictivemodelselection
on predictive_models_predictivemodelbundle_selection.predictivemodelselection_id = predictive_models_predictivemodelselection.id
left outer join predictive_models_predictivemodel
on predictive_models_predictivemodelselection.predictive_model_id = predictive_models_predictivemodel.id

join clubs_selectiongroup on planner_cell.group_id = clubs_selectiongroup.id
join clubs_selectiongroup_club_states  on clubs_selectiongroup.id = clubs_selectiongroup_club_states.selectiongroup_id
join clubs_clubstate on clubs_selectiongroup_club_states.clubstate_id = clubs_clubstate.id
join geo_state on clubs_clubstate.state_id = geo_state.id
join clubs_club on clubs_clubstate.club_id = clubs_club.id


where planner_campaign.name = '{}'
),
ms_param as (
select
    distinct
        tactic_name,
        reporting_group_name,
        estimated_mille,
        resident_club_code,
        States
from validation.mailing_schedule_agg
where campaign_name = (select distinct campaign_name from metadata)

)
select distinct
    metadata.campaign_id,
    metadata.campaign_name,
    metadata.tactic_id,
    metadata.tactic_name,
    metadata.model_name,
    case
        when (metadata.tactic_name ='Direct Mail Member Term' and reporting_group_name = 'ACE') and metadata.model_name in ('Member Term Ace' ) then  'OK'
        when metadata.tactic_name ='Direct Mail Member Term' and metadata.model_name in ('Member Term' ) then  'OK'
        when metadata.tactic_name ='GIWL Member' and metadata.model_name in ('Member GIWL' ) then  'OK'
        when metadata.tactic_name ='GIWL Non-Member' and metadata.model_name in ('Broadmarket GIWL','GIWL Broad Market' ) then  'OK'
        when metadata.tactic_name ='Individual Direct Term Non-Member' and metadata.model_name in ('Individual Term Broad Market','Broadmarket Individual Term' ) then  'OK'
        when metadata.tactic_name ='MLTA Member' and metadata.model_name in ('Member MLTA' ) then  'OK'
        else 'WRONG MODEL ATTACHED'
        end as Check_model,
    ms_param.reporting_group_name,
    metadata.cell_name,
    metadata.model_min_mille,
    metadata.Model_max_mille,
    estimated_mille,
    case when ifNull(metadata.Model_max_mille,0) <> IFnull(estimated_mille,0)
    then 'Not Match' else '' end as Check_mille
from metadata
left join ms_param
    on metadata.tactic_name = ms_param.tactic_name
     and metadata.mtd_club_number = ms_param.resident_club_code
     and metadata.mtd_st_cd = ms_param.States
where metadata.tactic_name not like '%CS%'
Order by
    case
        when (metadata.tactic_name ='Direct Mail Member Term' and reporting_group_name = 'ACE') and metadata.model_name in ('Member Term Ace' ) then  'OK'
        when metadata.tactic_name ='Direct Mail Member Term' and metadata.model_name in ('Member Term' ) then  'OK'
        when metadata.tactic_name ='GIWL Member' and metadata.model_name in ('Member GIWL' ) then  'OK'
        when metadata.tactic_name ='GIWL Non-Member' and metadata.model_name in ('Broadmarket GIWL','GIWL Broad Market' ) then  'OK'
        when metadata.tactic_name ='Individual Direct Term Non-Member' and metadata.model_name in ('Individual Term Broad Market','Broadmarket Individual Term' ) then  'OK'
        when metadata.tactic_name ='MLTA Member' and metadata.model_name in ('Member MLTA' ) then  'OK'
        else 'WRONG MODEL ATTACHED'
        end,
    case when ifNull(metadata.Model_max_mille,0) <> IFnull(estimated_mille,0)
    then 'Not Match' else '' end Desc,
    metadata.tactic_name,
    ms_param.reporting_group_name
