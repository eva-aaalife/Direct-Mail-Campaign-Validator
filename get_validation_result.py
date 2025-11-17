

main_folder = 'validation_queries\\'


def read_file(file_name):
    qry = ""
    with open(main_folder + file_name, 'r') as sql:
        qry = [n for n in sql.readlines() if (not n.startswith('--'))
                                            and (not n.startswith('//')) ]
    qry = ''.join(qry)
    qry = qry.replace('%', '%%')
    return qry


def check_phone_number_input(campaign_number, campaign_year):
    qry = f"""
with
pass_1 as (
SELECT
    campaign_number,
    tactic_name,
    right(keycode, 1) as keycode10th ,
    count(*) as total_row,
    sum(case when phone_number is not null then 1 else 0 end) as check_phone
FROM model.mailing_schedule_agg
where campaign_number = {campaign_number }
and campaign_year = {campaign_year}
group by
right(keycode, 1) ,
campaign_number,
tactic_name
)
select distinct
    campaign_number,
    tactic_name,
    keycode10th,
    total_row,
    check_phone
from pass_1
where total_row <> check_phone
;

    """
    return qry



def check_mille_input(campaign_number, campaign_year):
    qry = f"""
with
pass_1 as (
SELECT
    campaign_number,
    tactic_name,
    reporting_group_name,
    sum(latest_estimate) as latest_est,
    count(*) as total_row,
    sum(case when tactic_name not like '%CS%' and estimated_mille is not null then 1 else 0 end) as check_mille
FROM model.mailing_schedule_agg
where campaign_number = {campaign_number}
and campaign_year = {campaign_year}
group by
campaign_number,
reporting_group_name,
tactic_name
)
select distinct
    campaign_number,
    tactic_name,
    reporting_group_name,
    total_row,
    check_mille
from pass_1
where (total_row <> check_mille )
and tactic_name not like '%CS%'
and latest_est >0
;
    """
    return qry


def step_1_orphans():

    file_name = 'step1_check_orphan_objects_v2_combine.sql'
    qry = read_file(file_name)
    return qry


def step_2_check_params(campaign_name):

    file_name = 'step2b_check_params_v2_combine.sql'
    qry = ''.join(read_file(file_name))
    return qry.format(campaign_name)


def step3_check_cs_pkg_phone(campaign_name):

    file_name = 'step3_check_club_state_final.sql'
    qry = read_file(file_name)
    return qry.format(campaign_name)


def step3b_check_variant_total(campaign_name):

    file_name = 'step3b_check_variant_total.sql'
    qry = read_file(file_name)
    return qry.format(campaign_name)


def step4_check_mille_param(campaign_name):

    file_name = 'step4_check_mille_param.sql'
    qry = read_file(file_name)
    return qry.format(campaign_name)
