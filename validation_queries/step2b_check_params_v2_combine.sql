with AQ_portion as (
with CurrentCampaignObject as (Select  Distinct
    (planner_marketingprogram.id) as 'marketing_program_id'
    , planner_marketingprogram.NAME as 'marketing_program_name'
    , planner_initiative.id as 'initiative_id'
    , planner_initiative.name as 'initiative_name'
    ,planner_campaign.id as 'campaign_id'
    ,planner_campaign.name as 'campaign_name'
    ,planner_distributionchannel.id as 'distributionchannel_id'
    ,planner_distributionchannel.description as 'distributionchannel_description'
    ,planner_tactic.id as 'tactic_id'
    ,planner_tactic.name as 'tactic_name'
    , planner_cell.id as 'cell_id'
    , planner_cell.name as 'cell_name'
    , substring(planner_cell.name, 1,
            IF(ReGEXP_INSTR(planner_cell.name, '-') =0,
                100, ReGEXP_INSTR(planner_cell.name, '-'))-2) as trimmed_cell_name
    , planner_cell.parameters_id as 'cell_parameter_id'
    ,campaign_parameters_selectionparameters.*
from planner_marketingprogram
left join planner_initiative on planner_initiative.marketing_program_id = planner_marketingprogram.id
left join planner_campaign on planner_initiative.id = planner_campaign.initiative_id
left join planner_distributionchannel  on planner_campaign.distribution_channel_id = planner_distributionchannel.id
left join planner_campaigntype on planner_campaign.campaign_type_id = planner_campaigntype.id
left join planner_tactic on planner_campaign.id = planner_tactic.campaign_id
left join planner_tactictype on planner_tactictype.id = planner_tactic.type_id
left join planner_cell on planner_tactic.id = planner_cell.tactic_id
inner join  campaign_parameters_selectionparameters
    on planner_cell.parameters_id = campaign_parameters_selectionparameters.id

where planner_tactic.name not like '%CS%'
    and planner_campaign.name = '{0}'
),
PrevCampaignObject as (
     with prev_1 as (
             select distinct

                planner_cell.id as 'Last_cell_id',
                substring(planner_cell.name, 1,
                    IF(ReGEXP_INSTR(planner_cell.name, '-') =0,
                    100, ReGEXP_INSTR(planner_cell.name, '-'))-2) as 'last_trimmed_cell_name',
                planner_tactic.name as 'last_tactic_name'

            from planner_marketingprogram
            left join planner_initiative on planner_initiative.marketing_program_id = planner_marketingprogram.id
            left join planner_campaign on planner_initiative.id = planner_campaign.initiative_id
            left join planner_distributionchannel  on planner_campaign.distribution_channel_id = planner_distributionchannel.id
            left join planner_campaigntype on planner_campaign.campaign_type_id = planner_campaigntype.id
            left join planner_tactic on planner_campaign.id = planner_tactic.campaign_id
            left join planner_tactictype on planner_tactictype.id = planner_tactic.type_id
            left join planner_cell on planner_tactic.id = planner_cell.tactic_id
            where
             substring(planner_cell.name, 1,
                IF(ReGEXP_INSTR(planner_cell.name, '-') =0,
                100, ReGEXP_INSTR(planner_cell.name, '-'))-2)
             in (
                select distinct
                    trimmed_cell_name
                from CurrentCampaignObject
            )
// muted on 10/27/2020 because MLTA has new cell name in C2- 2021
//            and planner_cell.id not in (
//                select distinct
//                    cell_id
//                from CurrentCampaignObject
//           )
        ),
        prev_2 as (
            select
                max(Last_cell_id) as Last_cell_id,
                last_trimmed_cell_name,
                last_tactic_name
            from prev_1
            group by
                last_trimmed_cell_name,
                last_tactic_name
        ),
    param as (
        select
            prev_2.*,
            campaign_parameters_selectionparameters.*
        from prev_2
        inner join planner_cell on planner_cell.id = prev_2.Last_cell_id
        inner join  campaign_parameters_selectionparameters
            on planner_cell.parameters_id = campaign_parameters_selectionparameters.id
        )
    select
    *
    from param
)
select distinct
    CurrentCampaignObject.marketing_program_id,
    CurrentCampaignObject.marketing_program_name,
    CurrentCampaignObject.initiative_id,
    CurrentCampaignObject.initiative_name,
    CurrentCampaignObject.campaign_id,
    CurrentCampaignObject.campaign_name,
    CurrentCampaignObject.distributionchannel_id,
    CurrentCampaignObject.distributionchannel_description,
    CurrentCampaignObject.tactic_id,
    CurrentCampaignObject.tactic_name,
    CurrentCampaignObject.cell_id,
    CurrentCampaignObject.cell_name,
    CurrentCampaignObject.trimmed_cell_name,
    last_cell_id,
    CurrentCampaignObject.cell_parameter_id,
    PrevCampaignObject.id as last_cell_param,
    case when CurrentCampaignObject.cell_parameter_id = PrevCampaignObject.id
    then 'same_param' else 'different_param' end as param_check,

CurrentCampaignObject.milliman_min as current_milliman_min,
PrevCampaignObject.milliman_min as prev_milliman_min,

case when IFNULL(CurrentCampaignObject.milliman_min,-1) <> IFNULL(PrevCampaignObject.milliman_min,-1)
        then 'Not Match'
        else '' end as check_milliman_min,


CurrentCampaignObject.milliman_max as current_milliman_max,
PrevCampaignObject.milliman_max as prev_milliman_max,

case when IFNULL(CurrentCampaignObject.milliman_max,-1) <> IFNULL(PrevCampaignObject.milliman_max,-1)
        then 'Not Match'
        else '' end as check_milliman_max,


CurrentCampaignObject.milliman_exclusion as current_milliman_exclusion,
PrevCampaignObject.milliman_exclusion as prev_milliman_exclusion,

case when IFNULL(CurrentCampaignObject.milliman_exclusion,-1) <> IFNULL(PrevCampaignObject.milliman_exclusion,-1)
        then 'Not Match'
        else '' end as check_milliman_exclusion,


CurrentCampaignObject.unknown_milliman_inclusion as current_unknown_milliman_inclusion,
PrevCampaignObject.unknown_milliman_inclusion as prev_unknown_milliman_inclusion,

case when IFNULL(CurrentCampaignObject.unknown_milliman_inclusion,-1) <> IFNULL(PrevCampaignObject.unknown_milliman_inclusion,-1)
        then 'Not Match'
        else '' end as check_unknown_milliman_inclusion,

CurrentCampaignObject.is_prospect as current_is_prospect,
PrevCampaignObject.is_prospect as prev_is_prospect,

case when IFNULL(CurrentCampaignObject.is_prospect,-1) <> IFNULL(PrevCampaignObject.is_prospect,-1)
        then 'Not Match'
        else '' end as check_is_prospect,


CurrentCampaignObject.is_member as current_is_member,
PrevCampaignObject.is_member as prev_is_member,

case when IFNULL(CurrentCampaignObject.is_member,-1) <> IFNULL(PrevCampaignObject.is_member,-1)
        then 'Not Match'
        else '' end as check_is_member,


CurrentCampaignObject.is_customer as current_is_customer,
PrevCampaignObject.is_customer as prev_is_customer,

case when IFNULL(CurrentCampaignObject.is_customer,-1) <> IFNULL(PrevCampaignObject.is_customer,-1)
        then 'Not Match'
        else '' end as check_is_customer,


CurrentCampaignObject.gender_male as current_gender_male,
PrevCampaignObject.gender_male as prev_gender_male,

case when IFNULL(CurrentCampaignObject.gender_male,-1) <> IFNULL(PrevCampaignObject.gender_male,-1)
        then 'Not Match'
        else '' end as check_gender_male,

CurrentCampaignObject.gender_female as current_gender_female,
PrevCampaignObject.gender_female as prev_gender_female,

case when IFNULL(CurrentCampaignObject.gender_female,-1) <> IFNULL(PrevCampaignObject.gender_female,-1)
        then 'Not Match'
        else '' end as check_gender_female,


CurrentCampaignObject.gender_unknown as current_gender_unknown,
PrevCampaignObject.gender_unknown as prev_gender_unknown,

case when IFNULL(CurrentCampaignObject.gender_unknown,-1) <> IFNULL(PrevCampaignObject.gender_unknown,-1)
        then 'Not Match'
        else '' end as check_gender_unknown,


CurrentCampaignObject.member_role as current_member_role,
PrevCampaignObject.member_role as prev_member_role,

case when IFNULL(CurrentCampaignObject.member_role,-1) <> IFNULL(PrevCampaignObject.member_role,-1)
        then 'Not Match'
        else '' end as check_member_role,


CurrentCampaignObject.unknown_member_role_inclusion as current_unknown_member_role_inclusion,
PrevCampaignObject.unknown_member_role_inclusion as prev_unknown_member_role_inclusion,

case when IFNULL(CurrentCampaignObject.unknown_member_role_inclusion,-1) <> IFNULL(PrevCampaignObject.unknown_member_role_inclusion,-1)
        then 'Not Match'
        else '' end as check_unknown_member_role_inclusion,


--Match check for parameter: product_eligibility_direct_mail_term.
CurrentCampaignObject.product_eligibility_direct_mail_term as current_product_eligibility_direct_mail_term,
PrevCampaignObject.product_eligibility_direct_mail_term as prev_product_eligibility_direct_mail_term,

case when IFNULL(CurrentCampaignObject.product_eligibility_direct_mail_term,-1) <> IFNULL(PrevCampaignObject.product_eligibility_direct_mail_term,-1)
        then 'Not Match'
        else '' end as check_product_eligibility_direct_mail_term,


--Match check for parameter: product_eligibility_giwl.
CurrentCampaignObject.product_eligibility_giwl as current_product_eligibility_giwl,
PrevCampaignObject.product_eligibility_giwl as prev_product_eligibility_giwl,

case when IFNULL(CurrentCampaignObject.product_eligibility_giwl,-1) <> IFNULL(PrevCampaignObject.product_eligibility_giwl,-1)
        then 'Not Match'
        else '' end as check_product_eligibility_giwl,


--Match check for parameter: product_eligibility_mlta.
CurrentCampaignObject.product_eligibility_mlta as current_product_eligibility_mlta,
PrevCampaignObject.product_eligibility_mlta as prev_product_eligibility_mlta,

case when IFNULL(CurrentCampaignObject.product_eligibility_mlta,-1) <> IFNULL(PrevCampaignObject.product_eligibility_mlta,-1)
        then 'Not Match'
        else '' end as check_product_eligibility_mlta,


--Match check for parameter: product_eligibility_accident.
CurrentCampaignObject.product_eligibility_accident as current_product_eligibility_accident,
PrevCampaignObject.product_eligibility_accident as prev_product_eligibility_accident,

case when IFNULL(CurrentCampaignObject.product_eligibility_accident,-1) <> IFNULL(PrevCampaignObject.product_eligibility_accident,-1)
        then 'Not Match'
        else '' end as check_product_eligibility_accident,


--Match check for parameter: product_eligibility_traditional_term.
CurrentCampaignObject.product_eligibility_traditional_term as current_product_eligibility_traditional_term,
PrevCampaignObject.product_eligibility_traditional_term as prev_product_eligibility_traditional_term,

case when IFNULL(CurrentCampaignObject.product_eligibility_traditional_term,-1) <> IFNULL(PrevCampaignObject.product_eligibility_traditional_term,-1)
        then 'Not Match'
        else '' end as check_product_eligibility_traditional_term,


--Match check for parameter: product_eligibility_express_term.
CurrentCampaignObject.product_eligibility_express_term as current_product_eligibility_express_term,
PrevCampaignObject.product_eligibility_express_term as prev_product_eligibility_express_term,

case when IFNULL(CurrentCampaignObject.product_eligibility_express_term,-1) <> IFNULL(PrevCampaignObject.product_eligibility_express_term,-1)
        then 'Not Match'
        else '' end as check_product_eligibility_express_term,


--Match check for parameter: product_eligibility_individualdirectterm.
CurrentCampaignObject.product_eligibility_individualdirectterm as current_product_eligibility_individualdirectterm,
PrevCampaignObject.product_eligibility_individualdirectterm as prev_product_eligibility_individualdirectterm,

case when IFNULL(CurrentCampaignObject.product_eligibility_individualdirectterm,-1) <> IFNULL(PrevCampaignObject.product_eligibility_individualdirectterm,-1)
        then 'Not Match'
        else '' end as check_product_eligibility_individualdirectterm,


--Match check for parameter: direct_mail_term_upsell_eligibility.
CurrentCampaignObject.direct_mail_term_upsell_eligibility as current_direct_mail_term_upsell_eligibility,
PrevCampaignObject.direct_mail_term_upsell_eligibility as prev_direct_mail_term_upsell_eligibility,

case when IFNULL(CurrentCampaignObject.direct_mail_term_upsell_eligibility,-1) <> IFNULL(PrevCampaignObject.direct_mail_term_upsell_eligibility,-1)
        then 'Not Match'
        else '' end as check_direct_mail_term_upsell_eligibility,


--Match check for parameter: direct_mail_term_upsell_total_face_amount.
CurrentCampaignObject.direct_mail_term_upsell_total_face_amount as current_direct_mail_term_upsell_total_face_amount,
PrevCampaignObject.direct_mail_term_upsell_total_face_amount as prev_direct_mail_term_upsell_total_face_amount,

case when IFNULL(CurrentCampaignObject.direct_mail_term_upsell_total_face_amount,-1) <> IFNULL(PrevCampaignObject.direct_mail_term_upsell_total_face_amount,-1)
        then 'Not Match'
        else '' end as check_direct_mail_term_upsell_total_face_amount,


--Match check for parameter: giwl_upsell_total_face_amount.
CurrentCampaignObject.giwl_upsell_total_face_amount as current_giwl_upsell_total_face_amount,
PrevCampaignObject.giwl_upsell_total_face_amount as prev_giwl_upsell_total_face_amount,

case when IFNULL(CurrentCampaignObject.giwl_upsell_total_face_amount,-1) <> IFNULL(PrevCampaignObject.giwl_upsell_total_face_amount,-1)
        then 'Not Match'
        else '' end as check_giwl_upsell_total_face_amount,


--Match check for parameter: giwl_upsell_eligibility.
CurrentCampaignObject.giwl_upsell_eligibility as current_giwl_upsell_eligibility,
PrevCampaignObject.giwl_upsell_eligibility as prev_giwl_upsell_eligibility,

case when IFNULL(CurrentCampaignObject.giwl_upsell_eligibility,-1) <> IFNULL(PrevCampaignObject.giwl_upsell_eligibility,-1)
        then 'Not Match'
        else '' end as check_giwl_upsell_eligibility,


--Match check for parameter: declined_lifeproduct_flag.
CurrentCampaignObject.declined_lifeproduct_flag as current_declined_lifeproduct_flag,
PrevCampaignObject.declined_lifeproduct_flag as prev_declined_lifeproduct_flag,

case when IFNULL(CurrentCampaignObject.declined_lifeproduct_flag,-1) <> IFNULL(PrevCampaignObject.declined_lifeproduct_flag,-1)
        then 'Not Match'
        else '' end as check_declined_lifeproduct_flag,


--Match check for parameter: declined_accidentproduct_flag.
CurrentCampaignObject.declined_accidentproduct_flag as current_declined_accidentproduct_flag,
PrevCampaignObject.declined_accidentproduct_flag as prev_declined_accidentproduct_flag,

case when IFNULL(CurrentCampaignObject.declined_accidentproduct_flag,-1) <> IFNULL(PrevCampaignObject.declined_accidentproduct_flag,-1)
        then 'Not Match'
        else '' end as check_declined_accidentproduct_flag,


--Match check for parameter: declined_365_flag.
CurrentCampaignObject.declined_365_flag as current_declined_365_flag,
PrevCampaignObject.declined_365_flag as prev_declined_365_flag,

case when IFNULL(CurrentCampaignObject.declined_365_flag,-1) <> IFNULL(PrevCampaignObject.declined_365_flag,-1)
        then 'Not Match'
        else '' end as check_declined_365_flag,


--Match check for parameter: declined_accident_flag.
CurrentCampaignObject.declined_accident_flag as current_declined_accident_flag,
PrevCampaignObject.declined_accident_flag as prev_declined_accident_flag,

case when IFNULL(CurrentCampaignObject.declined_accident_flag,-1) <> IFNULL(PrevCampaignObject.declined_accident_flag,-1)
        then 'Not Match'
        else '' end as check_declined_accident_flag,


--Match check for parameter: declined_adb_flag.
CurrentCampaignObject.declined_adb_flag as current_declined_adb_flag,
PrevCampaignObject.declined_adb_flag as prev_declined_adb_flag,

case when IFNULL(CurrentCampaignObject.declined_adb_flag,-1) <> IFNULL(PrevCampaignObject.declined_adb_flag,-1)
        then 'Not Match'
        else '' end as check_declined_adb_flag,


--Match check for parameter: declined_hip_flag.
CurrentCampaignObject.declined_hip_flag as current_declined_hip_flag,
PrevCampaignObject.declined_hip_flag as prev_declined_hip_flag,

case when IFNULL(CurrentCampaignObject.declined_hip_flag,-1) <> IFNULL(PrevCampaignObject.declined_hip_flag,-1)
        then 'Not Match'
        else '' end as check_declined_hip_flag,


--Match check for parameter: declined_mlta_flag.
CurrentCampaignObject.declined_mlta_flag as current_declined_mlta_flag,
PrevCampaignObject.declined_mlta_flag as prev_declined_mlta_flag,

case when IFNULL(CurrentCampaignObject.declined_mlta_flag,-1) <> IFNULL(PrevCampaignObject.declined_mlta_flag,-1)
        then 'Not Match'
        else '' end as check_declined_mlta_flag,


--Match check for parameter: declined_mpa_flag.
CurrentCampaignObject.declined_mpa_flag as current_declined_mpa_flag,
PrevCampaignObject.declined_mpa_flag as prev_declined_mpa_flag,

case when IFNULL(CurrentCampaignObject.declined_mpa_flag,-1) <> IFNULL(PrevCampaignObject.declined_mpa_flag,-1)
        then 'Not Match'
        else '' end as check_declined_mpa_flag,


--Match check for parameter: declined_pai_flag.
CurrentCampaignObject.declined_pai_flag as current_declined_pai_flag,
PrevCampaignObject.declined_pai_flag as prev_declined_pai_flag,

case when IFNULL(CurrentCampaignObject.declined_pai_flag,-1) <> IFNULL(PrevCampaignObject.declined_pai_flag,-1)
        then 'Not Match'
        else '' end as check_declined_pai_flag,


--Match check for parameter: declined_pdd_flag.
CurrentCampaignObject.declined_pdd_flag as current_declined_pdd_flag,
PrevCampaignObject.declined_pdd_flag as prev_declined_pdd_flag,

case when IFNULL(CurrentCampaignObject.declined_pdd_flag,-1) <> IFNULL(PrevCampaignObject.declined_pdd_flag,-1)
        then 'Not Match'
        else '' end as check_declined_pdd_flag,


--Match check for parameter: declined_waiver_flag.
CurrentCampaignObject.declined_waiver_flag as current_declined_waiver_flag,
PrevCampaignObject.declined_waiver_flag as prev_declined_waiver_flag,

case when IFNULL(CurrentCampaignObject.declined_waiver_flag,-1) <> IFNULL(PrevCampaignObject.declined_waiver_flag,-1)
        then 'Not Match'
        else '' end as check_declined_waiver_flag,


--Match check for parameter: declined_fpda_flag.
CurrentCampaignObject.declined_fpda_flag as current_declined_fpda_flag,
PrevCampaignObject.declined_fpda_flag as prev_declined_fpda_flag,

case when IFNULL(CurrentCampaignObject.declined_fpda_flag,-1) <> IFNULL(PrevCampaignObject.declined_fpda_flag,-1)
        then 'Not Match'
        else '' end as check_declined_fpda_flag,


--Match check for parameter: declined_spda_flag.
CurrentCampaignObject.declined_spda_flag as current_declined_spda_flag,
PrevCampaignObject.declined_spda_flag as prev_declined_spda_flag,

case when IFNULL(CurrentCampaignObject.declined_spda_flag,-1) <> IFNULL(PrevCampaignObject.declined_spda_flag,-1)
        then 'Not Match'
        else '' end as check_declined_spda_flag,


--Match check for parameter: declined_spia_flag.
CurrentCampaignObject.declined_spia_flag as current_declined_spia_flag,
PrevCampaignObject.declined_spia_flag as prev_declined_spia_flag,

case when IFNULL(CurrentCampaignObject.declined_spia_flag,-1) <> IFNULL(PrevCampaignObject.declined_spia_flag,-1)
        then 'Not Match'
        else '' end as check_declined_spia_flag,


--Match check for parameter: declined_directmailterm_flag.
CurrentCampaignObject.declined_directmailterm_flag as current_declined_directmailterm_flag,
PrevCampaignObject.declined_directmailterm_flag as prev_declined_directmailterm_flag,

case when IFNULL(CurrentCampaignObject.declined_directmailterm_flag,-1) <> IFNULL(PrevCampaignObject.declined_directmailterm_flag,-1)
        then 'Not Match'
        else '' end as check_declined_directmailterm_flag,


--Match check for parameter: declined_expressterm_flag.
CurrentCampaignObject.declined_expressterm_flag as current_declined_expressterm_flag,
PrevCampaignObject.declined_expressterm_flag as prev_declined_expressterm_flag,

case when IFNULL(CurrentCampaignObject.declined_expressterm_flag,-1) <> IFNULL(PrevCampaignObject.declined_expressterm_flag,-1)
        then 'Not Match'
        else '' end as check_declined_expressterm_flag,


--Match check for parameter: declined_individualdirectterm_flag.
CurrentCampaignObject.declined_individualdirectterm_flag as current_declined_individualdirectterm_flag,
PrevCampaignObject.declined_individualdirectterm_flag as prev_declined_individualdirectterm_flag,

case when IFNULL(CurrentCampaignObject.declined_individualdirectterm_flag,-1) <> IFNULL(PrevCampaignObject.declined_individualdirectterm_flag,-1)
        then 'Not Match'
        else '' end as check_declined_individualdirectterm_flag,


--Match check for parameter: declined_term_flag.
CurrentCampaignObject.declined_term_flag as current_declined_term_flag,
PrevCampaignObject.declined_term_flag as prev_declined_term_flag,

case when IFNULL(CurrentCampaignObject.declined_term_flag,-1) <> IFNULL(PrevCampaignObject.declined_term_flag,-1)
        then 'Not Match'
        else '' end as check_declined_term_flag,


--Match check for parameter: declined_accumulatorul_flag.
CurrentCampaignObject.declined_accumulatorul_flag as current_declined_accumulatorul_flag,
PrevCampaignObject.declined_accumulatorul_flag as prev_declined_accumulatorul_flag,

case when IFNULL(CurrentCampaignObject.declined_accumulatorul_flag,-1) <> IFNULL(PrevCampaignObject.declined_accumulatorul_flag,-1)
        then 'Not Match'
        else '' end as check_declined_accumulatorul_flag,


--Match check for parameter: declined_lifetimeul_flag.
CurrentCampaignObject.declined_lifetimeul_flag as current_declined_lifetimeul_flag,
PrevCampaignObject.declined_lifetimeul_flag as prev_declined_lifetimeul_flag,

case when IFNULL(CurrentCampaignObject.declined_lifetimeul_flag,-1) <> IFNULL(PrevCampaignObject.declined_lifetimeul_flag,-1)
        then 'Not Match'
        else '' end as check_declined_lifetimeul_flag,


--Match check for parameter: declined_siwl_flag.
CurrentCampaignObject.declined_siwl_flag as current_declined_siwl_flag,
PrevCampaignObject.declined_siwl_flag as prev_declined_siwl_flag,

case when IFNULL(CurrentCampaignObject.declined_siwl_flag,-1) <> IFNULL(PrevCampaignObject.declined_siwl_flag,-1)
        then 'Not Match'
        else '' end as check_declined_siwl_flag,


--Match check for parameter: declined_giwl_flag.
CurrentCampaignObject.declined_giwl_flag as current_declined_giwl_flag,
PrevCampaignObject.declined_giwl_flag as prev_declined_giwl_flag,

case when IFNULL(CurrentCampaignObject.declined_giwl_flag,-1) <> IFNULL(PrevCampaignObject.declined_giwl_flag,-1)
        then 'Not Match'
        else '' end as check_declined_giwl_flag,


--Match check for parameter: declined_juvenile_flag.
CurrentCampaignObject.declined_juvenile_flag as current_declined_juvenile_flag,
PrevCampaignObject.declined_juvenile_flag as prev_declined_juvenile_flag,

case when IFNULL(CurrentCampaignObject.declined_juvenile_flag,-1) <> IFNULL(PrevCampaignObject.declined_juvenile_flag,-1)
        then 'Not Match'
        else '' end as check_declined_juvenile_flag,


--Match check for parameter: declined_wholelife_flag.
CurrentCampaignObject.declined_wholelife_flag as current_declined_wholelife_flag,
PrevCampaignObject.declined_wholelife_flag as prev_declined_wholelife_flag,

case when IFNULL(CurrentCampaignObject.declined_wholelife_flag,-1) <> IFNULL(PrevCampaignObject.declined_wholelife_flag,-1)
        then 'Not Match'
        else '' end as check_declined_wholelife_flag,


--Match check for parameter: club_ok_to_mail.
CurrentCampaignObject.club_ok_to_mail as current_club_ok_to_mail,
PrevCampaignObject.club_ok_to_mail as prev_club_ok_to_mail,

case when IFNULL(CurrentCampaignObject.club_ok_to_mail,-1) <> IFNULL(PrevCampaignObject.club_ok_to_mail,-1)
        then 'Not Match'
        else '' end as check_club_ok_to_mail,


--Match check for parameter: total_insured_inforce_policies.
CurrentCampaignObject.total_insured_inforce_policies as current_total_insured_inforce_policies,
PrevCampaignObject.total_insured_inforce_policies as prev_total_insured_inforce_policies,

case when IFNULL(CurrentCampaignObject.total_insured_inforce_policies,-1) <> IFNULL(PrevCampaignObject.total_insured_inforce_policies,-1)
        then 'Not Match'
        else '' end as check_total_insured_inforce_policies,


--Match check for parameter: insured_inforce_lifeproduct_flag.
CurrentCampaignObject.insured_inforce_lifeproduct_flag as current_insured_inforce_lifeproduct_flag,
PrevCampaignObject.insured_inforce_lifeproduct_flag as prev_insured_inforce_lifeproduct_flag,

case when IFNULL(CurrentCampaignObject.insured_inforce_lifeproduct_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_lifeproduct_flag,-1)
        then 'Not Match'
        else '' end as check_insured_inforce_lifeproduct_flag,


--Match check for parameter: insured_inforce_accidentproduct_flag.
CurrentCampaignObject.insured_inforce_accidentproduct_flag as current_insured_inforce_accidentproduct_flag,
PrevCampaignObject.insured_inforce_accidentproduct_flag as prev_insured_inforce_accidentproduct_flag,

case when IFNULL(CurrentCampaignObject.insured_inforce_accidentproduct_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_accidentproduct_flag,-1)
        then 'Not Match'
        else '' end as check_insured_inforce_accidentproduct_flag,


--Match check for parameter: insured_inforce_annuityproduct_flag.
CurrentCampaignObject.insured_inforce_annuityproduct_flag as current_insured_inforce_annuityproduct_flag,
PrevCampaignObject.insured_inforce_annuityproduct_flag as prev_insured_inforce_annuityproduct_flag,

case when IFNULL(CurrentCampaignObject.insured_inforce_annuityproduct_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_annuityproduct_flag,-1)
        then 'Not Match'
        else '' end as check_insured_inforce_annuityproduct_flag,


--Match check for parameter: insured_inforce_365_flag.
CurrentCampaignObject.insured_inforce_365_flag as current_insured_inforce_365_flag,
PrevCampaignObject.insured_inforce_365_flag as prev_insured_inforce_365_flag,

case when IFNULL(CurrentCampaignObject.insured_inforce_365_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_365_flag,-1)
        then 'Not Match'
        else '' end as check_insured_inforce_365_flag,


--Match check for parameter: insured_inforce_accident_flag.
CurrentCampaignObject.insured_inforce_accident_flag as current_insured_inforce_accident_flag,
PrevCampaignObject.insured_inforce_accident_flag as prev_insured_inforce_accident_flag,

case when IFNULL(CurrentCampaignObject.insured_inforce_accident_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_accident_flag,-1)
        then 'Not Match'
        else '' end as check_insured_inforce_accident_flag,


--Match check for parameter: insured_inforce_adb_flag.
CurrentCampaignObject.insured_inforce_adb_flag as current_insured_inforce_adb_flag,
PrevCampaignObject.insured_inforce_adb_flag as prev_insured_inforce_adb_flag,

case when IFNULL(CurrentCampaignObject.insured_inforce_adb_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_adb_flag,-1)
        then 'Not Match'
        else '' end as check_insured_inforce_adb_flag,


--Match check for parameter: insured_inforce_hip_flag.
CurrentCampaignObject.insured_inforce_hip_flag as current_insured_inforce_hip_flag,
PrevCampaignObject.insured_inforce_hip_flag as prev_insured_inforce_hip_flag,

case when IFNULL(CurrentCampaignObject.insured_inforce_hip_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_hip_flag,-1)
        then 'Not Match'
        else '' end as check_insured_inforce_hip_flag,


--Match check for parameter: insured_inforce_mlta_flag.
CurrentCampaignObject.insured_inforce_mlta_flag as current_insured_inforce_mlta_flag,
PrevCampaignObject.insured_inforce_mlta_flag as prev_insured_inforce_mlta_flag,

case when IFNULL(CurrentCampaignObject.insured_inforce_mlta_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_mlta_flag,-1)
        then 'Not Match'
        else '' end as check_insured_inforce_mlta_flag,


--Match check for parameter: insured_inforce_mpa_flag.
CurrentCampaignObject.insured_inforce_mpa_flag as current_insured_inforce_mpa_flag,
PrevCampaignObject.insured_inforce_mpa_flag as prev_insured_inforce_mpa_flag,

case when IFNULL(CurrentCampaignObject.insured_inforce_mpa_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_mpa_flag,-1)
        then 'Not Match'
        else '' end as check_insured_inforce_mpa_flag,


--Match check for parameter: insured_inforce_pai_flag.
CurrentCampaignObject.insured_inforce_pai_flag as current_insured_inforce_pai_flag,
PrevCampaignObject.insured_inforce_pai_flag as prev_insured_inforce_pai_flag,

case when IFNULL(CurrentCampaignObject.insured_inforce_pai_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_pai_flag,-1)
        then 'Not Match'
        else '' end as check_insured_inforce_pai_flag,


--Match check for parameter: insured_inforce_pdd_flag.
CurrentCampaignObject.insured_inforce_pdd_flag as current_insured_inforce_pdd_flag,
PrevCampaignObject.insured_inforce_pdd_flag as prev_insured_inforce_pdd_flag,

case when IFNULL(CurrentCampaignObject.insured_inforce_pdd_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_pdd_flag,-1)
        then 'Not Match'
        else '' end as check_insured_inforce_pdd_flag,


--Match check for parameter: insured_inforce_waiver_flag.
CurrentCampaignObject.insured_inforce_waiver_flag as current_insured_inforce_waiver_flag,
PrevCampaignObject.insured_inforce_waiver_flag as prev_insured_inforce_waiver_flag,

case when IFNULL(CurrentCampaignObject.insured_inforce_waiver_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_waiver_flag,-1)
        then 'Not Match'
        else '' end as check_insured_inforce_waiver_flag,


--Match check for parameter: insured_inforce_fpda_flag.
CurrentCampaignObject.insured_inforce_fpda_flag as current_insured_inforce_fpda_flag,
PrevCampaignObject.insured_inforce_fpda_flag as prev_insured_inforce_fpda_flag,

case when IFNULL(CurrentCampaignObject.insured_inforce_fpda_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_fpda_flag,-1)
        then 'Not Match'
        else '' end as check_insured_inforce_fpda_flag,


--Match check for parameter: insured_inforce_spda_flag.
CurrentCampaignObject.insured_inforce_spda_flag as current_insured_inforce_spda_flag,
PrevCampaignObject.insured_inforce_spda_flag as prev_insured_inforce_spda_flag,

case when IFNULL(CurrentCampaignObject.insured_inforce_spda_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_spda_flag,-1)
        then 'Not Match'
        else '' end as check_insured_inforce_spda_flag,


--Match check for parameter: insured_inforce_spia_flag.
CurrentCampaignObject.insured_inforce_spia_flag as current_insured_inforce_spia_flag,
PrevCampaignObject.insured_inforce_spia_flag as prev_insured_inforce_spia_flag,

case when IFNULL(CurrentCampaignObject.insured_inforce_spia_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_spia_flag,-1)
        then 'Not Match'
        else '' end as check_insured_inforce_spia_flag,


--Match check for parameter: insured_inforce_directmailterm_flag.
CurrentCampaignObject.insured_inforce_directmailterm_flag as current_insured_inforce_directmailterm_flag,
PrevCampaignObject.insured_inforce_directmailterm_flag as prev_insured_inforce_directmailterm_flag,

case when IFNULL(CurrentCampaignObject.insured_inforce_directmailterm_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_directmailterm_flag,-1)
        then 'Not Match'
        else '' end as check_insured_inforce_directmailterm_flag,


--Match check for parameter: insured_inforce_expressterm_flag.
CurrentCampaignObject.insured_inforce_expressterm_flag as current_insured_inforce_expressterm_flag,
PrevCampaignObject.insured_inforce_expressterm_flag as prev_insured_inforce_expressterm_flag,

case when IFNULL(CurrentCampaignObject.insured_inforce_expressterm_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_expressterm_flag,-1)
        then 'Not Match'
        else '' end as check_insured_inforce_expressterm_flag,


--Match check for parameter: insured_inforce_individualdirectterm_flag.
CurrentCampaignObject.insured_inforce_individualdirectterm_flag as current_insured_inforce_individualdirectterm_flag,
PrevCampaignObject.insured_inforce_individualdirectterm_flag as prev_insured_inforce_individualdirectterm_flag,

case when IFNULL(CurrentCampaignObject.insured_inforce_individualdirectterm_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_individualdirectterm_flag,-1)
        then 'Not Match'
        else '' end as check_insured_inforce_individualdirectterm_flag,


--Match check for parameter: insured_inforce_term_flag.
CurrentCampaignObject.insured_inforce_term_flag as current_insured_inforce_term_flag,
PrevCampaignObject.insured_inforce_term_flag as prev_insured_inforce_term_flag,

case when IFNULL(CurrentCampaignObject.insured_inforce_term_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_term_flag,-1)
        then 'Not Match'
        else '' end as check_insured_inforce_term_flag,


--Match check for parameter: insured_inforce_accumulatorul_flag.
CurrentCampaignObject.insured_inforce_accumulatorul_flag as current_insured_inforce_accumulatorul_flag,
PrevCampaignObject.insured_inforce_accumulatorul_flag as prev_insured_inforce_accumulatorul_flag,

case when IFNULL(CurrentCampaignObject.insured_inforce_accumulatorul_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_accumulatorul_flag,-1)
        then 'Not Match'
        else '' end as check_insured_inforce_accumulatorul_flag,


--Match check for parameter: insured_inforce_lifetimeul_flag.
CurrentCampaignObject.insured_inforce_lifetimeul_flag as current_insured_inforce_lifetimeul_flag,
PrevCampaignObject.insured_inforce_lifetimeul_flag as prev_insured_inforce_lifetimeul_flag,

case when IFNULL(CurrentCampaignObject.insured_inforce_lifetimeul_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_lifetimeul_flag,-1)
        then 'Not Match'
        else '' end as check_insured_inforce_lifetimeul_flag,


--Match check for parameter: insured_inforce_siwl_flag.
CurrentCampaignObject.insured_inforce_siwl_flag as current_insured_inforce_siwl_flag,
PrevCampaignObject.insured_inforce_siwl_flag as prev_insured_inforce_siwl_flag,

case when IFNULL(CurrentCampaignObject.insured_inforce_siwl_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_siwl_flag,-1)
        then 'Not Match'
        else '' end as check_insured_inforce_siwl_flag,


--Match check for parameter: insured_inforce_giwl_flag.
CurrentCampaignObject.insured_inforce_giwl_flag as current_insured_inforce_giwl_flag,
PrevCampaignObject.insured_inforce_giwl_flag as prev_insured_inforce_giwl_flag,

case when IFNULL(CurrentCampaignObject.insured_inforce_giwl_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_giwl_flag,-1)
        then 'Not Match'
        else '' end as check_insured_inforce_giwl_flag,


--Match check for parameter: insured_inforce_juvenile_flag.
CurrentCampaignObject.insured_inforce_juvenile_flag as current_insured_inforce_juvenile_flag,
PrevCampaignObject.insured_inforce_juvenile_flag as prev_insured_inforce_juvenile_flag,

case when IFNULL(CurrentCampaignObject.insured_inforce_juvenile_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_juvenile_flag,-1)
        then 'Not Match'
        else '' end as check_insured_inforce_juvenile_flag,


--Match check for parameter: insured_inforce_wholelife_flag.
CurrentCampaignObject.insured_inforce_wholelife_flag as current_insured_inforce_wholelife_flag,
PrevCampaignObject.insured_inforce_wholelife_flag as prev_insured_inforce_wholelife_flag,

case when IFNULL(CurrentCampaignObject.insured_inforce_wholelife_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_wholelife_flag,-1)
        then 'Not Match'
        else '' end as check_insured_inforce_wholelife_flag,


--Match check for parameter: insured_activeapp_lifeproduct_flag.
CurrentCampaignObject.insured_activeapp_lifeproduct_flag as current_insured_activeapp_lifeproduct_flag,
PrevCampaignObject.insured_activeapp_lifeproduct_flag as prev_insured_activeapp_lifeproduct_flag,

case when IFNULL(CurrentCampaignObject.insured_activeapp_lifeproduct_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_lifeproduct_flag,-1)
        then 'Not Match'
        else '' end as check_insured_activeapp_lifeproduct_flag,


--Match check for parameter: insured_activeapp_accidentproduct_flag.
CurrentCampaignObject.insured_activeapp_accidentproduct_flag as current_insured_activeapp_accidentproduct_flag,
PrevCampaignObject.insured_activeapp_accidentproduct_flag as prev_insured_activeapp_accidentproduct_flag,

case when IFNULL(CurrentCampaignObject.insured_activeapp_accidentproduct_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_accidentproduct_flag,-1)
        then 'Not Match'
        else '' end as check_insured_activeapp_accidentproduct_flag,


--Match check for parameter: insured_activeapp_annuityproduct_flag.
CurrentCampaignObject.insured_activeapp_annuityproduct_flag as current_insured_activeapp_annuityproduct_flag,
PrevCampaignObject.insured_activeapp_annuityproduct_flag as prev_insured_activeapp_annuityproduct_flag,

case when IFNULL(CurrentCampaignObject.insured_activeapp_annuityproduct_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_annuityproduct_flag,-1)
        then 'Not Match'
        else '' end as check_insured_activeapp_annuityproduct_flag,


--Match check for parameter: insured_activeapp_365_flag.
CurrentCampaignObject.insured_activeapp_365_flag as current_insured_activeapp_365_flag,
PrevCampaignObject.insured_activeapp_365_flag as prev_insured_activeapp_365_flag,

case when IFNULL(CurrentCampaignObject.insured_activeapp_365_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_365_flag,-1)
        then 'Not Match'
        else '' end as check_insured_activeapp_365_flag,


--Match check for parameter: insured_activeapp_accident_flag.
CurrentCampaignObject.insured_activeapp_accident_flag as current_insured_activeapp_accident_flag,
PrevCampaignObject.insured_activeapp_accident_flag as prev_insured_activeapp_accident_flag,

case when IFNULL(CurrentCampaignObject.insured_activeapp_accident_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_accident_flag,-1)
        then 'Not Match'
        else '' end as check_insured_activeapp_accident_flag,


--Match check for parameter: insured_activeapp_adb_flag.
CurrentCampaignObject.insured_activeapp_adb_flag as current_insured_activeapp_adb_flag,
PrevCampaignObject.insured_activeapp_adb_flag as prev_insured_activeapp_adb_flag,

case when IFNULL(CurrentCampaignObject.insured_activeapp_adb_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_adb_flag,-1)
        then 'Not Match'
        else '' end as check_insured_activeapp_adb_flag,


--Match check for parameter: insured_activeapp_hip_flag.
CurrentCampaignObject.insured_activeapp_hip_flag as current_insured_activeapp_hip_flag,
PrevCampaignObject.insured_activeapp_hip_flag as prev_insured_activeapp_hip_flag,

case when IFNULL(CurrentCampaignObject.insured_activeapp_hip_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_hip_flag,-1)
        then 'Not Match'
        else '' end as check_insured_activeapp_hip_flag,


--Match check for parameter: insured_activeapp_mlta_flag.
CurrentCampaignObject.insured_activeapp_mlta_flag as current_insured_activeapp_mlta_flag,
PrevCampaignObject.insured_activeapp_mlta_flag as prev_insured_activeapp_mlta_flag,

case when IFNULL(CurrentCampaignObject.insured_activeapp_mlta_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_mlta_flag,-1)
        then 'Not Match'
        else '' end as check_insured_activeapp_mlta_flag,


--Match check for parameter: insured_activeapp_mpa_flag.
CurrentCampaignObject.insured_activeapp_mpa_flag as current_insured_activeapp_mpa_flag,
PrevCampaignObject.insured_activeapp_mpa_flag as prev_insured_activeapp_mpa_flag,

case when IFNULL(CurrentCampaignObject.insured_activeapp_mpa_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_mpa_flag,-1)
        then 'Not Match'
        else '' end as check_insured_activeapp_mpa_flag,


--Match check for parameter: insured_activeapp_pai_flag.
CurrentCampaignObject.insured_activeapp_pai_flag as current_insured_activeapp_pai_flag,
PrevCampaignObject.insured_activeapp_pai_flag as prev_insured_activeapp_pai_flag,

case when IFNULL(CurrentCampaignObject.insured_activeapp_pai_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_pai_flag,-1)
        then 'Not Match'
        else '' end as check_insured_activeapp_pai_flag,


--Match check for parameter: insured_activeapp_pdd_flag.
CurrentCampaignObject.insured_activeapp_pdd_flag as current_insured_activeapp_pdd_flag,
PrevCampaignObject.insured_activeapp_pdd_flag as prev_insured_activeapp_pdd_flag,

case when IFNULL(CurrentCampaignObject.insured_activeapp_pdd_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_pdd_flag,-1)
        then 'Not Match'
        else '' end as check_insured_activeapp_pdd_flag,


--Match check for parameter: insured_activeapp_waiver_flag.
CurrentCampaignObject.insured_activeapp_waiver_flag as current_insured_activeapp_waiver_flag,
PrevCampaignObject.insured_activeapp_waiver_flag as prev_insured_activeapp_waiver_flag,

case when IFNULL(CurrentCampaignObject.insured_activeapp_waiver_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_waiver_flag,-1)
        then 'Not Match'
        else '' end as check_insured_activeapp_waiver_flag,


--Match check for parameter: insured_activeapp_fpda_flag.
CurrentCampaignObject.insured_activeapp_fpda_flag as current_insured_activeapp_fpda_flag,
PrevCampaignObject.insured_activeapp_fpda_flag as prev_insured_activeapp_fpda_flag,

case when IFNULL(CurrentCampaignObject.insured_activeapp_fpda_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_fpda_flag,-1)
        then 'Not Match'
        else '' end as check_insured_activeapp_fpda_flag,


--Match check for parameter: insured_activeapp_spda_flag.
CurrentCampaignObject.insured_activeapp_spda_flag as current_insured_activeapp_spda_flag,
PrevCampaignObject.insured_activeapp_spda_flag as prev_insured_activeapp_spda_flag,

case when IFNULL(CurrentCampaignObject.insured_activeapp_spda_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_spda_flag,-1)
        then 'Not Match'
        else '' end as check_insured_activeapp_spda_flag,


--Match check for parameter: insured_activeapp_spia_flag.
CurrentCampaignObject.insured_activeapp_spia_flag as current_insured_activeapp_spia_flag,
PrevCampaignObject.insured_activeapp_spia_flag as prev_insured_activeapp_spia_flag,

case when IFNULL(CurrentCampaignObject.insured_activeapp_spia_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_spia_flag,-1)
        then 'Not Match'
        else '' end as check_insured_activeapp_spia_flag,


--Match check for parameter: insured_activeapp_directmailterm_flag.
CurrentCampaignObject.insured_activeapp_directmailterm_flag as current_insured_activeapp_directmailterm_flag,
PrevCampaignObject.insured_activeapp_directmailterm_flag as prev_insured_activeapp_directmailterm_flag,

case when IFNULL(CurrentCampaignObject.insured_activeapp_directmailterm_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_directmailterm_flag,-1)
        then 'Not Match'
        else '' end as check_insured_activeapp_directmailterm_flag,


--Match check for parameter: insured_activeapp_expressterm_flag.
CurrentCampaignObject.insured_activeapp_expressterm_flag as current_insured_activeapp_expressterm_flag,
PrevCampaignObject.insured_activeapp_expressterm_flag as prev_insured_activeapp_expressterm_flag,

case when IFNULL(CurrentCampaignObject.insured_activeapp_expressterm_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_expressterm_flag,-1)
        then 'Not Match'
        else '' end as check_insured_activeapp_expressterm_flag,


--Match check for parameter: insured_activeapp_individualdirectterm_flag.
CurrentCampaignObject.insured_activeapp_individualdirectterm_flag as current_insured_activeapp_individualdirectterm_flag,
PrevCampaignObject.insured_activeapp_individualdirectterm_flag as prev_insured_activeapp_individualdirectterm_flag,

case when IFNULL(CurrentCampaignObject.insured_activeapp_individualdirectterm_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_individualdirectterm_flag,-1)
        then 'Not Match'
        else '' end as check_insured_activeapp_individualdirectterm_flag,


--Match check for parameter: insured_activeapp_term_flag.
CurrentCampaignObject.insured_activeapp_term_flag as current_insured_activeapp_term_flag,
PrevCampaignObject.insured_activeapp_term_flag as prev_insured_activeapp_term_flag,

case when IFNULL(CurrentCampaignObject.insured_activeapp_term_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_term_flag,-1)
        then 'Not Match'
        else '' end as check_insured_activeapp_term_flag,


--Match check for parameter: insured_activeapp_accumulatorul_flag.
CurrentCampaignObject.insured_activeapp_accumulatorul_flag as current_insured_activeapp_accumulatorul_flag,
PrevCampaignObject.insured_activeapp_accumulatorul_flag as prev_insured_activeapp_accumulatorul_flag,

case when IFNULL(CurrentCampaignObject.insured_activeapp_accumulatorul_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_accumulatorul_flag,-1)
        then 'Not Match'
        else '' end as check_insured_activeapp_accumulatorul_flag,


--Match check for parameter: insured_activeapp_lifetimeul_flag.
CurrentCampaignObject.insured_activeapp_lifetimeul_flag as current_insured_activeapp_lifetimeul_flag,
PrevCampaignObject.insured_activeapp_lifetimeul_flag as prev_insured_activeapp_lifetimeul_flag,

case when IFNULL(CurrentCampaignObject.insured_activeapp_lifetimeul_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_lifetimeul_flag,-1)
        then 'Not Match'
        else '' end as check_insured_activeapp_lifetimeul_flag,


--Match check for parameter: insured_activeapp_siwl_flag.
CurrentCampaignObject.insured_activeapp_siwl_flag as current_insured_activeapp_siwl_flag,
PrevCampaignObject.insured_activeapp_siwl_flag as prev_insured_activeapp_siwl_flag,

case when IFNULL(CurrentCampaignObject.insured_activeapp_siwl_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_siwl_flag,-1)
        then 'Not Match'
        else '' end as check_insured_activeapp_siwl_flag,


--Match check for parameter: insured_activeapp_giwl_flag.
CurrentCampaignObject.insured_activeapp_giwl_flag as current_insured_activeapp_giwl_flag,
PrevCampaignObject.insured_activeapp_giwl_flag as prev_insured_activeapp_giwl_flag,

case when IFNULL(CurrentCampaignObject.insured_activeapp_giwl_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_giwl_flag,-1)
        then 'Not Match'
        else '' end as check_insured_activeapp_giwl_flag,


--Match check for parameter: insured_activeapp_juvenile_flag.
CurrentCampaignObject.insured_activeapp_juvenile_flag as current_insured_activeapp_juvenile_flag,
PrevCampaignObject.insured_activeapp_juvenile_flag as prev_insured_activeapp_juvenile_flag,

case when IFNULL(CurrentCampaignObject.insured_activeapp_juvenile_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_juvenile_flag,-1)
        then 'Not Match'
        else '' end as check_insured_activeapp_juvenile_flag,


--Match check for parameter: insured_activeapp_wholelife_flag.
CurrentCampaignObject.insured_activeapp_wholelife_flag as current_insured_activeapp_wholelife_flag,
PrevCampaignObject.insured_activeapp_wholelife_flag as prev_insured_activeapp_wholelife_flag,

case when IFNULL(CurrentCampaignObject.insured_activeapp_wholelife_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_wholelife_flag,-1)
        then 'Not Match'
        else '' end as check_insured_activeapp_wholelife_flag,


--Match check for parameter: insured_coldfeet_365_flag.
CurrentCampaignObject.insured_coldfeet_365_flag as current_insured_coldfeet_365_flag,
PrevCampaignObject.insured_coldfeet_365_flag as prev_insured_coldfeet_365_flag,

case when IFNULL(CurrentCampaignObject.insured_coldfeet_365_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_365_flag,-1)
        then 'Not Match'
        else '' end as check_insured_coldfeet_365_flag,


--Match check for parameter: insured_coldfeet_accident_flag.
CurrentCampaignObject.insured_coldfeet_accident_flag as current_insured_coldfeet_accident_flag,
PrevCampaignObject.insured_coldfeet_accident_flag as prev_insured_coldfeet_accident_flag,

case when IFNULL(CurrentCampaignObject.insured_coldfeet_accident_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_accident_flag,-1)
        then 'Not Match'
        else '' end as check_insured_coldfeet_accident_flag,


--Match check for parameter: insured_coldfeet_adb_flag.
CurrentCampaignObject.insured_coldfeet_adb_flag as current_insured_coldfeet_adb_flag,
PrevCampaignObject.insured_coldfeet_adb_flag as prev_insured_coldfeet_adb_flag,

case when IFNULL(CurrentCampaignObject.insured_coldfeet_adb_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_adb_flag,-1)
        then 'Not Match'
        else '' end as check_insured_coldfeet_adb_flag,


--Match check for parameter: insured_coldfeet_hip_flag.
CurrentCampaignObject.insured_coldfeet_hip_flag as current_insured_coldfeet_hip_flag,
PrevCampaignObject.insured_coldfeet_hip_flag as prev_insured_coldfeet_hip_flag,

case when IFNULL(CurrentCampaignObject.insured_coldfeet_hip_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_hip_flag,-1)
        then 'Not Match'
        else '' end as check_insured_coldfeet_hip_flag,


--Match check for parameter: insured_coldfeet_mlta_flag.
CurrentCampaignObject.insured_coldfeet_mlta_flag as current_insured_coldfeet_mlta_flag,
PrevCampaignObject.insured_coldfeet_mlta_flag as prev_insured_coldfeet_mlta_flag,

case when IFNULL(CurrentCampaignObject.insured_coldfeet_mlta_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_mlta_flag,-1)
        then 'Not Match'
        else '' end as check_insured_coldfeet_mlta_flag,


--Match check for parameter: insured_coldfeet_mpa_flag.
CurrentCampaignObject.insured_coldfeet_mpa_flag as current_insured_coldfeet_mpa_flag,
PrevCampaignObject.insured_coldfeet_mpa_flag as prev_insured_coldfeet_mpa_flag,

case when IFNULL(CurrentCampaignObject.insured_coldfeet_mpa_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_mpa_flag,-1)
        then 'Not Match'
        else '' end as check_insured_coldfeet_mpa_flag,


--Match check for parameter: insured_coldfeet_pai_flag.
CurrentCampaignObject.insured_coldfeet_pai_flag as current_insured_coldfeet_pai_flag,
PrevCampaignObject.insured_coldfeet_pai_flag as prev_insured_coldfeet_pai_flag,

case when IFNULL(CurrentCampaignObject.insured_coldfeet_pai_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_pai_flag,-1)
        then 'Not Match'
        else '' end as check_insured_coldfeet_pai_flag,


--Match check for parameter: insured_coldfeet_pdd_flag.
CurrentCampaignObject.insured_coldfeet_pdd_flag as current_insured_coldfeet_pdd_flag,
PrevCampaignObject.insured_coldfeet_pdd_flag as prev_insured_coldfeet_pdd_flag,

case when IFNULL(CurrentCampaignObject.insured_coldfeet_pdd_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_pdd_flag,-1)
        then 'Not Match'
        else '' end as check_insured_coldfeet_pdd_flag,


--Match check for parameter: insured_coldfeet_waiver_flag.
CurrentCampaignObject.insured_coldfeet_waiver_flag as current_insured_coldfeet_waiver_flag,
PrevCampaignObject.insured_coldfeet_waiver_flag as prev_insured_coldfeet_waiver_flag,

case when IFNULL(CurrentCampaignObject.insured_coldfeet_waiver_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_waiver_flag,-1)
        then 'Not Match'
        else '' end as check_insured_coldfeet_waiver_flag,


--Match check for parameter: insured_coldfeet_fpda_flag.
CurrentCampaignObject.insured_coldfeet_fpda_flag as current_insured_coldfeet_fpda_flag,
PrevCampaignObject.insured_coldfeet_fpda_flag as prev_insured_coldfeet_fpda_flag,

case when IFNULL(CurrentCampaignObject.insured_coldfeet_fpda_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_fpda_flag,-1)
        then 'Not Match'
        else '' end as check_insured_coldfeet_fpda_flag,


--Match check for parameter: insured_coldfeet_spda_flag.
CurrentCampaignObject.insured_coldfeet_spda_flag as current_insured_coldfeet_spda_flag,
PrevCampaignObject.insured_coldfeet_spda_flag as prev_insured_coldfeet_spda_flag,

case when IFNULL(CurrentCampaignObject.insured_coldfeet_spda_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_spda_flag,-1)
        then 'Not Match'
        else '' end as check_insured_coldfeet_spda_flag,


--Match check for parameter: insured_coldfeet_spia_flag.
CurrentCampaignObject.insured_coldfeet_spia_flag as current_insured_coldfeet_spia_flag,
PrevCampaignObject.insured_coldfeet_spia_flag as prev_insured_coldfeet_spia_flag,

case when IFNULL(CurrentCampaignObject.insured_coldfeet_spia_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_spia_flag,-1)
        then 'Not Match'
        else '' end as check_insured_coldfeet_spia_flag,


--Match check for parameter: insured_coldfeet_directmailterm_flag.
CurrentCampaignObject.insured_coldfeet_directmailterm_flag as current_insured_coldfeet_directmailterm_flag,
PrevCampaignObject.insured_coldfeet_directmailterm_flag as prev_insured_coldfeet_directmailterm_flag,

case when IFNULL(CurrentCampaignObject.insured_coldfeet_directmailterm_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_directmailterm_flag,-1)
        then 'Not Match'
        else '' end as check_insured_coldfeet_directmailterm_flag,


--Match check for parameter: insured_coldfeet_expressterm_flag.
CurrentCampaignObject.insured_coldfeet_expressterm_flag as current_insured_coldfeet_expressterm_flag,
PrevCampaignObject.insured_coldfeet_expressterm_flag as prev_insured_coldfeet_expressterm_flag,

case when IFNULL(CurrentCampaignObject.insured_coldfeet_expressterm_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_expressterm_flag,-1)
        then 'Not Match'
        else '' end as check_insured_coldfeet_expressterm_flag,


--Match check for parameter: insured_coldfeet_individualdirectterm_flag.
CurrentCampaignObject.insured_coldfeet_individualdirectterm_flag as current_insured_coldfeet_individualdirectterm_flag,
PrevCampaignObject.insured_coldfeet_individualdirectterm_flag as prev_insured_coldfeet_individualdirectterm_flag,

case when IFNULL(CurrentCampaignObject.insured_coldfeet_individualdirectterm_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_individualdirectterm_flag,-1)
        then 'Not Match'
        else '' end as check_insured_coldfeet_individualdirectterm_flag,


--Match check for parameter: insured_coldfeet_term_flag.
CurrentCampaignObject.insured_coldfeet_term_flag as current_insured_coldfeet_term_flag,
PrevCampaignObject.insured_coldfeet_term_flag as prev_insured_coldfeet_term_flag,

case when IFNULL(CurrentCampaignObject.insured_coldfeet_term_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_term_flag,-1)
        then 'Not Match'
        else '' end as check_insured_coldfeet_term_flag,


--Match check for parameter: insured_coldfeet_accumulatorul_flag.
CurrentCampaignObject.insured_coldfeet_accumulatorul_flag as current_insured_coldfeet_accumulatorul_flag,
PrevCampaignObject.insured_coldfeet_accumulatorul_flag as prev_insured_coldfeet_accumulatorul_flag,

case when IFNULL(CurrentCampaignObject.insured_coldfeet_accumulatorul_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_accumulatorul_flag,-1)
        then 'Not Match'
        else '' end as check_insured_coldfeet_accumulatorul_flag,


--Match check for parameter: insured_coldfeet_lifetimeul_flag.
CurrentCampaignObject.insured_coldfeet_lifetimeul_flag as current_insured_coldfeet_lifetimeul_flag,
PrevCampaignObject.insured_coldfeet_lifetimeul_flag as prev_insured_coldfeet_lifetimeul_flag,

case when IFNULL(CurrentCampaignObject.insured_coldfeet_lifetimeul_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_lifetimeul_flag,-1)
        then 'Not Match'
        else '' end as check_insured_coldfeet_lifetimeul_flag,


--Match check for parameter: insured_coldfeet_siwl_flag.
CurrentCampaignObject.insured_coldfeet_siwl_flag as current_insured_coldfeet_siwl_flag,
PrevCampaignObject.insured_coldfeet_siwl_flag as prev_insured_coldfeet_siwl_flag,

case when IFNULL(CurrentCampaignObject.insured_coldfeet_siwl_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_siwl_flag,-1)
        then 'Not Match'
        else '' end as check_insured_coldfeet_siwl_flag,


--Match check for parameter: insured_coldfeet_giwl_flag.
CurrentCampaignObject.insured_coldfeet_giwl_flag as current_insured_coldfeet_giwl_flag,
PrevCampaignObject.insured_coldfeet_giwl_flag as prev_insured_coldfeet_giwl_flag,

case when IFNULL(CurrentCampaignObject.insured_coldfeet_giwl_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_giwl_flag,-1)
        then 'Not Match'
        else '' end as check_insured_coldfeet_giwl_flag,


--Match check for parameter: insured_coldfeet_juvenile_flag.
CurrentCampaignObject.insured_coldfeet_juvenile_flag as current_insured_coldfeet_juvenile_flag,
PrevCampaignObject.insured_coldfeet_juvenile_flag as prev_insured_coldfeet_juvenile_flag,

case when IFNULL(CurrentCampaignObject.insured_coldfeet_juvenile_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_juvenile_flag,-1)
        then 'Not Match'
        else '' end as check_insured_coldfeet_juvenile_flag,


--Match check for parameter: insured_coldfeet_wholelife_flag.
CurrentCampaignObject.insured_coldfeet_wholelife_flag as current_insured_coldfeet_wholelife_flag,
PrevCampaignObject.insured_coldfeet_wholelife_flag as prev_insured_coldfeet_wholelife_flag,

case when IFNULL(CurrentCampaignObject.insured_coldfeet_wholelife_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_wholelife_flag,-1)
        then 'Not Match'
        else '' end as check_insured_coldfeet_wholelife_flag,


--Match check for parameter: insured_churn_365_flag.
CurrentCampaignObject.insured_churn_365_flag as current_insured_churn_365_flag,
PrevCampaignObject.insured_churn_365_flag as prev_insured_churn_365_flag,

case when IFNULL(CurrentCampaignObject.insured_churn_365_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_365_flag,-1)
        then 'Not Match'
        else '' end as check_insured_churn_365_flag,


--Match check for parameter: insured_churn_accident_flag.
CurrentCampaignObject.insured_churn_accident_flag as current_insured_churn_accident_flag,
PrevCampaignObject.insured_churn_accident_flag as prev_insured_churn_accident_flag,

case when IFNULL(CurrentCampaignObject.insured_churn_accident_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_accident_flag,-1)
        then 'Not Match'
        else '' end as check_insured_churn_accident_flag,


--Match check for parameter: insured_churn_adb_flag.
CurrentCampaignObject.insured_churn_adb_flag as current_insured_churn_adb_flag,
PrevCampaignObject.insured_churn_adb_flag as prev_insured_churn_adb_flag,

case when IFNULL(CurrentCampaignObject.insured_churn_adb_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_adb_flag,-1)
        then 'Not Match'
        else '' end as check_insured_churn_adb_flag,


--Match check for parameter: insured_churn_hip_flag.
CurrentCampaignObject.insured_churn_hip_flag as current_insured_churn_hip_flag,
PrevCampaignObject.insured_churn_hip_flag as prev_insured_churn_hip_flag,

case when IFNULL(CurrentCampaignObject.insured_churn_hip_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_hip_flag,-1)
        then 'Not Match'
        else '' end as check_insured_churn_hip_flag,


--Match check for parameter: insured_churn_mlta_flag.
CurrentCampaignObject.insured_churn_mlta_flag as current_insured_churn_mlta_flag,
PrevCampaignObject.insured_churn_mlta_flag as prev_insured_churn_mlta_flag,

case when IFNULL(CurrentCampaignObject.insured_churn_mlta_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_mlta_flag,-1)
        then 'Not Match'
        else '' end as check_insured_churn_mlta_flag,


--Match check for parameter: insured_churn_mpa_flag.
CurrentCampaignObject.insured_churn_mpa_flag as current_insured_churn_mpa_flag,
PrevCampaignObject.insured_churn_mpa_flag as prev_insured_churn_mpa_flag,

case when IFNULL(CurrentCampaignObject.insured_churn_mpa_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_mpa_flag,-1)
        then 'Not Match'
        else '' end as check_insured_churn_mpa_flag,


--Match check for parameter: insured_churn_pai_flag.
CurrentCampaignObject.insured_churn_pai_flag as current_insured_churn_pai_flag,
PrevCampaignObject.insured_churn_pai_flag as prev_insured_churn_pai_flag,

case when IFNULL(CurrentCampaignObject.insured_churn_pai_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_pai_flag,-1)
        then 'Not Match'
        else '' end as check_insured_churn_pai_flag,


--Match check for parameter: insured_churn_pdd_flag.
CurrentCampaignObject.insured_churn_pdd_flag as current_insured_churn_pdd_flag,
PrevCampaignObject.insured_churn_pdd_flag as prev_insured_churn_pdd_flag,

case when IFNULL(CurrentCampaignObject.insured_churn_pdd_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_pdd_flag,-1)
        then 'Not Match'
        else '' end as check_insured_churn_pdd_flag,


--Match check for parameter: insured_churn_waiver_flag.
CurrentCampaignObject.insured_churn_waiver_flag as current_insured_churn_waiver_flag,
PrevCampaignObject.insured_churn_waiver_flag as prev_insured_churn_waiver_flag,

case when IFNULL(CurrentCampaignObject.insured_churn_waiver_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_waiver_flag,-1)
        then 'Not Match'
        else '' end as check_insured_churn_waiver_flag,


--Match check for parameter: insured_churn_fpda_flag.
CurrentCampaignObject.insured_churn_fpda_flag as current_insured_churn_fpda_flag,
PrevCampaignObject.insured_churn_fpda_flag as prev_insured_churn_fpda_flag,

case when IFNULL(CurrentCampaignObject.insured_churn_fpda_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_fpda_flag,-1)
        then 'Not Match'
        else '' end as check_insured_churn_fpda_flag,


--Match check for parameter: insured_churn_spda_flag.
CurrentCampaignObject.insured_churn_spda_flag as current_insured_churn_spda_flag,
PrevCampaignObject.insured_churn_spda_flag as prev_insured_churn_spda_flag,

case when IFNULL(CurrentCampaignObject.insured_churn_spda_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_spda_flag,-1)
        then 'Not Match'
        else '' end as check_insured_churn_spda_flag,


--Match check for parameter: insured_churn_spia_flag.
CurrentCampaignObject.insured_churn_spia_flag as current_insured_churn_spia_flag,
PrevCampaignObject.insured_churn_spia_flag as prev_insured_churn_spia_flag,

case when IFNULL(CurrentCampaignObject.insured_churn_spia_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_spia_flag,-1)
        then 'Not Match'
        else '' end as check_insured_churn_spia_flag,


--Match check for parameter: insured_churn_directmailterm_flag.
CurrentCampaignObject.insured_churn_directmailterm_flag as current_insured_churn_directmailterm_flag,
PrevCampaignObject.insured_churn_directmailterm_flag as prev_insured_churn_directmailterm_flag,

case when IFNULL(CurrentCampaignObject.insured_churn_directmailterm_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_directmailterm_flag,-1)
        then 'Not Match'
        else '' end as check_insured_churn_directmailterm_flag,


--Match check for parameter: insured_churn_expressterm_flag.
CurrentCampaignObject.insured_churn_expressterm_flag as current_insured_churn_expressterm_flag,
PrevCampaignObject.insured_churn_expressterm_flag as prev_insured_churn_expressterm_flag,

case when IFNULL(CurrentCampaignObject.insured_churn_expressterm_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_expressterm_flag,-1)
        then 'Not Match'
        else '' end as check_insured_churn_expressterm_flag,


--Match check for parameter: insured_churn_individualdirectterm_flag.
CurrentCampaignObject.insured_churn_individualdirectterm_flag as current_insured_churn_individualdirectterm_flag,
PrevCampaignObject.insured_churn_individualdirectterm_flag as prev_insured_churn_individualdirectterm_flag,

case when IFNULL(CurrentCampaignObject.insured_churn_individualdirectterm_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_individualdirectterm_flag,-1)
        then 'Not Match'
        else '' end as check_insured_churn_individualdirectterm_flag,


--Match check for parameter: insured_churn_term_flag.
CurrentCampaignObject.insured_churn_term_flag as current_insured_churn_term_flag,
PrevCampaignObject.insured_churn_term_flag as prev_insured_churn_term_flag,

case when IFNULL(CurrentCampaignObject.insured_churn_term_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_term_flag,-1)
        then 'Not Match'
        else '' end as check_insured_churn_term_flag,


--Match check for parameter: insured_churn_accumulatorul_flag.
CurrentCampaignObject.insured_churn_accumulatorul_flag as current_insured_churn_accumulatorul_flag,
PrevCampaignObject.insured_churn_accumulatorul_flag as prev_insured_churn_accumulatorul_flag,

case when IFNULL(CurrentCampaignObject.insured_churn_accumulatorul_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_accumulatorul_flag,-1)
        then 'Not Match'
        else '' end as check_insured_churn_accumulatorul_flag,


--Match check for parameter: insured_churn_lifetimeul_flag.
CurrentCampaignObject.insured_churn_lifetimeul_flag as current_insured_churn_lifetimeul_flag,
PrevCampaignObject.insured_churn_lifetimeul_flag as prev_insured_churn_lifetimeul_flag,

case when IFNULL(CurrentCampaignObject.insured_churn_lifetimeul_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_lifetimeul_flag,-1)
        then 'Not Match'
        else '' end as check_insured_churn_lifetimeul_flag,


--Match check for parameter: insured_churn_siwl_flag.
CurrentCampaignObject.insured_churn_siwl_flag as current_insured_churn_siwl_flag,
PrevCampaignObject.insured_churn_siwl_flag as prev_insured_churn_siwl_flag,

case when IFNULL(CurrentCampaignObject.insured_churn_siwl_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_siwl_flag,-1)
        then 'Not Match'
        else '' end as check_insured_churn_siwl_flag,


--Match check for parameter: insured_churn_giwl_flag.
CurrentCampaignObject.insured_churn_giwl_flag as current_insured_churn_giwl_flag,
PrevCampaignObject.insured_churn_giwl_flag as prev_insured_churn_giwl_flag,

case when IFNULL(CurrentCampaignObject.insured_churn_giwl_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_giwl_flag,-1)
        then 'Not Match'
        else '' end as check_insured_churn_giwl_flag,


--Match check for parameter: insured_churn_juvenile_flag.
CurrentCampaignObject.insured_churn_juvenile_flag as current_insured_churn_juvenile_flag,
PrevCampaignObject.insured_churn_juvenile_flag as prev_insured_churn_juvenile_flag,

case when IFNULL(CurrentCampaignObject.insured_churn_juvenile_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_juvenile_flag,-1)
        then 'Not Match'
        else '' end as check_insured_churn_juvenile_flag,


--Match check for parameter: insured_churn_wholelife_flag.
CurrentCampaignObject.insured_churn_wholelife_flag as current_insured_churn_wholelife_flag,
PrevCampaignObject.insured_churn_wholelife_flag as prev_insured_churn_wholelife_flag,

case when IFNULL(CurrentCampaignObject.insured_churn_wholelife_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_wholelife_flag,-1)
        then 'Not Match'
        else '' end as check_insured_churn_wholelife_flag,


--Match check for parameter: is_partial_lead.
CurrentCampaignObject.is_partial_lead as current_is_partial_lead,
PrevCampaignObject.is_partial_lead as prev_is_partial_lead,

case when IFNULL(CurrentCampaignObject.is_partial_lead,-1) <> IFNULL(PrevCampaignObject.is_partial_lead,-1)
        then 'Not Match'
        else '' end as check_is_partial_lead,


--Match check for parameter: is_closed_lead.
CurrentCampaignObject.is_closed_lead as current_is_closed_lead,
PrevCampaignObject.is_closed_lead as prev_is_closed_lead,

case when IFNULL(CurrentCampaignObject.is_closed_lead,-1) <> IFNULL(PrevCampaignObject.is_closed_lead,-1)
        then 'Not Match'
        else '' end as check_is_closed_lead,


--Match check for parameter: is_complete_lead.
CurrentCampaignObject.is_complete_lead as current_is_complete_lead,
PrevCampaignObject.is_complete_lead as prev_is_complete_lead,

case when IFNULL(CurrentCampaignObject.is_complete_lead,-1) <> IFNULL(PrevCampaignObject.is_complete_lead,-1)
        then 'Not Match'
        else '' end as check_is_complete_lead,


--Match check for parameter: is_open_lead.
CurrentCampaignObject.is_open_lead as current_is_open_lead,
PrevCampaignObject.is_open_lead as prev_is_open_lead,

case when IFNULL(CurrentCampaignObject.is_open_lead,-1) <> IFNULL(PrevCampaignObject.is_open_lead,-1)
        then 'Not Match'
        else '' end as check_is_open_lead,


--Match check for parameter: days_lead_in_salesforce.
CurrentCampaignObject.days_lead_in_salesforce as current_days_lead_in_salesforce,
PrevCampaignObject.days_lead_in_salesforce as prev_days_lead_in_salesforce,

case when IFNULL(CurrentCampaignObject.days_lead_in_salesforce,-1) <> IFNULL(PrevCampaignObject.days_lead_in_salesforce,-1)
        then 'Not Match'
        else '' end as check_days_lead_in_salesforce,

--Match check for parameter: days_since_express_term_adandon.
CurrentCampaignObject.days_since_express_term_adandon as current_days_since_express_term_adandon,
PrevCampaignObject.days_since_express_term_adandon as prev_days_since_express_term_adandon,

case when IFNULL(CurrentCampaignObject.days_since_express_term_adandon,-1) <> IFNULL(PrevCampaignObject.days_since_express_term_adandon,-1)
        then 'Not Match'
        else '' end as check_days_since_express_term_adandon,


--Match check for parameter: days_have_not_received_field_agent_quote.
CurrentCampaignObject.days_have_not_received_field_agent_quote as current_days_have_not_received_field_agent_quote,
PrevCampaignObject.days_have_not_received_field_agent_quote as prev_days_have_not_received_field_agent_quote,

case when IFNULL(CurrentCampaignObject.days_have_not_received_field_agent_quote,-1) <> IFNULL(PrevCampaignObject.days_have_not_received_field_agent_quote,-1)
        then 'Not Match'
        else '' end as check_days_have_not_received_field_agent_quote,


--Match check for parameter: interaction_driven.
CurrentCampaignObject.interaction_driven as current_interaction_driven,
PrevCampaignObject.interaction_driven as prev_interaction_driven,

case when IFNULL(CurrentCampaignObject.interaction_driven,-1) <> IFNULL(PrevCampaignObject.interaction_driven,-1)
        then 'Not Match'
        else '' end as check_interaction_driven,


--Match check for parameter: insured_giwl_2nd_policy_is_member.
CurrentCampaignObject.insured_giwl_2nd_policy_is_member as current_insured_giwl_2nd_policy_is_member,
PrevCampaignObject.insured_giwl_2nd_policy_is_member as prev_insured_giwl_2nd_policy_is_member,

case when IFNULL(CurrentCampaignObject.insured_giwl_2nd_policy_is_member,-1) <> IFNULL(PrevCampaignObject.insured_giwl_2nd_policy_is_member,-1)
        then 'Not Match'
        else '' end as check_insured_giwl_2nd_policy_is_member,


--Match check for parameter: insured_giwl_term_declined_is_member.
CurrentCampaignObject.insured_giwl_term_declined_is_member as current_insured_giwl_term_declined_is_member,
PrevCampaignObject.insured_giwl_term_declined_is_member as prev_insured_giwl_term_declined_is_member,

case when IFNULL(CurrentCampaignObject.insured_giwl_term_declined_is_member,-1) <> IFNULL(PrevCampaignObject.insured_giwl_term_declined_is_member,-1)
        then 'Not Match'
        else '' end as check_insured_giwl_term_declined_is_member,


--Match check for parameter: insured_giwl_lapsed_is_members.
CurrentCampaignObject.insured_giwl_lapsed_is_members as current_insured_giwl_lapsed_is_members,
PrevCampaignObject.insured_giwl_lapsed_is_members as prev_insured_giwl_lapsed_is_members,

case when IFNULL(CurrentCampaignObject.insured_giwl_lapsed_is_members,-1) <> IFNULL(PrevCampaignObject.insured_giwl_lapsed_is_members,-1)
        then 'Not Match'
        else '' end as check_insured_giwl_lapsed_is_members,


--Match check for parameter: insured_giwl_xsell_is_member.
CurrentCampaignObject.insured_giwl_xsell_is_member as current_insured_giwl_xsell_is_member,
PrevCampaignObject.insured_giwl_xsell_is_member as prev_insured_giwl_xsell_is_member,

case when IFNULL(CurrentCampaignObject.insured_giwl_xsell_is_member,-1) <> IFNULL(PrevCampaignObject.insured_giwl_xsell_is_member,-1)
        then 'Not Match'
        else '' end as check_insured_giwl_xsell_is_member,


--Match check for parameter: Insured_Errored_Transaction.
CurrentCampaignObject.Insured_Errored_Transaction as current_Insured_Errored_Transaction,
PrevCampaignObject.Insured_Errored_Transaction as prev_Insured_Errored_Transaction,

case when IFNULL(CurrentCampaignObject.Insured_Errored_Transaction,-1) <> IFNULL(PrevCampaignObject.Insured_Errored_Transaction,-1)
        then 'Not Match'
        else '' end as check_Insured_Errored_Transaction,


--Match check for parameter: Insured_P_Transaction.
CurrentCampaignObject.Insured_P_Transaction as current_Insured_P_Transaction,
PrevCampaignObject.Insured_P_Transaction as prev_Insured_P_Transaction,

case when IFNULL(CurrentCampaignObject.Insured_P_Transaction,-1) <> IFNULL(PrevCampaignObject.Insured_P_Transaction,-1)
        then 'Not Match'
        else '' end as check_Insured_P_Transaction,


--Match check for parameter: Insured_PremiumPaying_DirectMailTerm.
CurrentCampaignObject.Insured_PremiumPaying_DirectMailTerm as current_Insured_PremiumPaying_DirectMailTerm,
PrevCampaignObject.Insured_PremiumPaying_DirectMailTerm as prev_Insured_PremiumPaying_DirectMailTerm,

case when IFNULL(CurrentCampaignObject.Insured_PremiumPaying_DirectMailTerm,-1) <> IFNULL(PrevCampaignObject.Insured_PremiumPaying_DirectMailTerm,-1)
        then 'Not Match'
        else '' end as check_Insured_PremiumPaying_DirectMailTerm,


--Match check for parameter: prospect_status.
CurrentCampaignObject.prospect_status as current_prospect_status,
PrevCampaignObject.prospect_status as prev_prospect_status,

case when IFNULL(CurrentCampaignObject.prospect_status,-1) <> IFNULL(PrevCampaignObject.prospect_status,-1)
        then 'Not Match'
        else '' end as check_prospect_status

from CurrentCampaignObject
left join PrevCampaignObject on
    CurrentCampaignObject.trimmed_cell_name = PrevCampaignObject.last_trimmed_cell_name
    and CurrentCampaignObject.tactic_name = PrevCampaignObject.last_tactic_name

inner join planner_cell on
    planner_cell.id = PrevCampaignObject.last_cell_id

//where
//
////(
////
////    case when IFNULL(CurrentCampaignObject.resolved_age_min,-1) <> IFNULL(PrevCampaignObject.resolved_age_min,-1)
////        then 'Not Match'
////        else '' end = 'Not Match')
////OR
////(
////
////    case when IFNULL(CurrentCampaignObject.resolved_age_max,-1) <> IFNULL(PrevCampaignObject.resolved_age_max,-1)
////        then 'Not Match'
////        else '' end = 'Not Match')
////OR
////(
////
////    case when IFNULL(CurrentCampaignObject.unknown_age_inclusion,-1) <> IFNULL(PrevCampaignObject.unknown_age_inclusion,-1)
////        then 'Not Match'
////        else '' end = 'Not Match')
////OR
//(
//
//    case when IFNULL(CurrentCampaignObject.milliman_min,-1) <> IFNULL(PrevCampaignObject.milliman_min,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.milliman_max,-1) <> IFNULL(PrevCampaignObject.milliman_max,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.milliman_exclusion,-1) <> IFNULL(PrevCampaignObject.milliman_exclusion,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.unknown_milliman_inclusion,-1) <> IFNULL(PrevCampaignObject.unknown_milliman_inclusion,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.is_prospect,-1) <> IFNULL(PrevCampaignObject.is_prospect,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.is_member,-1) <> IFNULL(PrevCampaignObject.is_member,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.is_customer,-1) <> IFNULL(PrevCampaignObject.is_customer,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.gender_male,-1) <> IFNULL(PrevCampaignObject.gender_male,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.gender_female,-1) <> IFNULL(PrevCampaignObject.gender_female,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.gender_unknown,-1) <> IFNULL(PrevCampaignObject.gender_unknown,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.member_role,-1) <> IFNULL(PrevCampaignObject.member_role,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.unknown_member_role_inclusion,-1) <> IFNULL(PrevCampaignObject.unknown_member_role_inclusion,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.product_eligibility_direct_mail_term,-1) <> IFNULL(PrevCampaignObject.product_eligibility_direct_mail_term,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.product_eligibility_giwl,-1) <> IFNULL(PrevCampaignObject.product_eligibility_giwl,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.product_eligibility_mlta,-1) <> IFNULL(PrevCampaignObject.product_eligibility_mlta,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.product_eligibility_accident,-1) <> IFNULL(PrevCampaignObject.product_eligibility_accident,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.product_eligibility_traditional_term,-1) <> IFNULL(PrevCampaignObject.product_eligibility_traditional_term,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.product_eligibility_express_term,-1) <> IFNULL(PrevCampaignObject.product_eligibility_express_term,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.product_eligibility_individualdirectterm,-1) <> IFNULL(PrevCampaignObject.product_eligibility_individualdirectterm,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.direct_mail_term_upsell_eligibility,-1) <> IFNULL(PrevCampaignObject.direct_mail_term_upsell_eligibility,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.direct_mail_term_upsell_total_face_amount,-1) <> IFNULL(PrevCampaignObject.direct_mail_term_upsell_total_face_amount,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.giwl_upsell_total_face_amount,-1) <> IFNULL(PrevCampaignObject.giwl_upsell_total_face_amount,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.giwl_upsell_eligibility,-1) <> IFNULL(PrevCampaignObject.giwl_upsell_eligibility,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.declined_lifeproduct_flag,-1) <> IFNULL(PrevCampaignObject.declined_lifeproduct_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.declined_accidentproduct_flag,-1) <> IFNULL(PrevCampaignObject.declined_accidentproduct_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.declined_365_flag,-1) <> IFNULL(PrevCampaignObject.declined_365_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.declined_accident_flag,-1) <> IFNULL(PrevCampaignObject.declined_accident_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.declined_adb_flag,-1) <> IFNULL(PrevCampaignObject.declined_adb_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.declined_hip_flag,-1) <> IFNULL(PrevCampaignObject.declined_hip_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.declined_mlta_flag,-1) <> IFNULL(PrevCampaignObject.declined_mlta_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.declined_mpa_flag,-1) <> IFNULL(PrevCampaignObject.declined_mpa_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.declined_pai_flag,-1) <> IFNULL(PrevCampaignObject.declined_pai_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.declined_pdd_flag,-1) <> IFNULL(PrevCampaignObject.declined_pdd_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.declined_waiver_flag,-1) <> IFNULL(PrevCampaignObject.declined_waiver_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.declined_fpda_flag,-1) <> IFNULL(PrevCampaignObject.declined_fpda_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.declined_spda_flag,-1) <> IFNULL(PrevCampaignObject.declined_spda_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.declined_spia_flag,-1) <> IFNULL(PrevCampaignObject.declined_spia_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.declined_directmailterm_flag,-1) <> IFNULL(PrevCampaignObject.declined_directmailterm_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.declined_expressterm_flag,-1) <> IFNULL(PrevCampaignObject.declined_expressterm_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.declined_individualdirectterm_flag,-1) <> IFNULL(PrevCampaignObject.declined_individualdirectterm_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.declined_term_flag,-1) <> IFNULL(PrevCampaignObject.declined_term_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.declined_accumulatorul_flag,-1) <> IFNULL(PrevCampaignObject.declined_accumulatorul_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.declined_lifetimeul_flag,-1) <> IFNULL(PrevCampaignObject.declined_lifetimeul_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.declined_siwl_flag,-1) <> IFNULL(PrevCampaignObject.declined_siwl_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.declined_giwl_flag,-1) <> IFNULL(PrevCampaignObject.declined_giwl_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.declined_juvenile_flag,-1) <> IFNULL(PrevCampaignObject.declined_juvenile_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.declined_wholelife_flag,-1) <> IFNULL(PrevCampaignObject.declined_wholelife_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.club_ok_to_mail,-1) <> IFNULL(PrevCampaignObject.club_ok_to_mail,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.total_insured_inforce_policies,-1) <> IFNULL(PrevCampaignObject.total_insured_inforce_policies,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_inforce_lifeproduct_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_lifeproduct_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_inforce_accidentproduct_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_accidentproduct_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_inforce_annuityproduct_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_annuityproduct_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_inforce_365_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_365_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_inforce_accident_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_accident_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_inforce_adb_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_adb_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_inforce_hip_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_hip_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_inforce_mlta_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_mlta_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_inforce_mpa_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_mpa_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_inforce_pai_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_pai_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_inforce_pdd_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_pdd_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_inforce_waiver_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_waiver_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_inforce_fpda_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_fpda_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_inforce_spda_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_spda_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_inforce_spia_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_spia_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_inforce_directmailterm_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_directmailterm_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_inforce_expressterm_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_expressterm_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_inforce_individualdirectterm_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_individualdirectterm_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_inforce_term_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_term_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_inforce_accumulatorul_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_accumulatorul_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_inforce_lifetimeul_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_lifetimeul_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_inforce_siwl_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_siwl_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_inforce_giwl_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_giwl_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_inforce_juvenile_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_juvenile_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_inforce_wholelife_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_wholelife_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_activeapp_lifeproduct_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_lifeproduct_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_activeapp_accidentproduct_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_accidentproduct_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_activeapp_annuityproduct_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_annuityproduct_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_activeapp_365_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_365_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_activeapp_accident_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_accident_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_activeapp_adb_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_adb_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_activeapp_hip_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_hip_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_activeapp_mlta_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_mlta_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_activeapp_mpa_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_mpa_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_activeapp_pai_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_pai_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_activeapp_pdd_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_pdd_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_activeapp_waiver_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_waiver_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_activeapp_fpda_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_fpda_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_activeapp_spda_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_spda_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_activeapp_spia_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_spia_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_activeapp_directmailterm_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_directmailterm_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_activeapp_expressterm_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_expressterm_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_activeapp_individualdirectterm_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_individualdirectterm_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_activeapp_term_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_term_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_activeapp_accumulatorul_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_accumulatorul_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_activeapp_lifetimeul_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_lifetimeul_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_activeapp_siwl_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_siwl_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_activeapp_giwl_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_giwl_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_activeapp_juvenile_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_juvenile_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_activeapp_wholelife_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_wholelife_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_coldfeet_365_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_365_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_coldfeet_accident_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_accident_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_coldfeet_adb_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_adb_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_coldfeet_hip_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_hip_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_coldfeet_mlta_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_mlta_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_coldfeet_mpa_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_mpa_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_coldfeet_pai_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_pai_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_coldfeet_pdd_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_pdd_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_coldfeet_waiver_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_waiver_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_coldfeet_fpda_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_fpda_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_coldfeet_spda_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_spda_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_coldfeet_spia_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_spia_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_coldfeet_directmailterm_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_directmailterm_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_coldfeet_expressterm_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_expressterm_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_coldfeet_individualdirectterm_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_individualdirectterm_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_coldfeet_term_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_term_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_coldfeet_accumulatorul_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_accumulatorul_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_coldfeet_lifetimeul_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_lifetimeul_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_coldfeet_siwl_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_siwl_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_coldfeet_giwl_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_giwl_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_coldfeet_juvenile_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_juvenile_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_coldfeet_wholelife_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_wholelife_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_churn_365_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_365_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_churn_accident_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_accident_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_churn_adb_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_adb_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_churn_hip_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_hip_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_churn_mlta_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_mlta_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_churn_mpa_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_mpa_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_churn_pai_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_pai_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_churn_pdd_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_pdd_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_churn_waiver_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_waiver_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_churn_fpda_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_fpda_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_churn_spda_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_spda_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_churn_spia_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_spia_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_churn_directmailterm_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_directmailterm_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_churn_expressterm_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_expressterm_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_churn_individualdirectterm_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_individualdirectterm_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_churn_term_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_term_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_churn_accumulatorul_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_accumulatorul_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_churn_lifetimeul_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_lifetimeul_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_churn_siwl_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_siwl_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_churn_giwl_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_giwl_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_churn_juvenile_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_juvenile_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_churn_wholelife_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_wholelife_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.is_partial_lead,-1) <> IFNULL(PrevCampaignObject.is_partial_lead,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.is_closed_lead,-1) <> IFNULL(PrevCampaignObject.is_closed_lead,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.is_complete_lead,-1) <> IFNULL(PrevCampaignObject.is_complete_lead,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.is_open_lead,-1) <> IFNULL(PrevCampaignObject.is_open_lead,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.days_lead_in_salesforce,-1) <> IFNULL(PrevCampaignObject.days_lead_in_salesforce,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.days_since_express_term_adandon,-1) <> IFNULL(PrevCampaignObject.days_since_express_term_adandon,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.days_have_not_received_field_agent_quote,-1) <> IFNULL(PrevCampaignObject.days_have_not_received_field_agent_quote,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.interaction_driven,-1) <> IFNULL(PrevCampaignObject.interaction_driven,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_giwl_2nd_policy_is_member,-1) <> IFNULL(PrevCampaignObject.insured_giwl_2nd_policy_is_member,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_giwl_term_declined_is_member,-1) <> IFNULL(PrevCampaignObject.insured_giwl_term_declined_is_member,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_giwl_lapsed_is_members,-1) <> IFNULL(PrevCampaignObject.insured_giwl_lapsed_is_members,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_giwl_xsell_is_member,-1) <> IFNULL(PrevCampaignObject.insured_giwl_xsell_is_member,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.Insured_Errored_Transaction,-1) <> IFNULL(PrevCampaignObject.Insured_Errored_Transaction,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.Insured_P_Transaction,-1) <> IFNULL(PrevCampaignObject.Insured_P_Transaction,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.Insured_PremiumPaying_DirectMailTerm,-1) <> IFNULL(PrevCampaignObject.Insured_PremiumPaying_DirectMailTerm,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.prospect_status,-1) <> IFNULL(PrevCampaignObject.prospect_status,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//
//order by
//    CurrentCampaignObject.tactic_name,
//    case when CurrentCampaignObject.cell_parameter_id = planner_cell.parameters_id
//    then 'same_param' else 'different_param' end asc
),
CS_portion as (
with CurrentCampaignObject as (Select  Distinct
    (planner_marketingprogram.id) as 'marketing_program_id'
    , planner_marketingprogram.NAME as 'marketing_program_name'
    , planner_initiative.id as 'initiative_id'
    , planner_initiative.name as 'initiative_name'
    ,planner_campaign.id as 'campaign_id'
    ,planner_campaign.name as 'campaign_name'
    ,planner_distributionchannel.id as 'distributionchannel_id'
    ,planner_distributionchannel.description as 'distributionchannel_description'
    ,planner_tactic.id as 'tactic_id'
    ,planner_tactic.name as 'tactic_name'
    , planner_cell.id as 'cell_id'
    , planner_cell.name as 'cell_name'
    , planner_cell.parameters_id as 'cell_parameter_id'

    ,campaign_parameters_selectionparameters.*
from planner_marketingprogram
left join planner_initiative on planner_initiative.marketing_program_id = planner_marketingprogram.id
left join planner_campaign on planner_initiative.id = planner_campaign.initiative_id
left join planner_distributionchannel  on planner_campaign.distribution_channel_id = planner_distributionchannel.id
left join planner_campaigntype on planner_campaign.campaign_type_id = planner_campaigntype.id
left join planner_tactic on planner_campaign.id = planner_tactic.campaign_id
left join planner_tactictype on planner_tactictype.id = planner_tactic.type_id
left join planner_cell on planner_tactic.id = planner_cell.tactic_id
inner join  campaign_parameters_selectionparameters
    on planner_cell.parameters_id = campaign_parameters_selectionparameters.id

where planner_tactic.name like '%CS%'
    and planner_campaign.name = '{0}'
),
PrevCampaignObject as (
     with prev_1 as (
             select distinct

                planner_cell.id as 'Last_cell_id',
                planner_cell.name as 'last_cell_name',
                planner_tactic.name as 'last_tactic_name'

            from planner_marketingprogram
            left join planner_initiative on planner_initiative.marketing_program_id = planner_marketingprogram.id
            left join planner_campaign on planner_initiative.id = planner_campaign.initiative_id
            left join planner_distributionchannel  on planner_campaign.distribution_channel_id = planner_distributionchannel.id
            left join planner_campaigntype on planner_campaign.campaign_type_id = planner_campaigntype.id
            left join planner_tactic on planner_campaign.id = planner_tactic.campaign_id
            left join planner_tactictype on planner_tactictype.id = planner_tactic.type_id
            left join planner_cell on planner_tactic.id = planner_cell.tactic_id
            where planner_cell.name in (
                select distinct
                    cell_name
                from CurrentCampaignObject
            )
            and planner_cell.id not in (
                select distinct
                    cell_id
                from CurrentCampaignObject
            )
        ),
        prev_2 as (
            select
                max(Last_cell_id) as Last_cell_id,
                last_cell_name,
                last_tactic_name
            from prev_1
            group by
                last_cell_name,
                last_tactic_name
        ),
    param as (
        select
            prev_2.*,
            campaign_parameters_selectionparameters.*
        from prev_2
        inner join planner_cell on planner_cell.id = prev_2.Last_cell_id
        inner join  campaign_parameters_selectionparameters
            on planner_cell.parameters_id = campaign_parameters_selectionparameters.id
        )
    select
    *
    from param
)

select distinct
    CurrentCampaignObject.marketing_program_id,
    CurrentCampaignObject.marketing_program_name,
    CurrentCampaignObject.initiative_id,
    CurrentCampaignObject.initiative_name,
    CurrentCampaignObject.campaign_id,
    CurrentCampaignObject.campaign_name,
    CurrentCampaignObject.distributionchannel_id,
    CurrentCampaignObject.distributionchannel_description,
    CurrentCampaignObject.tactic_id,
    CurrentCampaignObject.tactic_name,
    CurrentCampaignObject.cell_id,
    CurrentCampaignObject.cell_name,
    CurrentCampaignObject.cell_name as trimmed_cell_name,
    last_cell_id,

    CurrentCampaignObject.cell_parameter_id,
    PrevCampaignObject.id as last_cell_param,
    case when CurrentCampaignObject.cell_parameter_id = PrevCampaignObject.id
    then 'same_param' else 'different_param' end as param_check,

//--Match check for parameter: resolved_age_min.
//CurrentCampaignObject.resolved_age_min as current_resolved_age_min,
//PrevCampaignObject.resolved_age_min as prev_resolved_age_min,
//
//case when IFNULL(CurrentCampaignObject.resolved_age_min,-1) <> IFNULL(PrevCampaignObject.resolved_age_min,-1)
//        then 'Not Match'
//        else '' end as check_resolved_age_min,
//
//
//--Match check for parameter: resolved_age_max.
//CurrentCampaignObject.resolved_age_max as current_resolved_age_max,
//PrevCampaignObject.resolved_age_max as prev_resolved_age_max,
//
//case when IFNULL(CurrentCampaignObject.resolved_age_max,-1) <> IFNULL(PrevCampaignObject.resolved_age_max,-1)
//        then 'Not Match'
//        else '' end as check_resolved_age_max,
//
//
//--Match check for parameter: unknown_age_inclusion.
//CurrentCampaignObject.unknown_age_inclusion as current_unknown_age_inclusion,
//PrevCampaignObject.unknown_age_inclusion as prev_unknown_age_inclusion,
//
//case when IFNULL(CurrentCampaignObject.unknown_age_inclusion,-1) <> IFNULL(PrevCampaignObject.unknown_age_inclusion,-1)
//        then 'Not Match'
//        else '' end as check_unknown_age_inclusion,
//

--Match check for parameter: milliman_min.
CurrentCampaignObject.milliman_min as current_milliman_min,
PrevCampaignObject.milliman_min as prev_milliman_min,

case when IFNULL(CurrentCampaignObject.milliman_min,-1) <> IFNULL(PrevCampaignObject.milliman_min,-1)
        then 'Not Match'
        else '' end as check_milliman_min,


--Match check for parameter: milliman_max.
CurrentCampaignObject.milliman_max as current_milliman_max,
PrevCampaignObject.milliman_max as prev_milliman_max,

case when IFNULL(CurrentCampaignObject.milliman_max,-1) <> IFNULL(PrevCampaignObject.milliman_max,-1)
        then 'Not Match'
        else '' end as check_milliman_max,


--Match check for parameter: milliman_exclusion.
CurrentCampaignObject.milliman_exclusion as current_milliman_exclusion,
PrevCampaignObject.milliman_exclusion as prev_milliman_exclusion,

case when IFNULL(CurrentCampaignObject.milliman_exclusion,-1) <> IFNULL(PrevCampaignObject.milliman_exclusion,-1)
        then 'Not Match'
        else '' end as check_milliman_exclusion,


--Match check for parameter: unknown_milliman_inclusion.
CurrentCampaignObject.unknown_milliman_inclusion as current_unknown_milliman_inclusion,
PrevCampaignObject.unknown_milliman_inclusion as prev_unknown_milliman_inclusion,

case when IFNULL(CurrentCampaignObject.unknown_milliman_inclusion,-1) <> IFNULL(PrevCampaignObject.unknown_milliman_inclusion,-1)
        then 'Not Match'
        else '' end as check_unknown_milliman_inclusion,

--Match check for parameter: is_prospect.
CurrentCampaignObject.is_prospect as current_is_prospect,
PrevCampaignObject.is_prospect as prev_is_prospect,

case when IFNULL(CurrentCampaignObject.is_prospect,-1) <> IFNULL(PrevCampaignObject.is_prospect,-1)
        then 'Not Match'
        else '' end as check_is_prospect,


--Match check for parameter: is_member.
CurrentCampaignObject.is_member as current_is_member,
PrevCampaignObject.is_member as prev_is_member,

case when IFNULL(CurrentCampaignObject.is_member,-1) <> IFNULL(PrevCampaignObject.is_member,-1)
        then 'Not Match'
        else '' end as check_is_member,


--Match check for parameter: is_customer.
CurrentCampaignObject.is_customer as current_is_customer,
PrevCampaignObject.is_customer as prev_is_customer,

case when IFNULL(CurrentCampaignObject.is_customer,-1) <> IFNULL(PrevCampaignObject.is_customer,-1)
        then 'Not Match'
        else '' end as check_is_customer,


--Match check for parameter: gender_male.
CurrentCampaignObject.gender_male as current_gender_male,
PrevCampaignObject.gender_male as prev_gender_male,

case when IFNULL(CurrentCampaignObject.gender_male,-1) <> IFNULL(PrevCampaignObject.gender_male,-1)
        then 'Not Match'
        else '' end as check_gender_male,


--Match check for parameter: gender_female.
CurrentCampaignObject.gender_female as current_gender_female,
PrevCampaignObject.gender_female as prev_gender_female,

case when IFNULL(CurrentCampaignObject.gender_female,-1) <> IFNULL(PrevCampaignObject.gender_female,-1)
        then 'Not Match'
        else '' end as check_gender_female,


--Match check for parameter: gender_unknown.
CurrentCampaignObject.gender_unknown as current_gender_unknown,
PrevCampaignObject.gender_unknown as prev_gender_unknown,

case when IFNULL(CurrentCampaignObject.gender_unknown,-1) <> IFNULL(PrevCampaignObject.gender_unknown,-1)
        then 'Not Match'
        else '' end as check_gender_unknown,


--Match check for parameter: member_role.
CurrentCampaignObject.member_role as current_member_role,
PrevCampaignObject.member_role as prev_member_role,

case when IFNULL(CurrentCampaignObject.member_role,-1) <> IFNULL(PrevCampaignObject.member_role,-1)
        then 'Not Match'
        else '' end as check_member_role,


--Match check for parameter: unknown_member_role_inclusion.
CurrentCampaignObject.unknown_member_role_inclusion as current_unknown_member_role_inclusion,
PrevCampaignObject.unknown_member_role_inclusion as prev_unknown_member_role_inclusion,

case when IFNULL(CurrentCampaignObject.unknown_member_role_inclusion,-1) <> IFNULL(PrevCampaignObject.unknown_member_role_inclusion,-1)
        then 'Not Match'
        else '' end as check_unknown_member_role_inclusion,


--Match check for parameter: product_eligibility_direct_mail_term.
CurrentCampaignObject.product_eligibility_direct_mail_term as current_product_eligibility_direct_mail_term,
PrevCampaignObject.product_eligibility_direct_mail_term as prev_product_eligibility_direct_mail_term,

case when IFNULL(CurrentCampaignObject.product_eligibility_direct_mail_term,-1) <> IFNULL(PrevCampaignObject.product_eligibility_direct_mail_term,-1)
        then 'Not Match'
        else '' end as check_product_eligibility_direct_mail_term,


--Match check for parameter: product_eligibility_giwl.
CurrentCampaignObject.product_eligibility_giwl as current_product_eligibility_giwl,
PrevCampaignObject.product_eligibility_giwl as prev_product_eligibility_giwl,

case when IFNULL(CurrentCampaignObject.product_eligibility_giwl,-1) <> IFNULL(PrevCampaignObject.product_eligibility_giwl,-1)
        then 'Not Match'
        else '' end as check_product_eligibility_giwl,


--Match check for parameter: product_eligibility_mlta.
CurrentCampaignObject.product_eligibility_mlta as current_product_eligibility_mlta,
PrevCampaignObject.product_eligibility_mlta as prev_product_eligibility_mlta,

case when IFNULL(CurrentCampaignObject.product_eligibility_mlta,-1) <> IFNULL(PrevCampaignObject.product_eligibility_mlta,-1)
        then 'Not Match'
        else '' end as check_product_eligibility_mlta,


--Match check for parameter: product_eligibility_accident.
CurrentCampaignObject.product_eligibility_accident as current_product_eligibility_accident,
PrevCampaignObject.product_eligibility_accident as prev_product_eligibility_accident,

case when IFNULL(CurrentCampaignObject.product_eligibility_accident,-1) <> IFNULL(PrevCampaignObject.product_eligibility_accident,-1)
        then 'Not Match'
        else '' end as check_product_eligibility_accident,


--Match check for parameter: product_eligibility_traditional_term.
CurrentCampaignObject.product_eligibility_traditional_term as current_product_eligibility_traditional_term,
PrevCampaignObject.product_eligibility_traditional_term as prev_product_eligibility_traditional_term,

case when IFNULL(CurrentCampaignObject.product_eligibility_traditional_term,-1) <> IFNULL(PrevCampaignObject.product_eligibility_traditional_term,-1)
        then 'Not Match'
        else '' end as check_product_eligibility_traditional_term,


--Match check for parameter: product_eligibility_express_term.
CurrentCampaignObject.product_eligibility_express_term as current_product_eligibility_express_term,
PrevCampaignObject.product_eligibility_express_term as prev_product_eligibility_express_term,

case when IFNULL(CurrentCampaignObject.product_eligibility_express_term,-1) <> IFNULL(PrevCampaignObject.product_eligibility_express_term,-1)
        then 'Not Match'
        else '' end as check_product_eligibility_express_term,


--Match check for parameter: product_eligibility_individualdirectterm.
CurrentCampaignObject.product_eligibility_individualdirectterm as current_product_eligibility_individualdirectterm,
PrevCampaignObject.product_eligibility_individualdirectterm as prev_product_eligibility_individualdirectterm,

case when IFNULL(CurrentCampaignObject.product_eligibility_individualdirectterm,-1) <> IFNULL(PrevCampaignObject.product_eligibility_individualdirectterm,-1)
        then 'Not Match'
        else '' end as check_product_eligibility_individualdirectterm,


--Match check for parameter: direct_mail_term_upsell_eligibility.
CurrentCampaignObject.direct_mail_term_upsell_eligibility as current_direct_mail_term_upsell_eligibility,
PrevCampaignObject.direct_mail_term_upsell_eligibility as prev_direct_mail_term_upsell_eligibility,

case when IFNULL(CurrentCampaignObject.direct_mail_term_upsell_eligibility,-1) <> IFNULL(PrevCampaignObject.direct_mail_term_upsell_eligibility,-1)
        then 'Not Match'
        else '' end as check_direct_mail_term_upsell_eligibility,


--Match check for parameter: direct_mail_term_upsell_total_face_amount.
CurrentCampaignObject.direct_mail_term_upsell_total_face_amount as current_direct_mail_term_upsell_total_face_amount,
PrevCampaignObject.direct_mail_term_upsell_total_face_amount as prev_direct_mail_term_upsell_total_face_amount,

case when IFNULL(CurrentCampaignObject.direct_mail_term_upsell_total_face_amount,-1) <> IFNULL(PrevCampaignObject.direct_mail_term_upsell_total_face_amount,-1)
        then 'Not Match'
        else '' end as check_direct_mail_term_upsell_total_face_amount,


--Match check for parameter: giwl_upsell_total_face_amount.
CurrentCampaignObject.giwl_upsell_total_face_amount as current_giwl_upsell_total_face_amount,
PrevCampaignObject.giwl_upsell_total_face_amount as prev_giwl_upsell_total_face_amount,

case when IFNULL(CurrentCampaignObject.giwl_upsell_total_face_amount,-1) <> IFNULL(PrevCampaignObject.giwl_upsell_total_face_amount,-1)
        then 'Not Match'
        else '' end as check_giwl_upsell_total_face_amount,


--Match check for parameter: giwl_upsell_eligibility.
CurrentCampaignObject.giwl_upsell_eligibility as current_giwl_upsell_eligibility,
PrevCampaignObject.giwl_upsell_eligibility as prev_giwl_upsell_eligibility,

case when IFNULL(CurrentCampaignObject.giwl_upsell_eligibility,-1) <> IFNULL(PrevCampaignObject.giwl_upsell_eligibility,-1)
        then 'Not Match'
        else '' end as check_giwl_upsell_eligibility,


--Match check for parameter: declined_lifeproduct_flag.
CurrentCampaignObject.declined_lifeproduct_flag as current_declined_lifeproduct_flag,
PrevCampaignObject.declined_lifeproduct_flag as prev_declined_lifeproduct_flag,

case when IFNULL(CurrentCampaignObject.declined_lifeproduct_flag,-1) <> IFNULL(PrevCampaignObject.declined_lifeproduct_flag,-1)
        then 'Not Match'
        else '' end as check_declined_lifeproduct_flag,


--Match check for parameter: declined_accidentproduct_flag.
CurrentCampaignObject.declined_accidentproduct_flag as current_declined_accidentproduct_flag,
PrevCampaignObject.declined_accidentproduct_flag as prev_declined_accidentproduct_flag,

case when IFNULL(CurrentCampaignObject.declined_accidentproduct_flag,-1) <> IFNULL(PrevCampaignObject.declined_accidentproduct_flag,-1)
        then 'Not Match'
        else '' end as check_declined_accidentproduct_flag,


--Match check for parameter: declined_365_flag.
CurrentCampaignObject.declined_365_flag as current_declined_365_flag,
PrevCampaignObject.declined_365_flag as prev_declined_365_flag,

case when IFNULL(CurrentCampaignObject.declined_365_flag,-1) <> IFNULL(PrevCampaignObject.declined_365_flag,-1)
        then 'Not Match'
        else '' end as check_declined_365_flag,


--Match check for parameter: declined_accident_flag.
CurrentCampaignObject.declined_accident_flag as current_declined_accident_flag,
PrevCampaignObject.declined_accident_flag as prev_declined_accident_flag,

case when IFNULL(CurrentCampaignObject.declined_accident_flag,-1) <> IFNULL(PrevCampaignObject.declined_accident_flag,-1)
        then 'Not Match'
        else '' end as check_declined_accident_flag,


--Match check for parameter: declined_adb_flag.
CurrentCampaignObject.declined_adb_flag as current_declined_adb_flag,
PrevCampaignObject.declined_adb_flag as prev_declined_adb_flag,

case when IFNULL(CurrentCampaignObject.declined_adb_flag,-1) <> IFNULL(PrevCampaignObject.declined_adb_flag,-1)
        then 'Not Match'
        else '' end as check_declined_adb_flag,


--Match check for parameter: declined_hip_flag.
CurrentCampaignObject.declined_hip_flag as current_declined_hip_flag,
PrevCampaignObject.declined_hip_flag as prev_declined_hip_flag,

case when IFNULL(CurrentCampaignObject.declined_hip_flag,-1) <> IFNULL(PrevCampaignObject.declined_hip_flag,-1)
        then 'Not Match'
        else '' end as check_declined_hip_flag,


--Match check for parameter: declined_mlta_flag.
CurrentCampaignObject.declined_mlta_flag as current_declined_mlta_flag,
PrevCampaignObject.declined_mlta_flag as prev_declined_mlta_flag,

case when IFNULL(CurrentCampaignObject.declined_mlta_flag,-1) <> IFNULL(PrevCampaignObject.declined_mlta_flag,-1)
        then 'Not Match'
        else '' end as check_declined_mlta_flag,


--Match check for parameter: declined_mpa_flag.
CurrentCampaignObject.declined_mpa_flag as current_declined_mpa_flag,
PrevCampaignObject.declined_mpa_flag as prev_declined_mpa_flag,

case when IFNULL(CurrentCampaignObject.declined_mpa_flag,-1) <> IFNULL(PrevCampaignObject.declined_mpa_flag,-1)
        then 'Not Match'
        else '' end as check_declined_mpa_flag,


--Match check for parameter: declined_pai_flag.
CurrentCampaignObject.declined_pai_flag as current_declined_pai_flag,
PrevCampaignObject.declined_pai_flag as prev_declined_pai_flag,

case when IFNULL(CurrentCampaignObject.declined_pai_flag,-1) <> IFNULL(PrevCampaignObject.declined_pai_flag,-1)
        then 'Not Match'
        else '' end as check_declined_pai_flag,


--Match check for parameter: declined_pdd_flag.
CurrentCampaignObject.declined_pdd_flag as current_declined_pdd_flag,
PrevCampaignObject.declined_pdd_flag as prev_declined_pdd_flag,

case when IFNULL(CurrentCampaignObject.declined_pdd_flag,-1) <> IFNULL(PrevCampaignObject.declined_pdd_flag,-1)
        then 'Not Match'
        else '' end as check_declined_pdd_flag,


--Match check for parameter: declined_waiver_flag.
CurrentCampaignObject.declined_waiver_flag as current_declined_waiver_flag,
PrevCampaignObject.declined_waiver_flag as prev_declined_waiver_flag,

case when IFNULL(CurrentCampaignObject.declined_waiver_flag,-1) <> IFNULL(PrevCampaignObject.declined_waiver_flag,-1)
        then 'Not Match'
        else '' end as check_declined_waiver_flag,


--Match check for parameter: declined_fpda_flag.
CurrentCampaignObject.declined_fpda_flag as current_declined_fpda_flag,
PrevCampaignObject.declined_fpda_flag as prev_declined_fpda_flag,

case when IFNULL(CurrentCampaignObject.declined_fpda_flag,-1) <> IFNULL(PrevCampaignObject.declined_fpda_flag,-1)
        then 'Not Match'
        else '' end as check_declined_fpda_flag,


--Match check for parameter: declined_spda_flag.
CurrentCampaignObject.declined_spda_flag as current_declined_spda_flag,
PrevCampaignObject.declined_spda_flag as prev_declined_spda_flag,

case when IFNULL(CurrentCampaignObject.declined_spda_flag,-1) <> IFNULL(PrevCampaignObject.declined_spda_flag,-1)
        then 'Not Match'
        else '' end as check_declined_spda_flag,


--Match check for parameter: declined_spia_flag.
CurrentCampaignObject.declined_spia_flag as current_declined_spia_flag,
PrevCampaignObject.declined_spia_flag as prev_declined_spia_flag,

case when IFNULL(CurrentCampaignObject.declined_spia_flag,-1) <> IFNULL(PrevCampaignObject.declined_spia_flag,-1)
        then 'Not Match'
        else '' end as check_declined_spia_flag,


--Match check for parameter: declined_directmailterm_flag.
CurrentCampaignObject.declined_directmailterm_flag as current_declined_directmailterm_flag,
PrevCampaignObject.declined_directmailterm_flag as prev_declined_directmailterm_flag,

case when IFNULL(CurrentCampaignObject.declined_directmailterm_flag,-1) <> IFNULL(PrevCampaignObject.declined_directmailterm_flag,-1)
        then 'Not Match'
        else '' end as check_declined_directmailterm_flag,


--Match check for parameter: declined_expressterm_flag.
CurrentCampaignObject.declined_expressterm_flag as current_declined_expressterm_flag,
PrevCampaignObject.declined_expressterm_flag as prev_declined_expressterm_flag,

case when IFNULL(CurrentCampaignObject.declined_expressterm_flag,-1) <> IFNULL(PrevCampaignObject.declined_expressterm_flag,-1)
        then 'Not Match'
        else '' end as check_declined_expressterm_flag,


--Match check for parameter: declined_individualdirectterm_flag.
CurrentCampaignObject.declined_individualdirectterm_flag as current_declined_individualdirectterm_flag,
PrevCampaignObject.declined_individualdirectterm_flag as prev_declined_individualdirectterm_flag,

case when IFNULL(CurrentCampaignObject.declined_individualdirectterm_flag,-1) <> IFNULL(PrevCampaignObject.declined_individualdirectterm_flag,-1)
        then 'Not Match'
        else '' end as check_declined_individualdirectterm_flag,


--Match check for parameter: declined_term_flag.
CurrentCampaignObject.declined_term_flag as current_declined_term_flag,
PrevCampaignObject.declined_term_flag as prev_declined_term_flag,

case when IFNULL(CurrentCampaignObject.declined_term_flag,-1) <> IFNULL(PrevCampaignObject.declined_term_flag,-1)
        then 'Not Match'
        else '' end as check_declined_term_flag,


--Match check for parameter: declined_accumulatorul_flag.
CurrentCampaignObject.declined_accumulatorul_flag as current_declined_accumulatorul_flag,
PrevCampaignObject.declined_accumulatorul_flag as prev_declined_accumulatorul_flag,

case when IFNULL(CurrentCampaignObject.declined_accumulatorul_flag,-1) <> IFNULL(PrevCampaignObject.declined_accumulatorul_flag,-1)
        then 'Not Match'
        else '' end as check_declined_accumulatorul_flag,


--Match check for parameter: declined_lifetimeul_flag.
CurrentCampaignObject.declined_lifetimeul_flag as current_declined_lifetimeul_flag,
PrevCampaignObject.declined_lifetimeul_flag as prev_declined_lifetimeul_flag,

case when IFNULL(CurrentCampaignObject.declined_lifetimeul_flag,-1) <> IFNULL(PrevCampaignObject.declined_lifetimeul_flag,-1)
        then 'Not Match'
        else '' end as check_declined_lifetimeul_flag,


--Match check for parameter: declined_siwl_flag.
CurrentCampaignObject.declined_siwl_flag as current_declined_siwl_flag,
PrevCampaignObject.declined_siwl_flag as prev_declined_siwl_flag,

case when IFNULL(CurrentCampaignObject.declined_siwl_flag,-1) <> IFNULL(PrevCampaignObject.declined_siwl_flag,-1)
        then 'Not Match'
        else '' end as check_declined_siwl_flag,


--Match check for parameter: declined_giwl_flag.
CurrentCampaignObject.declined_giwl_flag as current_declined_giwl_flag,
PrevCampaignObject.declined_giwl_flag as prev_declined_giwl_flag,

case when IFNULL(CurrentCampaignObject.declined_giwl_flag,-1) <> IFNULL(PrevCampaignObject.declined_giwl_flag,-1)
        then 'Not Match'
        else '' end as check_declined_giwl_flag,


--Match check for parameter: declined_juvenile_flag.
CurrentCampaignObject.declined_juvenile_flag as current_declined_juvenile_flag,
PrevCampaignObject.declined_juvenile_flag as prev_declined_juvenile_flag,

case when IFNULL(CurrentCampaignObject.declined_juvenile_flag,-1) <> IFNULL(PrevCampaignObject.declined_juvenile_flag,-1)
        then 'Not Match'
        else '' end as check_declined_juvenile_flag,


--Match check for parameter: declined_wholelife_flag.
CurrentCampaignObject.declined_wholelife_flag as current_declined_wholelife_flag,
PrevCampaignObject.declined_wholelife_flag as prev_declined_wholelife_flag,

case when IFNULL(CurrentCampaignObject.declined_wholelife_flag,-1) <> IFNULL(PrevCampaignObject.declined_wholelife_flag,-1)
        then 'Not Match'
        else '' end as check_declined_wholelife_flag,


--Match check for parameter: club_ok_to_mail.
CurrentCampaignObject.club_ok_to_mail as current_club_ok_to_mail,
PrevCampaignObject.club_ok_to_mail as prev_club_ok_to_mail,

case when IFNULL(CurrentCampaignObject.club_ok_to_mail,-1) <> IFNULL(PrevCampaignObject.club_ok_to_mail,-1)
        then 'Not Match'
        else '' end as check_club_ok_to_mail,


--Match check for parameter: total_insured_inforce_policies.
CurrentCampaignObject.total_insured_inforce_policies as current_total_insured_inforce_policies,
PrevCampaignObject.total_insured_inforce_policies as prev_total_insured_inforce_policies,

case when IFNULL(CurrentCampaignObject.total_insured_inforce_policies,-1) <> IFNULL(PrevCampaignObject.total_insured_inforce_policies,-1)
        then 'Not Match'
        else '' end as check_total_insured_inforce_policies,


--Match check for parameter: insured_inforce_lifeproduct_flag.
CurrentCampaignObject.insured_inforce_lifeproduct_flag as current_insured_inforce_lifeproduct_flag,
PrevCampaignObject.insured_inforce_lifeproduct_flag as prev_insured_inforce_lifeproduct_flag,

case when IFNULL(CurrentCampaignObject.insured_inforce_lifeproduct_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_lifeproduct_flag,-1)
        then 'Not Match'
        else '' end as check_insured_inforce_lifeproduct_flag,


--Match check for parameter: insured_inforce_accidentproduct_flag.
CurrentCampaignObject.insured_inforce_accidentproduct_flag as current_insured_inforce_accidentproduct_flag,
PrevCampaignObject.insured_inforce_accidentproduct_flag as prev_insured_inforce_accidentproduct_flag,

case when IFNULL(CurrentCampaignObject.insured_inforce_accidentproduct_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_accidentproduct_flag,-1)
        then 'Not Match'
        else '' end as check_insured_inforce_accidentproduct_flag,


--Match check for parameter: insured_inforce_annuityproduct_flag.
CurrentCampaignObject.insured_inforce_annuityproduct_flag as current_insured_inforce_annuityproduct_flag,
PrevCampaignObject.insured_inforce_annuityproduct_flag as prev_insured_inforce_annuityproduct_flag,

case when IFNULL(CurrentCampaignObject.insured_inforce_annuityproduct_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_annuityproduct_flag,-1)
        then 'Not Match'
        else '' end as check_insured_inforce_annuityproduct_flag,


--Match check for parameter: insured_inforce_365_flag.
CurrentCampaignObject.insured_inforce_365_flag as current_insured_inforce_365_flag,
PrevCampaignObject.insured_inforce_365_flag as prev_insured_inforce_365_flag,

case when IFNULL(CurrentCampaignObject.insured_inforce_365_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_365_flag,-1)
        then 'Not Match'
        else '' end as check_insured_inforce_365_flag,


--Match check for parameter: insured_inforce_accident_flag.
CurrentCampaignObject.insured_inforce_accident_flag as current_insured_inforce_accident_flag,
PrevCampaignObject.insured_inforce_accident_flag as prev_insured_inforce_accident_flag,

case when IFNULL(CurrentCampaignObject.insured_inforce_accident_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_accident_flag,-1)
        then 'Not Match'
        else '' end as check_insured_inforce_accident_flag,


--Match check for parameter: insured_inforce_adb_flag.
CurrentCampaignObject.insured_inforce_adb_flag as current_insured_inforce_adb_flag,
PrevCampaignObject.insured_inforce_adb_flag as prev_insured_inforce_adb_flag,

case when IFNULL(CurrentCampaignObject.insured_inforce_adb_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_adb_flag,-1)
        then 'Not Match'
        else '' end as check_insured_inforce_adb_flag,


--Match check for parameter: insured_inforce_hip_flag.
CurrentCampaignObject.insured_inforce_hip_flag as current_insured_inforce_hip_flag,
PrevCampaignObject.insured_inforce_hip_flag as prev_insured_inforce_hip_flag,

case when IFNULL(CurrentCampaignObject.insured_inforce_hip_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_hip_flag,-1)
        then 'Not Match'
        else '' end as check_insured_inforce_hip_flag,


--Match check for parameter: insured_inforce_mlta_flag.
CurrentCampaignObject.insured_inforce_mlta_flag as current_insured_inforce_mlta_flag,
PrevCampaignObject.insured_inforce_mlta_flag as prev_insured_inforce_mlta_flag,

case when IFNULL(CurrentCampaignObject.insured_inforce_mlta_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_mlta_flag,-1)
        then 'Not Match'
        else '' end as check_insured_inforce_mlta_flag,


--Match check for parameter: insured_inforce_mpa_flag.
CurrentCampaignObject.insured_inforce_mpa_flag as current_insured_inforce_mpa_flag,
PrevCampaignObject.insured_inforce_mpa_flag as prev_insured_inforce_mpa_flag,

case when IFNULL(CurrentCampaignObject.insured_inforce_mpa_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_mpa_flag,-1)
        then 'Not Match'
        else '' end as check_insured_inforce_mpa_flag,


--Match check for parameter: insured_inforce_pai_flag.
CurrentCampaignObject.insured_inforce_pai_flag as current_insured_inforce_pai_flag,
PrevCampaignObject.insured_inforce_pai_flag as prev_insured_inforce_pai_flag,

case when IFNULL(CurrentCampaignObject.insured_inforce_pai_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_pai_flag,-1)
        then 'Not Match'
        else '' end as check_insured_inforce_pai_flag,


--Match check for parameter: insured_inforce_pdd_flag.
CurrentCampaignObject.insured_inforce_pdd_flag as current_insured_inforce_pdd_flag,
PrevCampaignObject.insured_inforce_pdd_flag as prev_insured_inforce_pdd_flag,

case when IFNULL(CurrentCampaignObject.insured_inforce_pdd_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_pdd_flag,-1)
        then 'Not Match'
        else '' end as check_insured_inforce_pdd_flag,


--Match check for parameter: insured_inforce_waiver_flag.
CurrentCampaignObject.insured_inforce_waiver_flag as current_insured_inforce_waiver_flag,
PrevCampaignObject.insured_inforce_waiver_flag as prev_insured_inforce_waiver_flag,

case when IFNULL(CurrentCampaignObject.insured_inforce_waiver_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_waiver_flag,-1)
        then 'Not Match'
        else '' end as check_insured_inforce_waiver_flag,


--Match check for parameter: insured_inforce_fpda_flag.
CurrentCampaignObject.insured_inforce_fpda_flag as current_insured_inforce_fpda_flag,
PrevCampaignObject.insured_inforce_fpda_flag as prev_insured_inforce_fpda_flag,

case when IFNULL(CurrentCampaignObject.insured_inforce_fpda_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_fpda_flag,-1)
        then 'Not Match'
        else '' end as check_insured_inforce_fpda_flag,


--Match check for parameter: insured_inforce_spda_flag.
CurrentCampaignObject.insured_inforce_spda_flag as current_insured_inforce_spda_flag,
PrevCampaignObject.insured_inforce_spda_flag as prev_insured_inforce_spda_flag,

case when IFNULL(CurrentCampaignObject.insured_inforce_spda_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_spda_flag,-1)
        then 'Not Match'
        else '' end as check_insured_inforce_spda_flag,


--Match check for parameter: insured_inforce_spia_flag.
CurrentCampaignObject.insured_inforce_spia_flag as current_insured_inforce_spia_flag,
PrevCampaignObject.insured_inforce_spia_flag as prev_insured_inforce_spia_flag,

case when IFNULL(CurrentCampaignObject.insured_inforce_spia_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_spia_flag,-1)
        then 'Not Match'
        else '' end as check_insured_inforce_spia_flag,


--Match check for parameter: insured_inforce_directmailterm_flag.
CurrentCampaignObject.insured_inforce_directmailterm_flag as current_insured_inforce_directmailterm_flag,
PrevCampaignObject.insured_inforce_directmailterm_flag as prev_insured_inforce_directmailterm_flag,

case when IFNULL(CurrentCampaignObject.insured_inforce_directmailterm_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_directmailterm_flag,-1)
        then 'Not Match'
        else '' end as check_insured_inforce_directmailterm_flag,


--Match check for parameter: insured_inforce_expressterm_flag.
CurrentCampaignObject.insured_inforce_expressterm_flag as current_insured_inforce_expressterm_flag,
PrevCampaignObject.insured_inforce_expressterm_flag as prev_insured_inforce_expressterm_flag,

case when IFNULL(CurrentCampaignObject.insured_inforce_expressterm_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_expressterm_flag,-1)
        then 'Not Match'
        else '' end as check_insured_inforce_expressterm_flag,


--Match check for parameter: insured_inforce_individualdirectterm_flag.
CurrentCampaignObject.insured_inforce_individualdirectterm_flag as current_insured_inforce_individualdirectterm_flag,
PrevCampaignObject.insured_inforce_individualdirectterm_flag as prev_insured_inforce_individualdirectterm_flag,

case when IFNULL(CurrentCampaignObject.insured_inforce_individualdirectterm_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_individualdirectterm_flag,-1)
        then 'Not Match'
        else '' end as check_insured_inforce_individualdirectterm_flag,


--Match check for parameter: insured_inforce_term_flag.
CurrentCampaignObject.insured_inforce_term_flag as current_insured_inforce_term_flag,
PrevCampaignObject.insured_inforce_term_flag as prev_insured_inforce_term_flag,

case when IFNULL(CurrentCampaignObject.insured_inforce_term_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_term_flag,-1)
        then 'Not Match'
        else '' end as check_insured_inforce_term_flag,


--Match check for parameter: insured_inforce_accumulatorul_flag.
CurrentCampaignObject.insured_inforce_accumulatorul_flag as current_insured_inforce_accumulatorul_flag,
PrevCampaignObject.insured_inforce_accumulatorul_flag as prev_insured_inforce_accumulatorul_flag,

case when IFNULL(CurrentCampaignObject.insured_inforce_accumulatorul_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_accumulatorul_flag,-1)
        then 'Not Match'
        else '' end as check_insured_inforce_accumulatorul_flag,


--Match check for parameter: insured_inforce_lifetimeul_flag.
CurrentCampaignObject.insured_inforce_lifetimeul_flag as current_insured_inforce_lifetimeul_flag,
PrevCampaignObject.insured_inforce_lifetimeul_flag as prev_insured_inforce_lifetimeul_flag,

case when IFNULL(CurrentCampaignObject.insured_inforce_lifetimeul_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_lifetimeul_flag,-1)
        then 'Not Match'
        else '' end as check_insured_inforce_lifetimeul_flag,


--Match check for parameter: insured_inforce_siwl_flag.
CurrentCampaignObject.insured_inforce_siwl_flag as current_insured_inforce_siwl_flag,
PrevCampaignObject.insured_inforce_siwl_flag as prev_insured_inforce_siwl_flag,

case when IFNULL(CurrentCampaignObject.insured_inforce_siwl_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_siwl_flag,-1)
        then 'Not Match'
        else '' end as check_insured_inforce_siwl_flag,


--Match check for parameter: insured_inforce_giwl_flag.
CurrentCampaignObject.insured_inforce_giwl_flag as current_insured_inforce_giwl_flag,
PrevCampaignObject.insured_inforce_giwl_flag as prev_insured_inforce_giwl_flag,

case when IFNULL(CurrentCampaignObject.insured_inforce_giwl_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_giwl_flag,-1)
        then 'Not Match'
        else '' end as check_insured_inforce_giwl_flag,


--Match check for parameter: insured_inforce_juvenile_flag.
CurrentCampaignObject.insured_inforce_juvenile_flag as current_insured_inforce_juvenile_flag,
PrevCampaignObject.insured_inforce_juvenile_flag as prev_insured_inforce_juvenile_flag,

case when IFNULL(CurrentCampaignObject.insured_inforce_juvenile_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_juvenile_flag,-1)
        then 'Not Match'
        else '' end as check_insured_inforce_juvenile_flag,


--Match check for parameter: insured_inforce_wholelife_flag.
CurrentCampaignObject.insured_inforce_wholelife_flag as current_insured_inforce_wholelife_flag,
PrevCampaignObject.insured_inforce_wholelife_flag as prev_insured_inforce_wholelife_flag,

case when IFNULL(CurrentCampaignObject.insured_inforce_wholelife_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_wholelife_flag,-1)
        then 'Not Match'
        else '' end as check_insured_inforce_wholelife_flag,


--Match check for parameter: insured_activeapp_lifeproduct_flag.
CurrentCampaignObject.insured_activeapp_lifeproduct_flag as current_insured_activeapp_lifeproduct_flag,
PrevCampaignObject.insured_activeapp_lifeproduct_flag as prev_insured_activeapp_lifeproduct_flag,

case when IFNULL(CurrentCampaignObject.insured_activeapp_lifeproduct_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_lifeproduct_flag,-1)
        then 'Not Match'
        else '' end as check_insured_activeapp_lifeproduct_flag,


--Match check for parameter: insured_activeapp_accidentproduct_flag.
CurrentCampaignObject.insured_activeapp_accidentproduct_flag as current_insured_activeapp_accidentproduct_flag,
PrevCampaignObject.insured_activeapp_accidentproduct_flag as prev_insured_activeapp_accidentproduct_flag,

case when IFNULL(CurrentCampaignObject.insured_activeapp_accidentproduct_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_accidentproduct_flag,-1)
        then 'Not Match'
        else '' end as check_insured_activeapp_accidentproduct_flag,


--Match check for parameter: insured_activeapp_annuityproduct_flag.
CurrentCampaignObject.insured_activeapp_annuityproduct_flag as current_insured_activeapp_annuityproduct_flag,
PrevCampaignObject.insured_activeapp_annuityproduct_flag as prev_insured_activeapp_annuityproduct_flag,

case when IFNULL(CurrentCampaignObject.insured_activeapp_annuityproduct_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_annuityproduct_flag,-1)
        then 'Not Match'
        else '' end as check_insured_activeapp_annuityproduct_flag,


--Match check for parameter: insured_activeapp_365_flag.
CurrentCampaignObject.insured_activeapp_365_flag as current_insured_activeapp_365_flag,
PrevCampaignObject.insured_activeapp_365_flag as prev_insured_activeapp_365_flag,

case when IFNULL(CurrentCampaignObject.insured_activeapp_365_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_365_flag,-1)
        then 'Not Match'
        else '' end as check_insured_activeapp_365_flag,


--Match check for parameter: insured_activeapp_accident_flag.
CurrentCampaignObject.insured_activeapp_accident_flag as current_insured_activeapp_accident_flag,
PrevCampaignObject.insured_activeapp_accident_flag as prev_insured_activeapp_accident_flag,

case when IFNULL(CurrentCampaignObject.insured_activeapp_accident_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_accident_flag,-1)
        then 'Not Match'
        else '' end as check_insured_activeapp_accident_flag,


--Match check for parameter: insured_activeapp_adb_flag.
CurrentCampaignObject.insured_activeapp_adb_flag as current_insured_activeapp_adb_flag,
PrevCampaignObject.insured_activeapp_adb_flag as prev_insured_activeapp_adb_flag,

case when IFNULL(CurrentCampaignObject.insured_activeapp_adb_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_adb_flag,-1)
        then 'Not Match'
        else '' end as check_insured_activeapp_adb_flag,


--Match check for parameter: insured_activeapp_hip_flag.
CurrentCampaignObject.insured_activeapp_hip_flag as current_insured_activeapp_hip_flag,
PrevCampaignObject.insured_activeapp_hip_flag as prev_insured_activeapp_hip_flag,

case when IFNULL(CurrentCampaignObject.insured_activeapp_hip_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_hip_flag,-1)
        then 'Not Match'
        else '' end as check_insured_activeapp_hip_flag,


--Match check for parameter: insured_activeapp_mlta_flag.
CurrentCampaignObject.insured_activeapp_mlta_flag as current_insured_activeapp_mlta_flag,
PrevCampaignObject.insured_activeapp_mlta_flag as prev_insured_activeapp_mlta_flag,

case when IFNULL(CurrentCampaignObject.insured_activeapp_mlta_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_mlta_flag,-1)
        then 'Not Match'
        else '' end as check_insured_activeapp_mlta_flag,


--Match check for parameter: insured_activeapp_mpa_flag.
CurrentCampaignObject.insured_activeapp_mpa_flag as current_insured_activeapp_mpa_flag,
PrevCampaignObject.insured_activeapp_mpa_flag as prev_insured_activeapp_mpa_flag,

case when IFNULL(CurrentCampaignObject.insured_activeapp_mpa_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_mpa_flag,-1)
        then 'Not Match'
        else '' end as check_insured_activeapp_mpa_flag,


--Match check for parameter: insured_activeapp_pai_flag.
CurrentCampaignObject.insured_activeapp_pai_flag as current_insured_activeapp_pai_flag,
PrevCampaignObject.insured_activeapp_pai_flag as prev_insured_activeapp_pai_flag,

case when IFNULL(CurrentCampaignObject.insured_activeapp_pai_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_pai_flag,-1)
        then 'Not Match'
        else '' end as check_insured_activeapp_pai_flag,


--Match check for parameter: insured_activeapp_pdd_flag.
CurrentCampaignObject.insured_activeapp_pdd_flag as current_insured_activeapp_pdd_flag,
PrevCampaignObject.insured_activeapp_pdd_flag as prev_insured_activeapp_pdd_flag,

case when IFNULL(CurrentCampaignObject.insured_activeapp_pdd_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_pdd_flag,-1)
        then 'Not Match'
        else '' end as check_insured_activeapp_pdd_flag,


--Match check for parameter: insured_activeapp_waiver_flag.
CurrentCampaignObject.insured_activeapp_waiver_flag as current_insured_activeapp_waiver_flag,
PrevCampaignObject.insured_activeapp_waiver_flag as prev_insured_activeapp_waiver_flag,

case when IFNULL(CurrentCampaignObject.insured_activeapp_waiver_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_waiver_flag,-1)
        then 'Not Match'
        else '' end as check_insured_activeapp_waiver_flag,


--Match check for parameter: insured_activeapp_fpda_flag.
CurrentCampaignObject.insured_activeapp_fpda_flag as current_insured_activeapp_fpda_flag,
PrevCampaignObject.insured_activeapp_fpda_flag as prev_insured_activeapp_fpda_flag,

case when IFNULL(CurrentCampaignObject.insured_activeapp_fpda_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_fpda_flag,-1)
        then 'Not Match'
        else '' end as check_insured_activeapp_fpda_flag,


--Match check for parameter: insured_activeapp_spda_flag.
CurrentCampaignObject.insured_activeapp_spda_flag as current_insured_activeapp_spda_flag,
PrevCampaignObject.insured_activeapp_spda_flag as prev_insured_activeapp_spda_flag,

case when IFNULL(CurrentCampaignObject.insured_activeapp_spda_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_spda_flag,-1)
        then 'Not Match'
        else '' end as check_insured_activeapp_spda_flag,


--Match check for parameter: insured_activeapp_spia_flag.
CurrentCampaignObject.insured_activeapp_spia_flag as current_insured_activeapp_spia_flag,
PrevCampaignObject.insured_activeapp_spia_flag as prev_insured_activeapp_spia_flag,

case when IFNULL(CurrentCampaignObject.insured_activeapp_spia_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_spia_flag,-1)
        then 'Not Match'
        else '' end as check_insured_activeapp_spia_flag,


--Match check for parameter: insured_activeapp_directmailterm_flag.
CurrentCampaignObject.insured_activeapp_directmailterm_flag as current_insured_activeapp_directmailterm_flag,
PrevCampaignObject.insured_activeapp_directmailterm_flag as prev_insured_activeapp_directmailterm_flag,

case when IFNULL(CurrentCampaignObject.insured_activeapp_directmailterm_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_directmailterm_flag,-1)
        then 'Not Match'
        else '' end as check_insured_activeapp_directmailterm_flag,


--Match check for parameter: insured_activeapp_expressterm_flag.
CurrentCampaignObject.insured_activeapp_expressterm_flag as current_insured_activeapp_expressterm_flag,
PrevCampaignObject.insured_activeapp_expressterm_flag as prev_insured_activeapp_expressterm_flag,

case when IFNULL(CurrentCampaignObject.insured_activeapp_expressterm_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_expressterm_flag,-1)
        then 'Not Match'
        else '' end as check_insured_activeapp_expressterm_flag,


--Match check for parameter: insured_activeapp_individualdirectterm_flag.
CurrentCampaignObject.insured_activeapp_individualdirectterm_flag as current_insured_activeapp_individualdirectterm_flag,
PrevCampaignObject.insured_activeapp_individualdirectterm_flag as prev_insured_activeapp_individualdirectterm_flag,

case when IFNULL(CurrentCampaignObject.insured_activeapp_individualdirectterm_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_individualdirectterm_flag,-1)
        then 'Not Match'
        else '' end as check_insured_activeapp_individualdirectterm_flag,


--Match check for parameter: insured_activeapp_term_flag.
CurrentCampaignObject.insured_activeapp_term_flag as current_insured_activeapp_term_flag,
PrevCampaignObject.insured_activeapp_term_flag as prev_insured_activeapp_term_flag,

case when IFNULL(CurrentCampaignObject.insured_activeapp_term_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_term_flag,-1)
        then 'Not Match'
        else '' end as check_insured_activeapp_term_flag,


--Match check for parameter: insured_activeapp_accumulatorul_flag.
CurrentCampaignObject.insured_activeapp_accumulatorul_flag as current_insured_activeapp_accumulatorul_flag,
PrevCampaignObject.insured_activeapp_accumulatorul_flag as prev_insured_activeapp_accumulatorul_flag,

case when IFNULL(CurrentCampaignObject.insured_activeapp_accumulatorul_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_accumulatorul_flag,-1)
        then 'Not Match'
        else '' end as check_insured_activeapp_accumulatorul_flag,


--Match check for parameter: insured_activeapp_lifetimeul_flag.
CurrentCampaignObject.insured_activeapp_lifetimeul_flag as current_insured_activeapp_lifetimeul_flag,
PrevCampaignObject.insured_activeapp_lifetimeul_flag as prev_insured_activeapp_lifetimeul_flag,

case when IFNULL(CurrentCampaignObject.insured_activeapp_lifetimeul_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_lifetimeul_flag,-1)
        then 'Not Match'
        else '' end as check_insured_activeapp_lifetimeul_flag,


--Match check for parameter: insured_activeapp_siwl_flag.
CurrentCampaignObject.insured_activeapp_siwl_flag as current_insured_activeapp_siwl_flag,
PrevCampaignObject.insured_activeapp_siwl_flag as prev_insured_activeapp_siwl_flag,

case when IFNULL(CurrentCampaignObject.insured_activeapp_siwl_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_siwl_flag,-1)
        then 'Not Match'
        else '' end as check_insured_activeapp_siwl_flag,


--Match check for parameter: insured_activeapp_giwl_flag.
CurrentCampaignObject.insured_activeapp_giwl_flag as current_insured_activeapp_giwl_flag,
PrevCampaignObject.insured_activeapp_giwl_flag as prev_insured_activeapp_giwl_flag,

case when IFNULL(CurrentCampaignObject.insured_activeapp_giwl_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_giwl_flag,-1)
        then 'Not Match'
        else '' end as check_insured_activeapp_giwl_flag,


--Match check for parameter: insured_activeapp_juvenile_flag.
CurrentCampaignObject.insured_activeapp_juvenile_flag as current_insured_activeapp_juvenile_flag,
PrevCampaignObject.insured_activeapp_juvenile_flag as prev_insured_activeapp_juvenile_flag,

case when IFNULL(CurrentCampaignObject.insured_activeapp_juvenile_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_juvenile_flag,-1)
        then 'Not Match'
        else '' end as check_insured_activeapp_juvenile_flag,


--Match check for parameter: insured_activeapp_wholelife_flag.
CurrentCampaignObject.insured_activeapp_wholelife_flag as current_insured_activeapp_wholelife_flag,
PrevCampaignObject.insured_activeapp_wholelife_flag as prev_insured_activeapp_wholelife_flag,

case when IFNULL(CurrentCampaignObject.insured_activeapp_wholelife_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_wholelife_flag,-1)
        then 'Not Match'
        else '' end as check_insured_activeapp_wholelife_flag,


--Match check for parameter: insured_coldfeet_365_flag.
CurrentCampaignObject.insured_coldfeet_365_flag as current_insured_coldfeet_365_flag,
PrevCampaignObject.insured_coldfeet_365_flag as prev_insured_coldfeet_365_flag,

case when IFNULL(CurrentCampaignObject.insured_coldfeet_365_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_365_flag,-1)
        then 'Not Match'
        else '' end as check_insured_coldfeet_365_flag,


--Match check for parameter: insured_coldfeet_accident_flag.
CurrentCampaignObject.insured_coldfeet_accident_flag as current_insured_coldfeet_accident_flag,
PrevCampaignObject.insured_coldfeet_accident_flag as prev_insured_coldfeet_accident_flag,

case when IFNULL(CurrentCampaignObject.insured_coldfeet_accident_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_accident_flag,-1)
        then 'Not Match'
        else '' end as check_insured_coldfeet_accident_flag,


--Match check for parameter: insured_coldfeet_adb_flag.
CurrentCampaignObject.insured_coldfeet_adb_flag as current_insured_coldfeet_adb_flag,
PrevCampaignObject.insured_coldfeet_adb_flag as prev_insured_coldfeet_adb_flag,

case when IFNULL(CurrentCampaignObject.insured_coldfeet_adb_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_adb_flag,-1)
        then 'Not Match'
        else '' end as check_insured_coldfeet_adb_flag,


--Match check for parameter: insured_coldfeet_hip_flag.
CurrentCampaignObject.insured_coldfeet_hip_flag as current_insured_coldfeet_hip_flag,
PrevCampaignObject.insured_coldfeet_hip_flag as prev_insured_coldfeet_hip_flag,

case when IFNULL(CurrentCampaignObject.insured_coldfeet_hip_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_hip_flag,-1)
        then 'Not Match'
        else '' end as check_insured_coldfeet_hip_flag,


--Match check for parameter: insured_coldfeet_mlta_flag.
CurrentCampaignObject.insured_coldfeet_mlta_flag as current_insured_coldfeet_mlta_flag,
PrevCampaignObject.insured_coldfeet_mlta_flag as prev_insured_coldfeet_mlta_flag,

case when IFNULL(CurrentCampaignObject.insured_coldfeet_mlta_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_mlta_flag,-1)
        then 'Not Match'
        else '' end as check_insured_coldfeet_mlta_flag,


--Match check for parameter: insured_coldfeet_mpa_flag.
CurrentCampaignObject.insured_coldfeet_mpa_flag as current_insured_coldfeet_mpa_flag,
PrevCampaignObject.insured_coldfeet_mpa_flag as prev_insured_coldfeet_mpa_flag,

case when IFNULL(CurrentCampaignObject.insured_coldfeet_mpa_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_mpa_flag,-1)
        then 'Not Match'
        else '' end as check_insured_coldfeet_mpa_flag,


--Match check for parameter: insured_coldfeet_pai_flag.
CurrentCampaignObject.insured_coldfeet_pai_flag as current_insured_coldfeet_pai_flag,
PrevCampaignObject.insured_coldfeet_pai_flag as prev_insured_coldfeet_pai_flag,

case when IFNULL(CurrentCampaignObject.insured_coldfeet_pai_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_pai_flag,-1)
        then 'Not Match'
        else '' end as check_insured_coldfeet_pai_flag,


--Match check for parameter: insured_coldfeet_pdd_flag.
CurrentCampaignObject.insured_coldfeet_pdd_flag as current_insured_coldfeet_pdd_flag,
PrevCampaignObject.insured_coldfeet_pdd_flag as prev_insured_coldfeet_pdd_flag,

case when IFNULL(CurrentCampaignObject.insured_coldfeet_pdd_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_pdd_flag,-1)
        then 'Not Match'
        else '' end as check_insured_coldfeet_pdd_flag,


--Match check for parameter: insured_coldfeet_waiver_flag.
CurrentCampaignObject.insured_coldfeet_waiver_flag as current_insured_coldfeet_waiver_flag,
PrevCampaignObject.insured_coldfeet_waiver_flag as prev_insured_coldfeet_waiver_flag,

case when IFNULL(CurrentCampaignObject.insured_coldfeet_waiver_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_waiver_flag,-1)
        then 'Not Match'
        else '' end as check_insured_coldfeet_waiver_flag,


--Match check for parameter: insured_coldfeet_fpda_flag.
CurrentCampaignObject.insured_coldfeet_fpda_flag as current_insured_coldfeet_fpda_flag,
PrevCampaignObject.insured_coldfeet_fpda_flag as prev_insured_coldfeet_fpda_flag,

case when IFNULL(CurrentCampaignObject.insured_coldfeet_fpda_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_fpda_flag,-1)
        then 'Not Match'
        else '' end as check_insured_coldfeet_fpda_flag,


--Match check for parameter: insured_coldfeet_spda_flag.
CurrentCampaignObject.insured_coldfeet_spda_flag as current_insured_coldfeet_spda_flag,
PrevCampaignObject.insured_coldfeet_spda_flag as prev_insured_coldfeet_spda_flag,

case when IFNULL(CurrentCampaignObject.insured_coldfeet_spda_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_spda_flag,-1)
        then 'Not Match'
        else '' end as check_insured_coldfeet_spda_flag,


--Match check for parameter: insured_coldfeet_spia_flag.
CurrentCampaignObject.insured_coldfeet_spia_flag as current_insured_coldfeet_spia_flag,
PrevCampaignObject.insured_coldfeet_spia_flag as prev_insured_coldfeet_spia_flag,

case when IFNULL(CurrentCampaignObject.insured_coldfeet_spia_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_spia_flag,-1)
        then 'Not Match'
        else '' end as check_insured_coldfeet_spia_flag,


--Match check for parameter: insured_coldfeet_directmailterm_flag.
CurrentCampaignObject.insured_coldfeet_directmailterm_flag as current_insured_coldfeet_directmailterm_flag,
PrevCampaignObject.insured_coldfeet_directmailterm_flag as prev_insured_coldfeet_directmailterm_flag,

case when IFNULL(CurrentCampaignObject.insured_coldfeet_directmailterm_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_directmailterm_flag,-1)
        then 'Not Match'
        else '' end as check_insured_coldfeet_directmailterm_flag,


--Match check for parameter: insured_coldfeet_expressterm_flag.
CurrentCampaignObject.insured_coldfeet_expressterm_flag as current_insured_coldfeet_expressterm_flag,
PrevCampaignObject.insured_coldfeet_expressterm_flag as prev_insured_coldfeet_expressterm_flag,

case when IFNULL(CurrentCampaignObject.insured_coldfeet_expressterm_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_expressterm_flag,-1)
        then 'Not Match'
        else '' end as check_insured_coldfeet_expressterm_flag,


--Match check for parameter: insured_coldfeet_individualdirectterm_flag.
CurrentCampaignObject.insured_coldfeet_individualdirectterm_flag as current_insured_coldfeet_individualdirectterm_flag,
PrevCampaignObject.insured_coldfeet_individualdirectterm_flag as prev_insured_coldfeet_individualdirectterm_flag,

case when IFNULL(CurrentCampaignObject.insured_coldfeet_individualdirectterm_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_individualdirectterm_flag,-1)
        then 'Not Match'
        else '' end as check_insured_coldfeet_individualdirectterm_flag,


--Match check for parameter: insured_coldfeet_term_flag.
CurrentCampaignObject.insured_coldfeet_term_flag as current_insured_coldfeet_term_flag,
PrevCampaignObject.insured_coldfeet_term_flag as prev_insured_coldfeet_term_flag,

case when IFNULL(CurrentCampaignObject.insured_coldfeet_term_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_term_flag,-1)
        then 'Not Match'
        else '' end as check_insured_coldfeet_term_flag,


--Match check for parameter: insured_coldfeet_accumulatorul_flag.
CurrentCampaignObject.insured_coldfeet_accumulatorul_flag as current_insured_coldfeet_accumulatorul_flag,
PrevCampaignObject.insured_coldfeet_accumulatorul_flag as prev_insured_coldfeet_accumulatorul_flag,

case when IFNULL(CurrentCampaignObject.insured_coldfeet_accumulatorul_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_accumulatorul_flag,-1)
        then 'Not Match'
        else '' end as check_insured_coldfeet_accumulatorul_flag,


--Match check for parameter: insured_coldfeet_lifetimeul_flag.
CurrentCampaignObject.insured_coldfeet_lifetimeul_flag as current_insured_coldfeet_lifetimeul_flag,
PrevCampaignObject.insured_coldfeet_lifetimeul_flag as prev_insured_coldfeet_lifetimeul_flag,

case when IFNULL(CurrentCampaignObject.insured_coldfeet_lifetimeul_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_lifetimeul_flag,-1)
        then 'Not Match'
        else '' end as check_insured_coldfeet_lifetimeul_flag,


--Match check for parameter: insured_coldfeet_siwl_flag.
CurrentCampaignObject.insured_coldfeet_siwl_flag as current_insured_coldfeet_siwl_flag,
PrevCampaignObject.insured_coldfeet_siwl_flag as prev_insured_coldfeet_siwl_flag,

case when IFNULL(CurrentCampaignObject.insured_coldfeet_siwl_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_siwl_flag,-1)
        then 'Not Match'
        else '' end as check_insured_coldfeet_siwl_flag,


--Match check for parameter: insured_coldfeet_giwl_flag.
CurrentCampaignObject.insured_coldfeet_giwl_flag as current_insured_coldfeet_giwl_flag,
PrevCampaignObject.insured_coldfeet_giwl_flag as prev_insured_coldfeet_giwl_flag,

case when IFNULL(CurrentCampaignObject.insured_coldfeet_giwl_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_giwl_flag,-1)
        then 'Not Match'
        else '' end as check_insured_coldfeet_giwl_flag,


--Match check for parameter: insured_coldfeet_juvenile_flag.
CurrentCampaignObject.insured_coldfeet_juvenile_flag as current_insured_coldfeet_juvenile_flag,
PrevCampaignObject.insured_coldfeet_juvenile_flag as prev_insured_coldfeet_juvenile_flag,

case when IFNULL(CurrentCampaignObject.insured_coldfeet_juvenile_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_juvenile_flag,-1)
        then 'Not Match'
        else '' end as check_insured_coldfeet_juvenile_flag,


--Match check for parameter: insured_coldfeet_wholelife_flag.
CurrentCampaignObject.insured_coldfeet_wholelife_flag as current_insured_coldfeet_wholelife_flag,
PrevCampaignObject.insured_coldfeet_wholelife_flag as prev_insured_coldfeet_wholelife_flag,

case when IFNULL(CurrentCampaignObject.insured_coldfeet_wholelife_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_wholelife_flag,-1)
        then 'Not Match'
        else '' end as check_insured_coldfeet_wholelife_flag,


--Match check for parameter: insured_churn_365_flag.
CurrentCampaignObject.insured_churn_365_flag as current_insured_churn_365_flag,
PrevCampaignObject.insured_churn_365_flag as prev_insured_churn_365_flag,

case when IFNULL(CurrentCampaignObject.insured_churn_365_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_365_flag,-1)
        then 'Not Match'
        else '' end as check_insured_churn_365_flag,


--Match check for parameter: insured_churn_accident_flag.
CurrentCampaignObject.insured_churn_accident_flag as current_insured_churn_accident_flag,
PrevCampaignObject.insured_churn_accident_flag as prev_insured_churn_accident_flag,

case when IFNULL(CurrentCampaignObject.insured_churn_accident_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_accident_flag,-1)
        then 'Not Match'
        else '' end as check_insured_churn_accident_flag,


--Match check for parameter: insured_churn_adb_flag.
CurrentCampaignObject.insured_churn_adb_flag as current_insured_churn_adb_flag,
PrevCampaignObject.insured_churn_adb_flag as prev_insured_churn_adb_flag,

case when IFNULL(CurrentCampaignObject.insured_churn_adb_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_adb_flag,-1)
        then 'Not Match'
        else '' end as check_insured_churn_adb_flag,


--Match check for parameter: insured_churn_hip_flag.
CurrentCampaignObject.insured_churn_hip_flag as current_insured_churn_hip_flag,
PrevCampaignObject.insured_churn_hip_flag as prev_insured_churn_hip_flag,

case when IFNULL(CurrentCampaignObject.insured_churn_hip_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_hip_flag,-1)
        then 'Not Match'
        else '' end as check_insured_churn_hip_flag,


--Match check for parameter: insured_churn_mlta_flag.
CurrentCampaignObject.insured_churn_mlta_flag as current_insured_churn_mlta_flag,
PrevCampaignObject.insured_churn_mlta_flag as prev_insured_churn_mlta_flag,

case when IFNULL(CurrentCampaignObject.insured_churn_mlta_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_mlta_flag,-1)
        then 'Not Match'
        else '' end as check_insured_churn_mlta_flag,


--Match check for parameter: insured_churn_mpa_flag.
CurrentCampaignObject.insured_churn_mpa_flag as current_insured_churn_mpa_flag,
PrevCampaignObject.insured_churn_mpa_flag as prev_insured_churn_mpa_flag,

case when IFNULL(CurrentCampaignObject.insured_churn_mpa_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_mpa_flag,-1)
        then 'Not Match'
        else '' end as check_insured_churn_mpa_flag,


--Match check for parameter: insured_churn_pai_flag.
CurrentCampaignObject.insured_churn_pai_flag as current_insured_churn_pai_flag,
PrevCampaignObject.insured_churn_pai_flag as prev_insured_churn_pai_flag,

case when IFNULL(CurrentCampaignObject.insured_churn_pai_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_pai_flag,-1)
        then 'Not Match'
        else '' end as check_insured_churn_pai_flag,


--Match check for parameter: insured_churn_pdd_flag.
CurrentCampaignObject.insured_churn_pdd_flag as current_insured_churn_pdd_flag,
PrevCampaignObject.insured_churn_pdd_flag as prev_insured_churn_pdd_flag,

case when IFNULL(CurrentCampaignObject.insured_churn_pdd_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_pdd_flag,-1)
        then 'Not Match'
        else '' end as check_insured_churn_pdd_flag,


--Match check for parameter: insured_churn_waiver_flag.
CurrentCampaignObject.insured_churn_waiver_flag as current_insured_churn_waiver_flag,
PrevCampaignObject.insured_churn_waiver_flag as prev_insured_churn_waiver_flag,

case when IFNULL(CurrentCampaignObject.insured_churn_waiver_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_waiver_flag,-1)
        then 'Not Match'
        else '' end as check_insured_churn_waiver_flag,


--Match check for parameter: insured_churn_fpda_flag.
CurrentCampaignObject.insured_churn_fpda_flag as current_insured_churn_fpda_flag,
PrevCampaignObject.insured_churn_fpda_flag as prev_insured_churn_fpda_flag,

case when IFNULL(CurrentCampaignObject.insured_churn_fpda_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_fpda_flag,-1)
        then 'Not Match'
        else '' end as check_insured_churn_fpda_flag,


--Match check for parameter: insured_churn_spda_flag.
CurrentCampaignObject.insured_churn_spda_flag as current_insured_churn_spda_flag,
PrevCampaignObject.insured_churn_spda_flag as prev_insured_churn_spda_flag,

case when IFNULL(CurrentCampaignObject.insured_churn_spda_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_spda_flag,-1)
        then 'Not Match'
        else '' end as check_insured_churn_spda_flag,


--Match check for parameter: insured_churn_spia_flag.
CurrentCampaignObject.insured_churn_spia_flag as current_insured_churn_spia_flag,
PrevCampaignObject.insured_churn_spia_flag as prev_insured_churn_spia_flag,

case when IFNULL(CurrentCampaignObject.insured_churn_spia_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_spia_flag,-1)
        then 'Not Match'
        else '' end as check_insured_churn_spia_flag,


--Match check for parameter: insured_churn_directmailterm_flag.
CurrentCampaignObject.insured_churn_directmailterm_flag as current_insured_churn_directmailterm_flag,
PrevCampaignObject.insured_churn_directmailterm_flag as prev_insured_churn_directmailterm_flag,

case when IFNULL(CurrentCampaignObject.insured_churn_directmailterm_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_directmailterm_flag,-1)
        then 'Not Match'
        else '' end as check_insured_churn_directmailterm_flag,


--Match check for parameter: insured_churn_expressterm_flag.
CurrentCampaignObject.insured_churn_expressterm_flag as current_insured_churn_expressterm_flag,
PrevCampaignObject.insured_churn_expressterm_flag as prev_insured_churn_expressterm_flag,

case when IFNULL(CurrentCampaignObject.insured_churn_expressterm_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_expressterm_flag,-1)
        then 'Not Match'
        else '' end as check_insured_churn_expressterm_flag,


--Match check for parameter: insured_churn_individualdirectterm_flag.
CurrentCampaignObject.insured_churn_individualdirectterm_flag as current_insured_churn_individualdirectterm_flag,
PrevCampaignObject.insured_churn_individualdirectterm_flag as prev_insured_churn_individualdirectterm_flag,

case when IFNULL(CurrentCampaignObject.insured_churn_individualdirectterm_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_individualdirectterm_flag,-1)
        then 'Not Match'
        else '' end as check_insured_churn_individualdirectterm_flag,


--Match check for parameter: insured_churn_term_flag.
CurrentCampaignObject.insured_churn_term_flag as current_insured_churn_term_flag,
PrevCampaignObject.insured_churn_term_flag as prev_insured_churn_term_flag,

case when IFNULL(CurrentCampaignObject.insured_churn_term_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_term_flag,-1)
        then 'Not Match'
        else '' end as check_insured_churn_term_flag,


--Match check for parameter: insured_churn_accumulatorul_flag.
CurrentCampaignObject.insured_churn_accumulatorul_flag as current_insured_churn_accumulatorul_flag,
PrevCampaignObject.insured_churn_accumulatorul_flag as prev_insured_churn_accumulatorul_flag,

case when IFNULL(CurrentCampaignObject.insured_churn_accumulatorul_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_accumulatorul_flag,-1)
        then 'Not Match'
        else '' end as check_insured_churn_accumulatorul_flag,


--Match check for parameter: insured_churn_lifetimeul_flag.
CurrentCampaignObject.insured_churn_lifetimeul_flag as current_insured_churn_lifetimeul_flag,
PrevCampaignObject.insured_churn_lifetimeul_flag as prev_insured_churn_lifetimeul_flag,

case when IFNULL(CurrentCampaignObject.insured_churn_lifetimeul_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_lifetimeul_flag,-1)
        then 'Not Match'
        else '' end as check_insured_churn_lifetimeul_flag,


--Match check for parameter: insured_churn_siwl_flag.
CurrentCampaignObject.insured_churn_siwl_flag as current_insured_churn_siwl_flag,
PrevCampaignObject.insured_churn_siwl_flag as prev_insured_churn_siwl_flag,

case when IFNULL(CurrentCampaignObject.insured_churn_siwl_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_siwl_flag,-1)
        then 'Not Match'
        else '' end as check_insured_churn_siwl_flag,


--Match check for parameter: insured_churn_giwl_flag.
CurrentCampaignObject.insured_churn_giwl_flag as current_insured_churn_giwl_flag,
PrevCampaignObject.insured_churn_giwl_flag as prev_insured_churn_giwl_flag,

case when IFNULL(CurrentCampaignObject.insured_churn_giwl_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_giwl_flag,-1)
        then 'Not Match'
        else '' end as check_insured_churn_giwl_flag,


--Match check for parameter: insured_churn_juvenile_flag.
CurrentCampaignObject.insured_churn_juvenile_flag as current_insured_churn_juvenile_flag,
PrevCampaignObject.insured_churn_juvenile_flag as prev_insured_churn_juvenile_flag,

case when IFNULL(CurrentCampaignObject.insured_churn_juvenile_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_juvenile_flag,-1)
        then 'Not Match'
        else '' end as check_insured_churn_juvenile_flag,


--Match check for parameter: insured_churn_wholelife_flag.
CurrentCampaignObject.insured_churn_wholelife_flag as current_insured_churn_wholelife_flag,
PrevCampaignObject.insured_churn_wholelife_flag as prev_insured_churn_wholelife_flag,

case when IFNULL(CurrentCampaignObject.insured_churn_wholelife_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_wholelife_flag,-1)
        then 'Not Match'
        else '' end as check_insured_churn_wholelife_flag,


--Match check for parameter: is_partial_lead.
CurrentCampaignObject.is_partial_lead as current_is_partial_lead,
PrevCampaignObject.is_partial_lead as prev_is_partial_lead,

case when IFNULL(CurrentCampaignObject.is_partial_lead,-1) <> IFNULL(PrevCampaignObject.is_partial_lead,-1)
        then 'Not Match'
        else '' end as check_is_partial_lead,


--Match check for parameter: is_closed_lead.
CurrentCampaignObject.is_closed_lead as current_is_closed_lead,
PrevCampaignObject.is_closed_lead as prev_is_closed_lead,

case when IFNULL(CurrentCampaignObject.is_closed_lead,-1) <> IFNULL(PrevCampaignObject.is_closed_lead,-1)
        then 'Not Match'
        else '' end as check_is_closed_lead,


--Match check for parameter: is_complete_lead.
CurrentCampaignObject.is_complete_lead as current_is_complete_lead,
PrevCampaignObject.is_complete_lead as prev_is_complete_lead,

case when IFNULL(CurrentCampaignObject.is_complete_lead,-1) <> IFNULL(PrevCampaignObject.is_complete_lead,-1)
        then 'Not Match'
        else '' end as check_is_complete_lead,


--Match check for parameter: is_open_lead.
CurrentCampaignObject.is_open_lead as current_is_open_lead,
PrevCampaignObject.is_open_lead as prev_is_open_lead,

case when IFNULL(CurrentCampaignObject.is_open_lead,-1) <> IFNULL(PrevCampaignObject.is_open_lead,-1)
        then 'Not Match'
        else '' end as check_is_open_lead,


--Match check for parameter: days_lead_in_salesforce.
CurrentCampaignObject.days_lead_in_salesforce as current_days_lead_in_salesforce,
PrevCampaignObject.days_lead_in_salesforce as prev_days_lead_in_salesforce,

case when IFNULL(CurrentCampaignObject.days_lead_in_salesforce,-1) <> IFNULL(PrevCampaignObject.days_lead_in_salesforce,-1)
        then 'Not Match'
        else '' end as check_days_lead_in_salesforce,

--Match check for parameter: days_since_express_term_adandon.
CurrentCampaignObject.days_since_express_term_adandon as current_days_since_express_term_adandon,
PrevCampaignObject.days_since_express_term_adandon as prev_days_since_express_term_adandon,

case when IFNULL(CurrentCampaignObject.days_since_express_term_adandon,-1) <> IFNULL(PrevCampaignObject.days_since_express_term_adandon,-1)
        then 'Not Match'
        else '' end as check_days_since_express_term_adandon,


--Match check for parameter: days_have_not_received_field_agent_quote.
CurrentCampaignObject.days_have_not_received_field_agent_quote as current_days_have_not_received_field_agent_quote,
PrevCampaignObject.days_have_not_received_field_agent_quote as prev_days_have_not_received_field_agent_quote,

case when IFNULL(CurrentCampaignObject.days_have_not_received_field_agent_quote,-1) <> IFNULL(PrevCampaignObject.days_have_not_received_field_agent_quote,-1)
        then 'Not Match'
        else '' end as check_days_have_not_received_field_agent_quote,


--Match check for parameter: interaction_driven.
CurrentCampaignObject.interaction_driven as current_interaction_driven,
PrevCampaignObject.interaction_driven as prev_interaction_driven,

case when IFNULL(CurrentCampaignObject.interaction_driven,-1) <> IFNULL(PrevCampaignObject.interaction_driven,-1)
        then 'Not Match'
        else '' end as check_interaction_driven,


--Match check for parameter: insured_giwl_2nd_policy_is_member.
CurrentCampaignObject.insured_giwl_2nd_policy_is_member as current_insured_giwl_2nd_policy_is_member,
PrevCampaignObject.insured_giwl_2nd_policy_is_member as prev_insured_giwl_2nd_policy_is_member,

case when IFNULL(CurrentCampaignObject.insured_giwl_2nd_policy_is_member,-1) <> IFNULL(PrevCampaignObject.insured_giwl_2nd_policy_is_member,-1)
        then 'Not Match'
        else '' end as check_insured_giwl_2nd_policy_is_member,


--Match check for parameter: insured_giwl_term_declined_is_member.
CurrentCampaignObject.insured_giwl_term_declined_is_member as current_insured_giwl_term_declined_is_member,
PrevCampaignObject.insured_giwl_term_declined_is_member as prev_insured_giwl_term_declined_is_member,

case when IFNULL(CurrentCampaignObject.insured_giwl_term_declined_is_member,-1) <> IFNULL(PrevCampaignObject.insured_giwl_term_declined_is_member,-1)
        then 'Not Match'
        else '' end as check_insured_giwl_term_declined_is_member,


--Match check for parameter: insured_giwl_lapsed_is_members.
CurrentCampaignObject.insured_giwl_lapsed_is_members as current_insured_giwl_lapsed_is_members,
PrevCampaignObject.insured_giwl_lapsed_is_members as prev_insured_giwl_lapsed_is_members,

case when IFNULL(CurrentCampaignObject.insured_giwl_lapsed_is_members,-1) <> IFNULL(PrevCampaignObject.insured_giwl_lapsed_is_members,-1)
        then 'Not Match'
        else '' end as check_insured_giwl_lapsed_is_members,


--Match check for parameter: insured_giwl_xsell_is_member.
CurrentCampaignObject.insured_giwl_xsell_is_member as current_insured_giwl_xsell_is_member,
PrevCampaignObject.insured_giwl_xsell_is_member as prev_insured_giwl_xsell_is_member,

case when IFNULL(CurrentCampaignObject.insured_giwl_xsell_is_member,-1) <> IFNULL(PrevCampaignObject.insured_giwl_xsell_is_member,-1)
        then 'Not Match'
        else '' end as check_insured_giwl_xsell_is_member,


--Match check for parameter: Insured_Errored_Transaction.
CurrentCampaignObject.Insured_Errored_Transaction as current_Insured_Errored_Transaction,
PrevCampaignObject.Insured_Errored_Transaction as prev_Insured_Errored_Transaction,

case when IFNULL(CurrentCampaignObject.Insured_Errored_Transaction,-1) <> IFNULL(PrevCampaignObject.Insured_Errored_Transaction,-1)
        then 'Not Match'
        else '' end as check_Insured_Errored_Transaction,


--Match check for parameter: Insured_P_Transaction.
CurrentCampaignObject.Insured_P_Transaction as current_Insured_P_Transaction,
PrevCampaignObject.Insured_P_Transaction as prev_Insured_P_Transaction,

case when IFNULL(CurrentCampaignObject.Insured_P_Transaction,-1) <> IFNULL(PrevCampaignObject.Insured_P_Transaction,-1)
        then 'Not Match'
        else '' end as check_Insured_P_Transaction,


--Match check for parameter: Insured_PremiumPaying_DirectMailTerm.
CurrentCampaignObject.Insured_PremiumPaying_DirectMailTerm as current_Insured_PremiumPaying_DirectMailTerm,
PrevCampaignObject.Insured_PremiumPaying_DirectMailTerm as prev_Insured_PremiumPaying_DirectMailTerm,

case when IFNULL(CurrentCampaignObject.Insured_PremiumPaying_DirectMailTerm,-1) <> IFNULL(PrevCampaignObject.Insured_PremiumPaying_DirectMailTerm,-1)
        then 'Not Match'
        else '' end as check_Insured_PremiumPaying_DirectMailTerm,


--Match check for parameter: prospect_status.
CurrentCampaignObject.prospect_status as current_prospect_status,
PrevCampaignObject.prospect_status as prev_prospect_status,

case when IFNULL(CurrentCampaignObject.prospect_status,-1) <> IFNULL(PrevCampaignObject.prospect_status,-1)
        then 'Not Match'
        else '' end as check_prospect_status

from CurrentCampaignObject
left join PrevCampaignObject on
    CurrentCampaignObject.cell_name = PrevCampaignObject.last_cell_name
    and CurrentCampaignObject.tactic_name = PrevCampaignObject.last_tactic_name
inner join planner_cell on
    planner_cell.id = PrevCampaignObject.last_cell_id

//where

//(
//
//    case when IFNULL(CurrentCampaignObject.resolved_age_min,-1) <> IFNULL(PrevCampaignObject.resolved_age_min,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.resolved_age_max,-1) <> IFNULL(PrevCampaignObject.resolved_age_max,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.unknown_age_inclusion,-1) <> IFNULL(PrevCampaignObject.unknown_age_inclusion,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR


//(
//
//    case when IFNULL(CurrentCampaignObject.milliman_min,-1) <> IFNULL(PrevCampaignObject.milliman_min,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.milliman_max,-1) <> IFNULL(PrevCampaignObject.milliman_max,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.milliman_exclusion,-1) <> IFNULL(PrevCampaignObject.milliman_exclusion,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.unknown_milliman_inclusion,-1) <> IFNULL(PrevCampaignObject.unknown_milliman_inclusion,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.is_prospect,-1) <> IFNULL(PrevCampaignObject.is_prospect,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.is_member,-1) <> IFNULL(PrevCampaignObject.is_member,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.is_customer,-1) <> IFNULL(PrevCampaignObject.is_customer,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.gender_male,-1) <> IFNULL(PrevCampaignObject.gender_male,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.gender_female,-1) <> IFNULL(PrevCampaignObject.gender_female,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.gender_unknown,-1) <> IFNULL(PrevCampaignObject.gender_unknown,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.member_role,-1) <> IFNULL(PrevCampaignObject.member_role,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.unknown_member_role_inclusion,-1) <> IFNULL(PrevCampaignObject.unknown_member_role_inclusion,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.product_eligibility_direct_mail_term,-1) <> IFNULL(PrevCampaignObject.product_eligibility_direct_mail_term,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.product_eligibility_giwl,-1) <> IFNULL(PrevCampaignObject.product_eligibility_giwl,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.product_eligibility_mlta,-1) <> IFNULL(PrevCampaignObject.product_eligibility_mlta,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.product_eligibility_accident,-1) <> IFNULL(PrevCampaignObject.product_eligibility_accident,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.product_eligibility_traditional_term,-1) <> IFNULL(PrevCampaignObject.product_eligibility_traditional_term,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.product_eligibility_express_term,-1) <> IFNULL(PrevCampaignObject.product_eligibility_express_term,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.product_eligibility_individualdirectterm,-1) <> IFNULL(PrevCampaignObject.product_eligibility_individualdirectterm,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.direct_mail_term_upsell_eligibility,-1) <> IFNULL(PrevCampaignObject.direct_mail_term_upsell_eligibility,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.direct_mail_term_upsell_total_face_amount,-1) <> IFNULL(PrevCampaignObject.direct_mail_term_upsell_total_face_amount,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.giwl_upsell_total_face_amount,-1) <> IFNULL(PrevCampaignObject.giwl_upsell_total_face_amount,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.giwl_upsell_eligibility,-1) <> IFNULL(PrevCampaignObject.giwl_upsell_eligibility,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.declined_lifeproduct_flag,-1) <> IFNULL(PrevCampaignObject.declined_lifeproduct_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.declined_accidentproduct_flag,-1) <> IFNULL(PrevCampaignObject.declined_accidentproduct_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.declined_365_flag,-1) <> IFNULL(PrevCampaignObject.declined_365_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.declined_accident_flag,-1) <> IFNULL(PrevCampaignObject.declined_accident_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.declined_adb_flag,-1) <> IFNULL(PrevCampaignObject.declined_adb_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.declined_hip_flag,-1) <> IFNULL(PrevCampaignObject.declined_hip_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.declined_mlta_flag,-1) <> IFNULL(PrevCampaignObject.declined_mlta_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.declined_mpa_flag,-1) <> IFNULL(PrevCampaignObject.declined_mpa_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.declined_pai_flag,-1) <> IFNULL(PrevCampaignObject.declined_pai_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.declined_pdd_flag,-1) <> IFNULL(PrevCampaignObject.declined_pdd_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.declined_waiver_flag,-1) <> IFNULL(PrevCampaignObject.declined_waiver_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.declined_fpda_flag,-1) <> IFNULL(PrevCampaignObject.declined_fpda_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.declined_spda_flag,-1) <> IFNULL(PrevCampaignObject.declined_spda_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.declined_spia_flag,-1) <> IFNULL(PrevCampaignObject.declined_spia_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.declined_directmailterm_flag,-1) <> IFNULL(PrevCampaignObject.declined_directmailterm_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.declined_expressterm_flag,-1) <> IFNULL(PrevCampaignObject.declined_expressterm_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.declined_individualdirectterm_flag,-1) <> IFNULL(PrevCampaignObject.declined_individualdirectterm_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.declined_term_flag,-1) <> IFNULL(PrevCampaignObject.declined_term_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.declined_accumulatorul_flag,-1) <> IFNULL(PrevCampaignObject.declined_accumulatorul_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.declined_lifetimeul_flag,-1) <> IFNULL(PrevCampaignObject.declined_lifetimeul_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.declined_siwl_flag,-1) <> IFNULL(PrevCampaignObject.declined_siwl_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.declined_giwl_flag,-1) <> IFNULL(PrevCampaignObject.declined_giwl_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.declined_juvenile_flag,-1) <> IFNULL(PrevCampaignObject.declined_juvenile_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.declined_wholelife_flag,-1) <> IFNULL(PrevCampaignObject.declined_wholelife_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.club_ok_to_mail,-1) <> IFNULL(PrevCampaignObject.club_ok_to_mail,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.total_insured_inforce_policies,-1) <> IFNULL(PrevCampaignObject.total_insured_inforce_policies,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_inforce_lifeproduct_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_lifeproduct_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_inforce_accidentproduct_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_accidentproduct_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_inforce_annuityproduct_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_annuityproduct_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_inforce_365_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_365_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_inforce_accident_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_accident_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_inforce_adb_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_adb_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_inforce_hip_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_hip_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_inforce_mlta_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_mlta_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_inforce_mpa_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_mpa_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_inforce_pai_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_pai_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_inforce_pdd_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_pdd_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_inforce_waiver_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_waiver_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_inforce_fpda_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_fpda_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_inforce_spda_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_spda_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_inforce_spia_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_spia_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_inforce_directmailterm_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_directmailterm_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_inforce_expressterm_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_expressterm_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_inforce_individualdirectterm_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_individualdirectterm_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_inforce_term_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_term_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_inforce_accumulatorul_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_accumulatorul_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_inforce_lifetimeul_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_lifetimeul_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_inforce_siwl_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_siwl_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_inforce_giwl_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_giwl_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_inforce_juvenile_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_juvenile_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_inforce_wholelife_flag,-1) <> IFNULL(PrevCampaignObject.insured_inforce_wholelife_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_activeapp_lifeproduct_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_lifeproduct_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_activeapp_accidentproduct_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_accidentproduct_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_activeapp_annuityproduct_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_annuityproduct_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_activeapp_365_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_365_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_activeapp_accident_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_accident_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_activeapp_adb_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_adb_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_activeapp_hip_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_hip_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_activeapp_mlta_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_mlta_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_activeapp_mpa_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_mpa_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_activeapp_pai_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_pai_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_activeapp_pdd_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_pdd_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_activeapp_waiver_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_waiver_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_activeapp_fpda_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_fpda_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_activeapp_spda_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_spda_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_activeapp_spia_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_spia_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_activeapp_directmailterm_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_directmailterm_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_activeapp_expressterm_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_expressterm_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_activeapp_individualdirectterm_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_individualdirectterm_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_activeapp_term_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_term_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_activeapp_accumulatorul_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_accumulatorul_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_activeapp_lifetimeul_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_lifetimeul_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_activeapp_siwl_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_siwl_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_activeapp_giwl_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_giwl_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_activeapp_juvenile_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_juvenile_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_activeapp_wholelife_flag,-1) <> IFNULL(PrevCampaignObject.insured_activeapp_wholelife_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_coldfeet_365_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_365_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_coldfeet_accident_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_accident_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_coldfeet_adb_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_adb_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_coldfeet_hip_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_hip_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_coldfeet_mlta_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_mlta_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_coldfeet_mpa_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_mpa_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_coldfeet_pai_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_pai_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_coldfeet_pdd_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_pdd_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_coldfeet_waiver_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_waiver_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_coldfeet_fpda_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_fpda_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_coldfeet_spda_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_spda_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_coldfeet_spia_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_spia_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_coldfeet_directmailterm_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_directmailterm_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_coldfeet_expressterm_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_expressterm_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_coldfeet_individualdirectterm_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_individualdirectterm_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_coldfeet_term_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_term_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_coldfeet_accumulatorul_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_accumulatorul_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_coldfeet_lifetimeul_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_lifetimeul_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_coldfeet_siwl_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_siwl_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_coldfeet_giwl_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_giwl_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_coldfeet_juvenile_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_juvenile_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_coldfeet_wholelife_flag,-1) <> IFNULL(PrevCampaignObject.insured_coldfeet_wholelife_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_churn_365_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_365_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_churn_accident_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_accident_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_churn_adb_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_adb_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_churn_hip_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_hip_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_churn_mlta_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_mlta_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_churn_mpa_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_mpa_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_churn_pai_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_pai_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_churn_pdd_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_pdd_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_churn_waiver_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_waiver_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_churn_fpda_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_fpda_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_churn_spda_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_spda_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_churn_spia_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_spia_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_churn_directmailterm_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_directmailterm_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_churn_expressterm_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_expressterm_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_churn_individualdirectterm_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_individualdirectterm_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_churn_term_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_term_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_churn_accumulatorul_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_accumulatorul_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_churn_lifetimeul_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_lifetimeul_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_churn_siwl_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_siwl_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_churn_giwl_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_giwl_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_churn_juvenile_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_juvenile_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_churn_wholelife_flag,-1) <> IFNULL(PrevCampaignObject.insured_churn_wholelife_flag,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.is_partial_lead,-1) <> IFNULL(PrevCampaignObject.is_partial_lead,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.is_closed_lead,-1) <> IFNULL(PrevCampaignObject.is_closed_lead,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.is_complete_lead,-1) <> IFNULL(PrevCampaignObject.is_complete_lead,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.is_open_lead,-1) <> IFNULL(PrevCampaignObject.is_open_lead,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.days_lead_in_salesforce,-1) <> IFNULL(PrevCampaignObject.days_lead_in_salesforce,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.days_since_express_term_adandon,-1) <> IFNULL(PrevCampaignObject.days_since_express_term_adandon,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.days_have_not_received_field_agent_quote,-1) <> IFNULL(PrevCampaignObject.days_have_not_received_field_agent_quote,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.interaction_driven,-1) <> IFNULL(PrevCampaignObject.interaction_driven,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_giwl_2nd_policy_is_member,-1) <> IFNULL(PrevCampaignObject.insured_giwl_2nd_policy_is_member,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_giwl_term_declined_is_member,-1) <> IFNULL(PrevCampaignObject.insured_giwl_term_declined_is_member,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_giwl_lapsed_is_members,-1) <> IFNULL(PrevCampaignObject.insured_giwl_lapsed_is_members,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.insured_giwl_xsell_is_member,-1) <> IFNULL(PrevCampaignObject.insured_giwl_xsell_is_member,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.Insured_Errored_Transaction,-1) <> IFNULL(PrevCampaignObject.Insured_Errored_Transaction,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.Insured_P_Transaction,-1) <> IFNULL(PrevCampaignObject.Insured_P_Transaction,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.Insured_PremiumPaying_DirectMailTerm,-1) <> IFNULL(PrevCampaignObject.Insured_PremiumPaying_DirectMailTerm,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')
//OR
//(
//
//    case when IFNULL(CurrentCampaignObject.prospect_status,-1) <> IFNULL(PrevCampaignObject.prospect_status,-1)
//        then 'Not Match'
//        else '' end = 'Not Match')

//order by
//    CurrentCampaignObject.tactic_name
//    ,
//    case when CurrentCampaignObject.cell_parameter_id = planner_cell.parameters_id
//    then 'same_param' else 'different_param'end asc
    )
select
*
from AQ_portion
union
select *
from CS_portion
order by
check_milliman_min desc,
check_milliman_max desc,
check_milliman_exclusion desc,
check_unknown_milliman_inclusion desc,
check_is_prospect desc,
check_is_member desc,
check_is_customer desc,
check_gender_male desc,
check_gender_female desc,
check_gender_unknown desc,
check_member_role desc,
check_unknown_member_role_inclusion desc,
check_product_eligibility_direct_mail_term desc,
check_product_eligibility_giwl desc,
check_product_eligibility_mlta desc,
check_product_eligibility_accident desc,
check_product_eligibility_traditional_term desc,
check_product_eligibility_express_term desc,
check_product_eligibility_individualdirectterm desc,
check_direct_mail_term_upsell_eligibility desc,
check_direct_mail_term_upsell_total_face_amount desc,
check_giwl_upsell_total_face_amount desc,
check_giwl_upsell_eligibility desc,
check_declined_lifeproduct_flag desc,
check_declined_accidentproduct_flag desc,
check_declined_365_flag desc,
check_declined_accident_flag desc,
check_declined_adb_flag desc,
check_declined_hip_flag desc,
check_declined_mlta_flag desc,
check_declined_mpa_flag desc,
check_declined_pai_flag desc,
check_declined_pdd_flag desc,
check_declined_waiver_flag desc,
check_declined_fpda_flag desc,
check_declined_spda_flag desc,
check_declined_spia_flag desc,
check_declined_directmailterm_flag desc,
check_declined_expressterm_flag desc,
check_declined_individualdirectterm_flag desc,
check_declined_term_flag desc,
check_declined_accumulatorul_flag desc,
check_declined_lifetimeul_flag desc,
check_declined_siwl_flag desc,
check_declined_giwl_flag desc,
check_declined_juvenile_flag desc,
check_declined_wholelife_flag desc,
check_club_ok_to_mail desc,
check_total_insured_inforce_policies desc,
check_insured_inforce_lifeproduct_flag desc,
check_insured_inforce_accidentproduct_flag desc,
check_insured_inforce_annuityproduct_flag desc,
check_insured_inforce_365_flag desc,
check_insured_inforce_accident_flag desc,
check_insured_inforce_adb_flag desc,
check_insured_inforce_hip_flag desc,
check_insured_inforce_mlta_flag desc,
check_insured_inforce_mpa_flag desc,
check_insured_inforce_pai_flag desc,
check_insured_inforce_pdd_flag desc,
check_insured_inforce_waiver_flag desc,
check_insured_inforce_fpda_flag desc,
check_insured_inforce_spda_flag desc,
check_insured_inforce_spia_flag desc,
check_insured_inforce_directmailterm_flag desc,
check_insured_inforce_expressterm_flag desc,
check_insured_inforce_individualdirectterm_flag desc,
check_insured_inforce_term_flag desc,
check_insured_inforce_accumulatorul_flag desc,
check_insured_inforce_lifetimeul_flag desc,
check_insured_inforce_siwl_flag desc,
check_insured_inforce_giwl_flag desc,
check_insured_inforce_juvenile_flag desc,
check_insured_inforce_wholelife_flag desc,
check_insured_activeapp_lifeproduct_flag desc,
check_insured_activeapp_accidentproduct_flag desc,
check_insured_activeapp_annuityproduct_flag desc,
check_insured_activeapp_365_flag desc,
check_insured_activeapp_accident_flag desc,
check_insured_activeapp_adb_flag desc,
check_insured_activeapp_hip_flag desc,
check_insured_activeapp_mlta_flag desc,
check_insured_activeapp_mpa_flag desc,
check_insured_activeapp_pai_flag desc,
check_insured_activeapp_pdd_flag desc,
check_insured_activeapp_waiver_flag desc,
check_insured_activeapp_fpda_flag desc,
check_insured_activeapp_spda_flag desc,
check_insured_activeapp_spia_flag desc,
check_insured_activeapp_directmailterm_flag desc,
check_insured_activeapp_expressterm_flag desc,
check_insured_activeapp_individualdirectterm_flag desc,
check_insured_activeapp_term_flag desc,
check_insured_activeapp_accumulatorul_flag desc,
check_insured_activeapp_lifetimeul_flag desc,
check_insured_activeapp_siwl_flag desc,
check_insured_activeapp_giwl_flag desc,
check_insured_activeapp_juvenile_flag desc,
check_insured_activeapp_wholelife_flag desc,
check_insured_coldfeet_365_flag desc,
check_insured_coldfeet_accident_flag desc,
check_insured_coldfeet_adb_flag desc,
check_insured_coldfeet_hip_flag desc,
check_insured_coldfeet_mlta_flag desc,
check_insured_coldfeet_mpa_flag desc,
check_insured_coldfeet_pai_flag desc,
check_insured_coldfeet_pdd_flag desc,
check_insured_coldfeet_waiver_flag desc,
check_insured_coldfeet_fpda_flag desc,
check_insured_coldfeet_spda_flag desc,
check_insured_coldfeet_spia_flag desc,
check_insured_coldfeet_directmailterm_flag desc,
check_insured_coldfeet_expressterm_flag desc,
check_insured_coldfeet_individualdirectterm_flag desc,
check_insured_coldfeet_term_flag desc,
check_insured_coldfeet_accumulatorul_flag desc,
check_insured_coldfeet_lifetimeul_flag desc,
check_insured_coldfeet_siwl_flag desc,
check_insured_coldfeet_giwl_flag desc,
check_insured_coldfeet_juvenile_flag desc,
check_insured_coldfeet_wholelife_flag desc,
check_insured_churn_365_flag desc,
check_insured_churn_accident_flag desc,
check_insured_churn_adb_flag desc,
check_insured_churn_hip_flag desc,
check_insured_churn_mlta_flag desc,
check_insured_churn_mpa_flag desc,
check_insured_churn_pai_flag desc,
check_insured_churn_pdd_flag desc,
check_insured_churn_waiver_flag desc,
check_insured_churn_fpda_flag desc,
check_insured_churn_spda_flag desc,
check_insured_churn_spia_flag desc,
check_insured_churn_directmailterm_flag desc,
check_insured_churn_expressterm_flag desc,
check_insured_churn_individualdirectterm_flag desc,
check_insured_churn_term_flag desc,
check_insured_churn_accumulatorul_flag desc,
check_insured_churn_lifetimeul_flag desc,
check_insured_churn_siwl_flag desc,
check_insured_churn_giwl_flag desc,
check_insured_churn_juvenile_flag desc,
check_insured_churn_wholelife_flag desc,
check_is_partial_lead desc,
check_is_closed_lead desc,
check_is_complete_lead desc,
check_is_open_lead desc,
check_days_lead_in_salesforce desc,
check_days_since_express_term_adandon desc,
check_days_have_not_received_field_agent_quote desc,
check_interaction_driven desc,
check_insured_giwl_2nd_policy_is_member desc,
check_insured_giwl_term_declined_is_member desc,
check_insured_giwl_lapsed_is_members desc,
check_insured_giwl_xsell_is_member desc,
check_Insured_Errored_Transaction desc,
check_Insured_P_Transaction desc,
check_Insured_PremiumPaying_DirectMailTerm desc,
check_prospect_status desc,
tactic_name
