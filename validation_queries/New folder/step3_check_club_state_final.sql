
ms_param as ,
match_mtd as (
select distinct
    metadata.campaign_id,
    metadata.campaign_name,
    metadata.tactic_id,
    metadata.tactic_name,

    metadata.resolved_age_min as mtd_resolved_age_min,
    ms_param.age_min as ms_resolved_age_min,

    case when ifnull(metadata.resolved_age_min,0) <> ifnull(ms_param.age_min,0)
        then 'Not Match' else '' end as check_age_min,

    metadata.resolved_age_max as mtd_resolved_age_max,
    ms_param.age_max as ms_resolved_age_max,
    case when ifnull(metadata.resolved_age_max,0) <> ifnull(ms_param.age_max,0)
        then 'Not Match' else '' end as check_age_max,


    metadata.unknown_age_inclusion,
    ms_param.age_unk as ms_age_unk,
    case when  metadata.unknown_age_inclusion = '1' and ms_param.age_unk = 'Y' then ''
         when  metadata.unknown_age_inclusion = '0' and ms_param.age_unk = 'N' then ''
         when ifnull(metadata.unknown_age_inclusion,'N') <> ifnull(ms_param.age_unk,'N')
         then 'Not Match' else '' end as check_age_unk,


    metadata.mtd_club_number as mtd_club_code,
    metadata.mtd_st_cd as mtd_state,
    ms_param.resident_club_code as ms_club_code,
    ms_param.States as ms_state,
    case when (metadata.mtd_club_number is null or metadata.mtd_st_cd is null)
          and ( ms_param.States is not null AND ms_param.resident_club_code is not null)
        then 'Missing From Metadata. Verify Club-Participation'
    else '' end as check_club_state,

    metadata.variant_id,
    metadata.touch_id,

    metadata.mtd_keycode_10th_position_byte,

    metadata.mtd_package_id as mtd_package_id,
    ms_param.ms_package_id as ms_package_id,
    case when metadata.mtd_package_id <> ms_param.ms_package_id
    then 'Not Match' else '' end as check_package_id,

    metadata.mtd_phone_number as mtd_phone_number,
    ms_param.ms_phone_number as ms_phone_number,

    case when ifnull(metadata.mtd_phone_number,0) <> ifnull(ms_param.ms_phone_number,0)
    then 'Not Match' else '' end as check_phone_number,

    ms_param.tactic_name as ms_tactic_name,
    ms_param.reporting_group_name,

    metadata.reply_by_date as mtd_reply_by_date,

    case when  metadata.tactic_name like '%MLTA%'
            and metadata.mtd_club_number = '004'
            and metadata.mtd_st_cd = 'CA'
          then
        ms_param.reply_by_date
    else '' end
    as ms_reply_by_date,

    case when  metadata.tactic_name like '%MLTA%'
                and metadata.mtd_club_number = '004'
                and metadata.mtd_st_cd = 'CA'
          then
            case when metadata.reply_by_date <> ms_param.reply_by_date
            then 'Not Match' else '' END
          else
          '' END as check_reply_by_date,
    plan_code

from (
Select  Distinct
    planner_campaign.id as 'campaign_id'
    ,planner_campaign.name as 'campaign_name'
    ,planner_tactic.id as 'tactic_id'
    ,planner_tactic.name as 'tactic_name'
    ,campaign_parameters_selectionparameters.resolved_age_min
    ,campaign_parameters_selectionparameters.resolved_age_max
    ,campaign_parameters_selectionparameters.unknown_age_inclusion
    ,clubs_club.number as 'mtd_club_number'
    ,geo_state.abbreviation as 'mtd_st_cd'
    ,planner_variant.id as 'variant_id'
    ,planner_variant.keycode_10th_position_byte as 'mtd_keycode_10th_position_byte'
    ,planner_touch.id as 'touch_id'
    ,creative_packageassignments.creative_id as 'mtd_package_id'
    ,creative_packageassignments.phone_number as 'mtd_phone_number'
    ,planner_touch.reply_by_date
    ,offers_plancode.plan_code as 'plan_code'

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
left join planner_variant on planner_cell.id = planner_variant.cell_id
left join planner_touch on planner_variant.id = planner_touch.variant_id

join clubs_selectiongroup on planner_cell.group_id = clubs_selectiongroup.id
join clubs_selectiongroup_club_states  on clubs_selectiongroup.id = clubs_selectiongroup_club_states.selectiongroup_id
join clubs_clubstate on clubs_selectiongroup_club_states.clubstate_id = clubs_clubstate.id
join geo_state on clubs_clubstate.state_id = geo_state.id
join clubs_club on clubs_clubstate.club_id = clubs_club.id

left outer join creative_creativeplan on planner_touch.creative_id = creative_creativeplan.id
left outer join creative_creativeplan_assignments on creative_creativeplan.id = creative_creativeplan_assignments.creativeplan_id
left outer join creative_packageassignments on creative_creativeplan_assignments.packageassignments_id = creative_packageassignments.id
                and geo_state.id = creative_packageassignments.state_id


join offers_offerbundle on planner_touch.offers_id = offers_offerbundle.id
left join offers_offerbundle_offers on offers_offerbundle.id = offers_offerbundle_offers.offerbundle_id
join offers_offerdetails on offers_offerbundle_offers.offerdetails_id = offers_offerdetails.id
                            and geo_state.id = offers_offerdetails.state_id
join offers_faceamountgroup on offers_offerdetails.face_amount_id = offers_faceamountgroup.id
join offers_faceamountgroup_offers on offers_faceamountgroup.id = offers_faceamountgroup_offers.faceamountgroup_id
join offers_faceamount on offers_faceamountgroup_offers.faceamount_id = offers_faceamount.id
join offers_plancode on offers_plancode.id = offers_offerdetails.plan_code_id



where planner_campaign.name = '{}'
and creative_packageassignments.creative_id is not null
and planner_tactic.name not like '%Trigger%'
) metadata
left join (
select
    distinct
        tactic_name,
        reporting_group_name,
        age_min,
        age_max,
        age_unk,
        resident_club_code,
        States,
        right(keycode,1) as ms_keycode10th,
        packageID as ms_package_id,
        phone_number as ms_phone_number,
        drop_date,
        date_add(drop_date, Interval 7 year) as reply_by_date
from validation.mailing_schedule_agg
where campaign_name = (select distinct campaign_name from (
Select  Distinct
    planner_campaign.id as 'campaign_id'
    ,planner_campaign.name as 'campaign_name'
    ,planner_tactic.id as 'tactic_id'
    ,planner_tactic.name as 'tactic_name'
    ,campaign_parameters_selectionparameters.resolved_age_min
    ,campaign_parameters_selectionparameters.resolved_age_max
    ,campaign_parameters_selectionparameters.unknown_age_inclusion
    ,clubs_club.number as 'mtd_club_number'
    ,geo_state.abbreviation as 'mtd_st_cd'
    ,planner_variant.id as 'variant_id'
    ,planner_variant.keycode_10th_position_byte as 'mtd_keycode_10th_position_byte'
    ,planner_touch.id as 'touch_id'
    ,creative_packageassignments.creative_id as 'mtd_package_id'
    ,creative_packageassignments.phone_number as 'mtd_phone_number'
    ,planner_touch.reply_by_date
    ,offers_plancode.plan_code as 'plan_code'

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
left join planner_variant on planner_cell.id = planner_variant.cell_id
left join planner_touch on planner_variant.id = planner_touch.variant_id

join clubs_selectiongroup on planner_cell.group_id = clubs_selectiongroup.id
join clubs_selectiongroup_club_states  on clubs_selectiongroup.id = clubs_selectiongroup_club_states.selectiongroup_id
join clubs_clubstate on clubs_selectiongroup_club_states.clubstate_id = clubs_clubstate.id
join geo_state on clubs_clubstate.state_id = geo_state.id
join clubs_club on clubs_clubstate.club_id = clubs_club.id

left outer join creative_creativeplan on planner_touch.creative_id = creative_creativeplan.id
left outer join creative_creativeplan_assignments on creative_creativeplan.id = creative_creativeplan_assignments.creativeplan_id
left outer join creative_packageassignments on creative_creativeplan_assignments.packageassignments_id = creative_packageassignments.id
                and geo_state.id = creative_packageassignments.state_id


join offers_offerbundle on planner_touch.offers_id = offers_offerbundle.id
left join offers_offerbundle_offers on offers_offerbundle.id = offers_offerbundle_offers.offerbundle_id
join offers_offerdetails on offers_offerbundle_offers.offerdetails_id = offers_offerdetails.id
                            and geo_state.id = offers_offerdetails.state_id
join offers_faceamountgroup on offers_offerdetails.face_amount_id = offers_faceamountgroup.id
join offers_faceamountgroup_offers on offers_faceamountgroup.id = offers_faceamountgroup_offers.faceamountgroup_id
join offers_faceamount on offers_faceamountgroup_offers.faceamount_id = offers_faceamount.id
join offers_plancode on offers_plancode.id = offers_offerdetails.plan_code_id



where planner_campaign.name = '{}'
and creative_packageassignments.creative_id is not null
and planner_tactic.name not like '%Trigger%'
) metadata)
) ms_param
    on metadata.tactic_name = ms_param.tactic_name
    and metadata.mtd_club_number = ms_param.resident_club_code
    and metadata.mtd_st_cd = ms_param.States
    and metadata.mtd_keycode_10th_position_byte = ms_param.ms_keycode10th

),
match_mailing_schedule as (
select distinct
    metadata.campaign_id,
    metadata.campaign_name,
    metadata.tactic_id,
    metadata.tactic_name,

    metadata.resolved_age_min as mtd_resolved_age_min,
    ms_param.age_min as ms_resolved_age_min,

    case when ifnull(metadata.resolved_age_min,0) <> ifnull(ms_param.age_min,0)
        then 'Not Match' else '' end as check_age_min,

    metadata.resolved_age_max as mtd_resolved_age_max,
    ms_param.age_max as ms_resolved_age_max,
    case when ifnull(metadata.resolved_age_max,0) <> ifnull(ms_param.age_max,0)
        then 'Not Match' else '' end as check_age_max,


    metadata.unknown_age_inclusion,
    ms_param.age_unk as ms_age_unk,
    case when  metadata.unknown_age_inclusion = '1' and ms_param.age_unk = 'Y' then ''
         when  metadata.unknown_age_inclusion = '0' and ms_param.age_unk = 'N' then ''
         when ifnull(metadata.unknown_age_inclusion,'N') <> ifnull(ms_param.age_unk,'N')
         then 'Not Match' else '' end as check_age_unk,


    metadata.mtd_club_number as mtd_club_code,
    metadata.mtd_st_cd as mtd_state,
    ms_param.resident_club_code as ms_club_code,
    ms_param.States as ms_state,
    case when (ms_param.resident_club_code is null or ms_param.States is null)
          and (  metadata.mtd_club_number is not null AND metadata.mtd_st_cd is not null)
        then 'Missing from my guess. Verify participation from package assignment.'
    else '' end as check_club_state,

    metadata.variant_id,
    metadata.touch_id,

    metadata.mtd_keycode_10th_position_byte,
    metadata.mtd_package_id as mtd_package_id,
    ms_param.ms_package_id as ms_package_id,
    case when metadata.mtd_package_id <> ms_param.ms_package_id
    then 'Not Match' else '' end as check_package_id,

    metadata.mtd_phone_number as mtd_phone_number,
    ms_param.ms_phone_number as ms_phone_number,

    case when ifnull(metadata.mtd_phone_number,0) <> ifnull(ms_param.ms_phone_number,0)
    then 'Not Match' else '' end as check_phone_number,

    ms_param.tactic_name as ms_tactic_name,
    ms_param.reporting_group_name,

    metadata.reply_by_date as mtd_reply_by_date,
    case when  metadata.tactic_name like '%MLTA%'
            and metadata.mtd_club_number = '004'
            and metadata.mtd_st_cd = 'CA'
          then
        ms_param.reply_by_date
    else NULL end
    as ms_reply_by_date,

    case when  metadata.tactic_name like '%MLTA%'
                and metadata.mtd_club_number = '004'
                and metadata.mtd_st_cd = 'CA'
          then
            case when metadata.reply_by_date <> ms_param.reply_by_date
            then 'Not Match' else '' END
          else
          '' END as check_reply_by_date,
    plan_code

from (
Select  Distinct
    planner_campaign.id as 'campaign_id'
    ,planner_campaign.name as 'campaign_name'
    ,planner_tactic.id as 'tactic_id'
    ,planner_tactic.name as 'tactic_name'
    ,campaign_parameters_selectionparameters.resolved_age_min
    ,campaign_parameters_selectionparameters.resolved_age_max
    ,campaign_parameters_selectionparameters.unknown_age_inclusion
    ,clubs_club.number as 'mtd_club_number'
    ,geo_state.abbreviation as 'mtd_st_cd'
    ,planner_variant.id as 'variant_id'
    ,planner_variant.keycode_10th_position_byte as 'mtd_keycode_10th_position_byte'
    ,planner_touch.id as 'touch_id'
    ,creative_packageassignments.creative_id as 'mtd_package_id'
    ,creative_packageassignments.phone_number as 'mtd_phone_number'
    ,planner_touch.reply_by_date
    ,offers_plancode.plan_code as 'plan_code'

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
left join planner_variant on planner_cell.id = planner_variant.cell_id
left join planner_touch on planner_variant.id = planner_touch.variant_id

join clubs_selectiongroup on planner_cell.group_id = clubs_selectiongroup.id
join clubs_selectiongroup_club_states  on clubs_selectiongroup.id = clubs_selectiongroup_club_states.selectiongroup_id
join clubs_clubstate on clubs_selectiongroup_club_states.clubstate_id = clubs_clubstate.id
join geo_state on clubs_clubstate.state_id = geo_state.id
join clubs_club on clubs_clubstate.club_id = clubs_club.id

left outer join creative_creativeplan on planner_touch.creative_id = creative_creativeplan.id
left outer join creative_creativeplan_assignments on creative_creativeplan.id = creative_creativeplan_assignments.creativeplan_id
left outer join creative_packageassignments on creative_creativeplan_assignments.packageassignments_id = creative_packageassignments.id
                and geo_state.id = creative_packageassignments.state_id


join offers_offerbundle on planner_touch.offers_id = offers_offerbundle.id
left join offers_offerbundle_offers on offers_offerbundle.id = offers_offerbundle_offers.offerbundle_id
join offers_offerdetails on offers_offerbundle_offers.offerdetails_id = offers_offerdetails.id
                            and geo_state.id = offers_offerdetails.state_id
join offers_faceamountgroup on offers_offerdetails.face_amount_id = offers_faceamountgroup.id
join offers_faceamountgroup_offers on offers_faceamountgroup.id = offers_faceamountgroup_offers.faceamountgroup_id
join offers_faceamount on offers_faceamountgroup_offers.faceamount_id = offers_faceamount.id
join offers_plancode on offers_plancode.id = offers_offerdetails.plan_code_id



where planner_campaign.name = '{}'
and creative_packageassignments.creative_id is not null
and planner_tactic.name not like '%Trigger%'
) metadata
right join (
select
    distinct
        tactic_name,
        reporting_group_name,
        age_min,
        age_max,
        age_unk,
        resident_club_code,
        States,
        right(keycode,1) as ms_keycode10th,
        packageID as ms_package_id,
        phone_number as ms_phone_number,
        drop_date,
        date_add(drop_date, Interval 7 year) as reply_by_date
from validation.mailing_schedule_agg
where campaign_name = (select distinct campaign_name from (
Select  Distinct
    planner_campaign.id as 'campaign_id'
    ,planner_campaign.name as 'campaign_name'
    ,planner_tactic.id as 'tactic_id'
    ,planner_tactic.name as 'tactic_name'
    ,campaign_parameters_selectionparameters.resolved_age_min
    ,campaign_parameters_selectionparameters.resolved_age_max
    ,campaign_parameters_selectionparameters.unknown_age_inclusion
    ,clubs_club.number as 'mtd_club_number'
    ,geo_state.abbreviation as 'mtd_st_cd'
    ,planner_variant.id as 'variant_id'
    ,planner_variant.keycode_10th_position_byte as 'mtd_keycode_10th_position_byte'
    ,planner_touch.id as 'touch_id'
    ,creative_packageassignments.creative_id as 'mtd_package_id'
    ,creative_packageassignments.phone_number as 'mtd_phone_number'
    ,planner_touch.reply_by_date
    ,offers_plancode.plan_code as 'plan_code'

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
left join planner_variant on planner_cell.id = planner_variant.cell_id
left join planner_touch on planner_variant.id = planner_touch.variant_id

join clubs_selectiongroup on planner_cell.group_id = clubs_selectiongroup.id
join clubs_selectiongroup_club_states  on clubs_selectiongroup.id = clubs_selectiongroup_club_states.selectiongroup_id
join clubs_clubstate on clubs_selectiongroup_club_states.clubstate_id = clubs_clubstate.id
join geo_state on clubs_clubstate.state_id = geo_state.id
join clubs_club on clubs_clubstate.club_id = clubs_club.id

left outer join creative_creativeplan on planner_touch.creative_id = creative_creativeplan.id
left outer join creative_creativeplan_assignments on creative_creativeplan.id = creative_creativeplan_assignments.creativeplan_id
left outer join creative_packageassignments on creative_creativeplan_assignments.packageassignments_id = creative_packageassignments.id
                and geo_state.id = creative_packageassignments.state_id


join offers_offerbundle on planner_touch.offers_id = offers_offerbundle.id
left join offers_offerbundle_offers on offers_offerbundle.id = offers_offerbundle_offers.offerbundle_id
join offers_offerdetails on offers_offerbundle_offers.offerdetails_id = offers_offerdetails.id
                            and geo_state.id = offers_offerdetails.state_id
join offers_faceamountgroup on offers_offerdetails.face_amount_id = offers_faceamountgroup.id
join offers_faceamountgroup_offers on offers_faceamountgroup.id = offers_faceamountgroup_offers.faceamountgroup_id
join offers_faceamount on offers_faceamountgroup_offers.faceamount_id = offers_faceamount.id
join offers_plancode on offers_plancode.id = offers_offerdetails.plan_code_id



where planner_campaign.name = '{}'
and creative_packageassignments.creative_id is not null
and planner_tactic.name not like '%Trigger%'
) metadata)
) ms_param
    on metadata.tactic_name = ms_param.tactic_name
    and metadata.mtd_club_number = ms_param.resident_club_code
    and metadata.mtd_st_cd = ms_param.States
    and metadata.mtd_keycode_10th_position_byte = ms_param.ms_keycode10th

)

 select *
 from match_mtd
 union
 select *
 from match_mailing_schedule

order by
check_age_min desc,
check_age_max desc,
check_age_unk desc,
check_club_state desc,
check_reply_by_date desc,
check_phone_number desc,
tactic_name,
mtd_club_code,
mtd_state
