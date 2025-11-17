import pymssql
import pandas as pd
import boto3
import s3fs
import psycopg2
import yaml

credObj = yaml.safe_load(open("credentials.yml", 'r'))

"""
# If you encounterd pandas error, install the older version
python -m pip install 'pandas<0.25.0'

"""

DM01 = {
	'server': 'PRDSQL1',
	'database': 'Marketing'
}

RedShift = {
	'Name': 'Redshift',
	'Type': 'RS',
	'Database': 'aaal',
	'Server': 'merkle-redshift.aaalife.com',
	'Port': 5439,
    'Username': credObj['mde']['username'],
    'Password': credObj['mde']['password']
}

access_key_id = credObj['s3']['access_key_id']
secret_access_key = credObj['s3']['secret_access_key']
bucket = "merkle-aaal-analytics-prod"
prefix2 = "inbound/landing/"

# Connection to PRDSQL1


def DM01Connection():
	try:
		conn = pymssql.connect(
			server=DM01['server'],
			database=DM01['database']
		)

		return conn.cursor()
	except:
		print("DM01Connection() to debug.")


def RSConnection():
	"""Connection to Redshift"""
	try:
		conn = psycopg2.connect(dbname=RedShift['Database'],
						   host=RedShift['Server'],
						   port=RedShift['Port'],
						   user=RedShift['Username'],
						   password=RedShift['Password']
		)
		conn.autocommit = True
		return conn.cursor()
	except:
		print("Check Connections.py - RSConnection() to debug.")


def get_mailing_schedule_qry(campaign_year, campaign_number):
	"""return query string"""
	# Base query
	mailing_schedule_query = """
Declare @Delimiter Char = ' '; Declare @camp_year int = {}; Declare @camp_num int = {} ;
with
	get_vols as
	(	select
			keycode,
			sum([budget]) as budget_vol,
			sum([latest estimate]) as latest_estimate,
			sum([adobe_launch_count]) as adobe_launch_count
		from
			Marketing.dbo.mailing_schedule
		where
			year = @camp_year and
			campaignNumber = @camp_num
		group by
			keycode ),
	camp as
	(	select
			distinct row_number() over ( partition by keycode
			order by
				LTRIM(RTRIM(Split.a.value('.', 'VARCHAR(100)'))) asc ) as row_num,
	a.year as campaign_year,
	a.CampaignNumber as campaign_number ,
	a.program,
	RTrim(a.rs_name) as tactic_name,
	a.[PRCOCODE] as company_code,
	LTRIM(RTRIM(Split.a.value('.',
	'VARCHAR(100)'))) 'States',
	[Model % Mailed] as model_percent,
	[Comments Member Profile] as comment,
	case
		when (PATINDEX('%[0-9][0-9]-[0-9][0-9]%',[Comments Member Profile])) <> 0
		then SUBSTRING([Comments Member Profile], (PATINDEX('%[0-9][0-9]-[0-9][0-9]%',[Comments Member Profile])),2)
		else Null
	end as age_min,
	case
		when (PATINDEX('%[0-9][0-9]-[0-9][0-9]%',[Comments Member Profile])) <> 0
		then SUBSTRING([Comments Member Profile], (PATINDEX('%-[0-9][0-9]%',[Comments Member Profile]))+1,2)
		else Null
	end as age_max,
	case
		when PATINDEX('%UNK%',[Comments Member Profile]) <> 0
		then 'Y'
		else
		case
			when (PATINDEX('%[0-9][0-9]-[0-9][0-9]%',[Comments Member Profile])) <> 0
			then 'N'
			else Null
		end
	end as age_unk,
	[initial Drop Date] as drop_date,
	a.keycode,
	packageID,
	substring
	(
		a.keycode,
		1,
		9
	)
	as keycode9th,
	substring
	(
		a.keycode,
		10,
		1
	)
	as keycode10th
from
	(	SELECT
			year,
			CampaignNumber,
			case
				when program = 'GIWL' and
				(substring(keycode,5,2) = 'BM')
				then 'GIWL BM'
				else Program
			end as Program,
			case
				when program = 'D TermLCS'
				then 'Direct Mail Member Term Lapsed Non-Complete (D TERMLCS)'
				when program = 'MLTALCS'
				then 'MLTA Lapsed Non-Complete (MLTALCS)'
				when program = 'D TermUCS'
				then 'Direct Mail Member Term 2nd Policy (D TERMUCS)'
				when program = 'GIWL2CS'
				then 'GIWL 2nd Policy (GIWL2CS)'
				when program = 'GIWLLCS'
				then 'GIWL Lapsed Non-Complete (GIWLLCS)'
				when program = 'MLTACS'
				then 'MLTA Cross-Sell (MLTACS)'
				when program = 'GIWLCS'
				then 'GIWL Cross-Sell (GIWLCS)'
				when program = 'D TermCS'
				then 'Direct Mail Member Term Cross-Sell (D TERMCS)'
				when program = 'GIWLTDCS'
				then 'GIWL to Term Declined (GIWLTDCS)'
				when program = 'GIWL'
				and
				(substring(keycode,5,2) <> 'BM')
				then 'GIWL Member'
				when program = 'MLTA'
				then 'MLTA Member'
				when program = 'D Term'
				then 'Direct Mail Member Term'
				when program = 'D Term Random'
				then 'Direct Mail Member Term - Random'
				when program = 'D Term Remark'
				then 'Direct Mail Member Term - Remark'
				when program = 'Accident'
				then 'ACCIDENT Member'
				when program = 'Ind Term'
				then 'Individual Direct Term Non-Member'
				when program = 'GIWL'
				and
				(substring(keycode,5,2) = 'BM')
				then 'GIWL Non-Member'
			end as RS_NAME,
			[Company Code],
			[PRCOCODE],
			[States To Be Mailed],
			keycode,
			cast('<M>' +
			Replace
				(
					[states to be mailed],
					' ',
					'</M><M>'
				)
				+ '</M>' as XML) as Data,
			[Model % Mailed],
			[Comments Member Profile],
			[initial Drop Date],
			packageID
		FROM
			[dbo].[mailing_schedule]
		where
			year = @camp_year and
			campaignNumber = @camp_num ) as A
		cross apply data.nodes('/M') as Split(a) ),
	add_vol as (select
					camp.*,
					get_vols.latest_estimate,
					get_vols.budget_vol,
					get_vols.adobe_launch_count
				from
					camp
					left join get_vols
					on get_vols.keycode = camp.keycode and
					camp.row_num = 1 ),
	variance_calculation_1 as (	select
									keycode9th,
									sum(latest_estimate) as keycode_total
								from
									add_vol
								group by
									keycode9th ),
	variance_calculation_2 as(	select
									distinct variance_calculation_1.keycode9th,
									keycode_total,
									add_vol.keycode10th,
									add_vol.latest_estimate,
									case
										when keycode_total is not null and
										keycode_total <> 0
										then round( (add_vol.latest_estimate*1.0 / keycode_total*1.0) ,2)
										else 0
									end as variance_percent
								from
									variance_calculation_1
									inner join add_vol
									on add_vol.keycode9th = variance_calculation_1.keycode9th )
select
	distinct add_vol.campaign_year,
	add_vol.campaign_number,
	add_vol.tactic_name,
	add_vol.company_code,
	add_vol.States,
	isnull(add_vol.model_percent, '') as model_percent,
	isnull(add_vol.age_min, '') as age_min,
	isnull(add_vol.age_max, '') as age_max,
	isnull(add_vol.age_unk, '') as age_unk,
	add_vol.keycode,
	isnull(add_vol.packageID, '') as packageID,
	isnull(add_vol.latest_estimate,0) as latest_estimate,
	isnull(variance_calculation_2.variance_percent,0) as variance_percent,
	add_vol.comment,
	add_vol.drop_date,
	add_vol.program,
	getdate() as pulled_at_est,
	isnull(add_vol.budget_vol,0) as budget_vol,
	isnull(add_vol.adobe_launch_count, 0) as adobe_launch_count
from
	add_vol
		inner join variance_calculation_2
		on variance_calculation_2.keycode9th = add_vol.keycode9th and
		variance_calculation_2.keycode10th = add_vol.keycode10th
where
	variance_calculation_2.variance_percent is not null
order by
	keycode

	"""

	return mailing_schedule_query.format(campaign_year, campaign_number)


def get_ms_data_by_campaign_year_num(campaign_year, campaign_number):
	"""Obtain data from mailing schedule. Return DataFrame."""

	# Initiate cursor
	dm1_conn = DM01Connection()

	query = get_mailing_schedule_qry(campaign_year, campaign_number)

	column_names = [
		'campaign_year',
		'campaign_number',
		'tactic_name',
		'company_code',
		'States',
		'model_percent',
		'age_min',
		'age_max',
		'age_unk',
		'keycode',
		'packageID',
		'latest_estimate',
		'variance_percent',
		'comment',
		'drop_date',
		'program',
		'pulled_at_est',
		'budget_vol',
		'adobe_launch_count'
		]

	dm1_conn.execute(query)

	df = pd.DataFrame(dm1_conn.fetchall(), columns=column_names)

	return df


def store_df_into_s3(df, campaign_year, campaign_number):
	"""Store the dataframe into s3 to prepare for insertion into table. Return s3 url upon success load."""
	if not df.empty:
		bytes_to_write = df.to_csv(None, index=False).encode()

		fs = s3fs.S3FileSystem(anon=False,
								key=access_key_id,
								secret=secret_access_key,
								use_ssl=False)
		filename = 'Mailing_Schedule_C' + str(campaign_number) + '_' + str(campaign_year)+'.csv'
		s3_url = prefix2 + filename

		with fs.open(bucket+'/' + s3_url, 'wb') as f:
			try:
				f.write(bytes_to_write)
				f.close()
				full_s3_url = 's3://' + bucket + '/' + s3_url
				return full_s3_url
			except:
				raise Exception('Loading data into S3 was unsuccessful.')

	else:
		raise Exception('Empty DataFrame Retrived. Check BI query/function.')


def build_copy_statement(s3_url):
	"""Return Copy statement with given s3 file address."""

	copy_statement = r'''
	copy model.mailing_schedule_agg(
	campaign_year,
	campaign_number,
	tactic_name,
	company_code,
	States,
	model_percent,
	age_min,
	age_max,
	age_unk,
	keycode,
	packageID,
	latest_estimate,
	variance_percent,
	comments,
	drop_date,
	program,
	insert_at,
	budget_vol,
	adobe_launch_count
	)
	from '%s'
	iam_role 'arn:aws:iam::383610932907:role/Merkle_SOA_Redshift_to_s3' MAXERROR
		9999 DELIMITER AS ',' IGNOREHEADER AS 1 DATEFORMAT AS 'auto' TIMEFORMAT AS
	'auto' TRIMBLANKS ACCEPTINVCHARS AS ' ' IGNOREBLANKLINES removequotes;
		''' % format(s3_url)
	return copy_statement


def delete_agg_table(campaign_year, campaign_number):
	""" Delete from agg table. """
	del_query = f'''
		delete from model.mailing_schedule_agg
		where campaign_year = {campaign_year} and campaign_number = {campaign_number};
	'''
	rs = RSConnection()
	rs.execute(del_query)
	print('----')
	print("Loading campaign data from mailing schedule into MDE.")
	print(
		f'Deleting data campaign year = {campaign_year} and campaign number = {campaign_number} completed.')
	rs.close()
	return



def backup_phone_n_mille(campaign_year, campaign_number):
	""" Back up phone and mille """
	print('----')
	print("Backing up phone# and mille from mailing schedule into the helper table.")

	backup_query = f'''
Truncate model.mailing_schedule_agg_helper;


insert into model.mailing_schedule_agg_helper
select distinct
	keycode,
	reporting_group_name,
	phone_number,
	estimated_mille,
	convert_timezone('EST5EDT', getdate()) as inserted_at
from model.mailing_schedule_agg
where campaign_number = {campaign_number }
and campaign_year = {campaign_year}
	'''
	rs = RSConnection()
	rs.execute(backup_query)

	print(f'Completed.')
	rs.close()
	return


def back_fill_existing_phone_num():
	"""Back fill existing data"""


	qry = '''
	update model.mailing_schedule_agg
	set phone_number = model.mailing_schedule_agg_helper.phone_number,
	estimated_mille = model.mailing_schedule_agg_helper.estimated_mille
	from model.mailing_schedule_agg_helper
	where model.mailing_schedule_agg_helper.keycode = model.mailing_schedule_agg.keycode;
	'''

	rs = RSConnection()
	rs.execute(qry)

	print(f'Completed.')
	rs.close()
	return


def insert_into_agg_table(copy_statement):
	"""Insert into RS table"""
	rs = RSConnection()
	rs.execute(copy_statement)
	print('Insertion completed.\n')
	rs.close()
	return

def update_reporting_group(campaign_year, campaign_number):
	"""Update reporting Group in model.mailing_schedule_agg table."""
	qry = f"""
update model.mailing_schedule_agg
set reporting_group_name = x.reporting_group_name
from model.mailing_schedule_agg agg
inner join
(
	SELECT distinct
			agg.campaign_year,
			agg.campaign_number,
			agg.tactic_name,
			agg.company_code,
			agg.states,
			substring(agg.keycode,5,3) as mid_key,
			po.commision_club_cd as club_number,
			case when club_number in ('111', '006')
					then club_number
				 when agg.states = 'NY'
					then 'AANY'
				else po.reporting_group_name end as reporting_group_name
	FROM model.mailing_schedule_agg agg
	left join model.keycode_4_to_10th po
		on po.tactic_name = agg.tactic_name
		and po.st_cd = agg.states
		and po.keycode_positions_5_7 = substring(agg.keycode,5,3)
	where agg.campaign_year = {campaign_year}
	and agg.campaign_number = {campaign_number}
	) x
	on x.tactic_name = agg.tactic_name
	and x.company_code = agg.company_code
	and x.states = agg.states
	and x.mid_key = substring(agg.keycode,5,3)
	and x.campaign_year = agg.campaign_year
	and x.campaign_number = agg.campaign_number
	;
	"""
	rs =RSConnection()
	rs.execute(qry)
	rs.close()

	print('Updating reporting_group_name completed.')
	print('Insertion completed.\n')
	print('---')
	return


def load_mailing_schedule_table(campaign_year, campaign_number ):

	# Pull data from mail schedule from DM1 for the specified campaign and year
	df = get_ms_data_by_campaign_year_num(campaign_year, campaign_number)
	# Save the data frame into the Merkle S3 bucket
	s3_url = store_df_into_s3(df, campaign_year, campaign_number)
	# Assemble a command to copy the data from S3 into the mail schedule aggregate table in MDE
	copy_statement = build_copy_statement(s3_url)
	# Create a backup from the current mail schedule aggregate table into a backup table
	backup_phone_n_mille(campaign_year, campaign_number)
	# Deletes all records from the mail schedule aggregate table matching the campaign number and year
	delete_agg_table(campaign_year, campaign_number)
	# Executes the copy statement from earlier to load the records from the S3 bucket into the table
	insert_into_agg_table(copy_statement)

	update_reporting_group(campaign_year, campaign_number)

	back_fill_existing_phone_num()

	return
