import pandas as pd
import psycopg2
from sqlalchemy import create_engine
import os, sys
from distutils.util import strtobool
import get_validation_result as validation_string
import openpyxl
import datetime
from openpyxl.utils.dataframe import dataframe_to_rows
import loading_mailing_schedule as load_ms
import yaml

credObj = yaml.safe_load(open("credentials.yml", 'r'))


today = datetime.datetime.today()
today = today.strftime( '%m-%d-%Y')

result_folder = 'validation_result\\'

RedShift ={
    'Name': 'Redshift',
    'Type': 'RS',
    'Database': 'aaal',
    'Server': 'merkle-redshift.aaalife.com',
    'Port': 5439,
    'Username': credObj['mde']['username'],
    'Password': credObj['mde']['password']
}


mtd = {
     'USER': credObj['mtd']['username'],
     'PASSWORD': credObj['mtd']['password'],
     'HOST': 'metadata-prd-write.data-prd.aaalifeaws.cloud',
     'PORT': '3306'
}

def RSConnection():
    """Connection to Redshift"""
    try:
        conn = psycopg2.connect(dbname = RedShift['Database'],
                           host = RedShift['Server'],
                           port = RedShift['Port'],
                           user = RedShift['Username'],
                           password = RedShift['Password']
        )
        conn.autocommit = True
        return conn.cursor()
    except:
        print("Check Connections.py - RSConnection() to debug.")

def MTDConnection(database):

    try:
        host = mtd['HOST']
        user = mtd['USER']
        password = mtd['PASSWORD']
        db = database

        engine = create_engine(f"mysql://{user}:{password}@{host}/{db}")
        conn = engine.connect()
        conn.autocommit = True
        return conn
    except:
        print("Check MTDConnection() to debug.")

def get_camp_year_from_user():

    question = '\nEnter campaign year to begin campaign validation.\n'
    sys.stdout.write('%s' % question)
    campaign_year = None
    while True:
        try:
            campaign_year = input()
            campaign_year = int(campaign_year)
            eligible_options = [2020, 2021, 2022, 2023, 2024, 2025, 2026]
            if not campaign_year in eligible_options:
                raise ValueError
            else:
                print('\nOK!')
                print('----')
                return (campaign_year)
        except ValueError:
            sys.stdout.write('\nInvalid entry! Pick 2020, 2021, 2022, 2023, 2024, 2025, 2026\n')

    return campaign_year

def get_camp_num_from_user():

    question = 'Enter campaign number to begin campaign validation.\n'
    sys.stdout.write('%s' % question)
    campaign_number = None
    while True:
        try:
            campaign_number = input()
            eligible_options = [str(c + 1) for c in range(0, 99)]
            if not campaign_number in eligible_options:
                raise ValueError
            else:
                print('\nOK!')
                return int(campaign_number)
        except ValueError:
            sys.stdout.write('\nPlease respond with integer 1 to 99.\n')

    return campaign_number

def del_existing_data(campaign_year, campaign_number):
    database = 'validation'
    conn = MTDConnection(database)

    del_statement = f"""
delete from validation.mailing_schedule_agg
where campaign_number = {campaign_number}
and campaign_year = {campaign_year}
    """
    conn.execute(del_statement)
    print('---')
    print('Deleting existing data completed. ')
    conn.close()

    return

def load_agg_into_mtd(campaign_year, campaign_number):
    """To load model.mailing_schedule_agg from MDE into MTD."""
    #campaign_year = 2020
    #campaign_number = 10
    print('Loading into MTD.')

    retrieval_qry = f"""
SELECT distinct
    agg.campaign_year,
    agg.campaign_number,
    agg.tactic_name,
    agg.company_code,
    agg.States,
    agg.model_percent,
    agg.age_min,
    agg.age_max,
    agg.age_unk,
    agg.keycode,
    agg.packageID,
    agg.latest_estimate,
    agg.variance_percent,
    agg.comments,
    agg.drop_date,
    agg.program,
    agg.insert_at,
    agg.budget_vol,
    po.commision_club_cd as club_number,
    agg.reporting_group_name,
    agg.phone_number,
    agg.estimated_mille,
    'C'+cast(agg.campaign_number as varchar)+'-'+cast(agg.campaign_year as varchar) as campaign_name
FROM model.mailing_schedule_agg agg
left join model.keycode_4_to_10th po
    on po.tactic_name = agg.tactic_name
    and po.st_cd = agg.states
    and po.keycode_positions_5_7 = substring(agg.keycode,5,3)
where agg.campaign_number = {campaign_number}
    and agg.campaign_year = {campaign_year}
    ;

    """

    col_name = [
    'campaign_year',
    'campaign_number',
    'tactic_name',
    'company_code',
    'states',
    'model_percent',
    'age_min',
    'age_max',
    'age_unk',
    'keycode',
    'packageid',
    'latest_estimate',
    'variance_percent',
    'comments',
    'drop_date',
    'program',
    'insert_at',
    'budget_vol',
    'resident_club_code',
    'reporting_group_name',
    'phone_number',
    'estimated_mille',
    'campaign_name'

    ]
    rs = RSConnection()
    rs.execute(retrieval_qry)
    df = pd.DataFrame(rs.fetchall(), columns = col_name)
    database = 'validation'
    conn = MTDConnection(database)
    df.to_sql(name='mailing_schedule_agg', con = conn,  if_exists='append', index=False)

    print('Insert into MTD DB completed.')
    rs.close()
    conn.close()
    return

def run_validation(campaign_name):
    """Run queries and produce report."""
    database = 'campaign_planner'
    conn = MTDConnection(database)
    print('---')
    print('Producing Validation Report. Please hold.')
    qry_1 = validation_string.step_1_orphans()
    qry_2 = validation_string.step_2_check_params(campaign_name)
    qry_3 = validation_string.step3_check_cs_pkg_phone(campaign_name)
    qry_3b = validation_string.step3b_check_variant_total(campaign_name)
    qry_4 = validation_string.step4_check_mille_param(campaign_name)

    step1 = pd.read_sql_query(qry_1, con = conn)
    step2 = pd.read_sql_query(qry_2, con = conn)
    step3 = pd.read_sql_query(qry_3, con = conn)
    step3b = pd.read_sql_query(qry_3b, con = conn)
    step4 = pd.read_sql_query(qry_4, con = conn)

    def fmt(data, fmt_dict):
        return data.replace(fmt_dict)

    fmt_dict = {
        'Not Match': 'background-color: red',
    }

    workbook_name = campaign_name+'-'+'Metadata_Validation_'+today+'.xlsx'
    writer = pd.ExcelWriter(result_folder+workbook_name)

    step1.to_excel(writer, engine='openpyxl', sheet_name='Check Orphans',index=False)

    checkers = [name for  name in step2.columns if name.startswith('check_')]
    styled = step2.style.apply(fmt, fmt_dict=fmt_dict, subset = checkers)
    styled.to_excel(writer, engine='openpyxl', sheet_name='Check Parameters',index=False)

    checkers = [name for  name in step3.columns if name.startswith('check_')]
    styled = step3.style.apply(fmt, fmt_dict=fmt_dict, subset = checkers)
    styled.to_excel(writer, engine='openpyxl', sheet_name='Check Club-State PKG Phone',index=False)

    step3b.to_excel(writer, engine='openpyxl', sheet_name='Check Variant Total',index=False)

    checkers = [name for  name in step4.columns if name.startswith('check_')]
    styled = step4.style.apply(fmt, fmt_dict=fmt_dict, subset = checkers)
    styled.to_excel(writer, engine='openpyxl', sheet_name='Check Mille',index=False)

    writer.save()
    print('Completed.')

    return


def check_phone_input(campaign_number, campaign_year ):
    """Check if phone numbers exist in model.mailing_schedule_agg for a given campaign number and year."""
    qryy = validation_string.check_phone_number_input(campaign_number, campaign_year)

    rs =RSConnection()
    rs.execute(qryy)
    col_name= [desc[0] for desc in rs.description]

    df = pd.DataFrame(rs.fetchall(), columns = col_name)
    headers = [col for col in df.columns]

    flag = False

    if not df.empty:
        print('\nFailed: Double check phone number entry.')
        print('Below phone numbers are not in place.')
        print('\n {} {} {} {} {} '.format('_'*20, '_'*60, '_'*12, '_'*12, '_'*12))

        fmt = '|{:^20}|{:60}|{:^12}|{:^12}|{:^12}|'
        print(fmt.format(*headers))
        print(' {} {} {} {} {} '.format('_'*20, '_'*60, '_'*12, '_'*12, '_'*12))

        for idx, r in df.iterrows():
            temp_r = [x for x in r]
            print(fmt.format(*temp_r))
        print('\n {} {} {} {} {} '.format('_'*20, '_'*60, '_'*12, '_'*12, '_'*12))
        print('\n')
    else:
        print('\nPass: Phone numbers are in place.')
        flag = True

    return flag

def check_mille_input(campaign_number, campaign_year ):
    """Check if mille data are complete in model.mailing_schedule_agg for a given campaign number and year.
Only check AQ/BM tactics.
    """
    qryy = validation_string.check_mille_input(campaign_number, campaign_year)

    rs =RSConnection()
    rs.execute(qryy)
    col_name= [desc[0] for desc in rs.description]
    col_name

    df = pd.DataFrame(rs.fetchall(), columns = col_name)


    headers = [col for col in df.columns]


    flag = False

    if not df.empty:
        print('\nFailed: Double check not all mille are in place.\n')
        print('Below milles are not in place.')
        print('\n {} {} {} {} {} '.format('_'*20, '_'*60, '_'*21, '_'*10, '_'*10))

        fmt = '|{:^20}|{:60}|{:^21}|{:^10}|{:^10}|'

        print(fmt.format(*headers))
        print(' {} {} {} {} {} '.format('_'*20, '_'*60, '_'*21, '_'*10, '_'*10))

        for idx, r in df.iterrows():
            temp_r = [str(x) for x in r]
            print(fmt.format(*temp_r))

        print(' {} {} {} {} {} '.format('_'*20, '_'*60, '_'*21, '_'*10, '_'*10))
        print('\n')
    else:
        print('\nPass: Mille are in place.')
        flag = True

    return flag

def user_yes_no_query(question):
    sys.stdout.write('%s \n[y/n]\n' % question)
    while True:
        try:
            return strtobool(input().lower())
        except ValueError:
            sys.stdout.write('Please respond with \'y\' or \'n\'.\n')


def checking_input(campaign_number, campaign_year ):
    """Flow control function on checking phone number and mille."""
    print('\nChecking input to repare for validation')

    flag_mille = check_mille_input(campaign_number, campaign_year)

    flag_phone = check_phone_input(campaign_number, campaign_year)

    if flag_mille == False or flag_phone ==False:
        print('Either phone number or mille in model.mailing_schedule is incomplete.')
        question = 'Continue?'
        greenlight = user_yes_no_query(question)
    else:
        greenlight = 1

    return greenlight

def main():
    """Flow control function to produce validation report."""
    # User input block
    campaign_year = get_camp_year_from_user()
    campaign_number = get_camp_num_from_user()
    campaign_name = 'C'+str(campaign_number)+'-'+str(campaign_year)
    question = '''\nRefresh model.mailing_schedule_agg?
    Enter \'Y\' if there\'s known update in Mailing_schedule.'''
    ans = user_yes_no_query(question)

    if ans == 1:
        load_ms.load_mailing_schedule_table(campaign_year, campaign_number)

        del_existing_data(campaign_year, campaign_number)
        load_agg_into_mtd(campaign_year, campaign_number)
        run_validation(campaign_name)
    else:
        greenlight = checking_input(campaign_number, campaign_year)

        if greenlight == 1 :
            del_existing_data(campaign_year, campaign_number)
            load_agg_into_mtd(campaign_year, campaign_number)
            run_validation(campaign_name)
        else:
            print('User Opted out. Bye!')
            return

    return


if __name__ == "__main__":
    main()