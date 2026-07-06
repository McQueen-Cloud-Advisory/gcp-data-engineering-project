with source_data as (
    select *
    from {{ source('raw', 'raw_airline_ontime_performance') }}
)

SELECT
    CAST(QUARTER AS INTEGER)          as quarter
    CAST(MONTH AS INTEGER)            as month
    CAST(DAY_OF_MONTH AS INTEGER)     as day_of_month
    CAST(DAY_OF_WEEK AS INTEGER)      as day_of_week
    DATE(CAST(FL_DATE AS TIMESTAMP))  as fl_date
    CAST(MKT_UNIQUE_CARRIER AS STRING)      as mkt_unique_carrier
    CAST(SCH_OP_CARRIER_FL_NUM AS INTEGER)   as sch_op_carrier_fl_num
    CAST(OP_UNIQUE_CARRIER AS STRING)       as op_unique_carrier
    CAST(ORIGIN_AIRPORT_ID AS STRING)       as origin_airport_id
    CAST(ORIGIN_AIRPORT_SEQ_ID AS STRING)   as origin_airport_seq_id
    CAST(ORIGIN_CITY_MARKET_ID AS STRING)   as origin_city_market_id
    CAST(ORIGIN AS STRING)                  as origin
    CAST(ORIGIN_CITY_NAME AS STRING)        as origin_city_name
    CAST(ORIGIN_STATE_ABR AS STRING)        as origin_state_abr
    CAST(ORIGIN_STATE_FIPS AS STRING)       as origin_state_fips
    CAST(ORIGIN_STATE_NM AS STRING)         as origin_state_nm
    CAST(ORIGIN_WAC AS STRING)              as origin_wac
    CAST(DEST_AIRPORT_ID AS STRING)         as dest_airport_id
    CAST(DEST_AIRPORT_SEQ_ID AS STRING)     as dest_airport_seq_id
    CAST(DEST_CITY_MARKET_ID AS STRING)     as dest_city_market_id
    CAST(DEST AS STRING)                    as dest
    CAST(DEST_CITY_NAME AS STRING)          as dest_city_name
    CAST(DEST_STATE_ABR AS STRING)         as dest_state_abr
    CAST(DEST_STATE_FIPS AS STRING)        as dest_state_fips
    CAST(DEST_STATE_NM AS STRING)          as dest_state_nm
    CAST(DEST_WAC AS STRING)               as dest_wac
    CAST(CRS_DEP_TIME AS STRING)           as crs_dep_time
    CAST(DEP_TIME AS STRING)               as dep_time
    CAST(DEP_DELAY AS STRING)              as dep_delay
    CAST(DEP_DELAY_NEW AS STRING)          as dep_delay_new
    CAST(DEP_DEL15 AS STRING)              as dep_del15
    CAST(DEP_DELAY_GROUP AS STRING)        as dep_delay_group
    CAST(DEP_TIME_BLK AS STRING)           as dep_time_blk
    CAST(WHEELS_OFF AS STRING)             as wheels_off
    CAST(WHEELS_ON AS STRING)              as wheels_on
    CAST(TAXI_IN AS STRING)                as taxi_in
    CAST(CRS_ARR_TIME AS STRING)           as crs_arr_time
    CAST(ARR_TIME AS STRING)               as arr_time
    CAST(ARR_DELAY AS STRING)              as arr_delay
    CAST(ARR_DELAY_NEW AS STRING)          as arr_delay_new
    CAST(ARR_DEL15 AS STRING)              as arr_del15
    CAST(ARR_DELAY_GROUP AS STRING)        as arr_delay_group
    CAST(ARR_TIME_BLK AS STRING)           as arr_time_blk
    CAST(CANCELLED AS STRING)              as cancelled
    CAST(CANCELLATION_CODE AS STRING)      as cancellation_code
    CAST(DIVERTED AS STRING)               as diverted
    CAST(DUP AS STRING)                    as dup
    CAST(CRS_ELAPSED_TIME AS STRING)        as crs_elapsed_time
    CAST(ACTUAL_ELAPSED_TIME AS STRING)     as actual_elapsed_time
    CAST(AIR_TIME AS STRING)                as air_time
    CAST(FLIGHTS AS STRING)                 as flights
    CAST(DISTANCE AS STRING)                as distance
    CAST(DISTANCE_GROUP AS STRING)          as distance_group
    CAST(CARRIER_DELAY AS STRING)           as carrier_delay
    CAST(WEATHER_DELAY AS STRING)           as weather_delay
    CAST(NAS_DELAY AS STRING)               as nas_delay
    CAST(SECURITY_DELAY AS STRING)          as security_delay
    CAST(FIRST_DEP_TIME AS STRING)          as first_dep_time
    CAST(TOTAL_ADD_GTIME AS STRING)         as total_add_gtime
    CAST(LONGEST_ADD_GTIME AS STRING)       as longest_add_gtime
    CAST(DIV_AIRPORT_LANDINGS AS STRING)    as div_airport_landings
FROM source_data