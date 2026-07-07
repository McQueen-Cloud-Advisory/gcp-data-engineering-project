with source_data as (
    select *
    from {{ source('raw', 'raw_airline_ontime_performance') }}
)

SELECT
    SAFE_CAST(NULLIF(TRIM(QUARTER), '') AS NUMERIC)                as quarter
    ,SAFE_CAST(NULLIF(TRIM(MONTH), '') AS NUMERIC)                 as month
    ,SAFE_CAST(NULLIF(TRIM(DAY_OF_MONTH), '') AS NUMERIC)          as day_of_month
    ,SAFE_CAST(NULLIF(TRIM(DAY_OF_WEEK), '') AS NUMERIC)           as day_of_week
    ,DATE(
        SAFE.PARSE_DATETIME(
            '%m/%d/%Y %I:%M:%S %p',
            TRIM(FL_DATE)
        )
    ) as fl_date
    ,NULLIF(TRIM(MKT_UNIQUE_CARRIER), '')     as mkt_unique_carrier
    ,SAFE_CAST(NULLIF(TRIM(SCH_OP_CARRIER_FL_NUM), '') AS NUMERIC) as sch_op_carrier_fl_num
    ,NULLIF(TRIM(OP_UNIQUE_CARRIER), '')      as op_unique_carrier
    ,SAFE_CAST(NULLIF(TRIM(ORIGIN_AIRPORT_ID), '') AS NUMERIC)     as origin_airport_id
    ,SAFE_CAST(NULLIF(TRIM(ORIGIN_AIRPORT_SEQ_ID), '') AS NUMERIC) as origin_airport_seq_id
    ,SAFE_CAST(NULLIF(TRIM(ORIGIN_CITY_MARKET_ID), '') AS NUMERIC) as origin_city_market_id
    ,NULLIF(TRIM(ORIGIN), '')                 as origin
    ,NULLIF(TRIM(ORIGIN_CITY_NAME), '')       as origin_city_name
    ,NULLIF(TRIM(ORIGIN_STATE_ABR), '')       as origin_state_abr
    ,NULLIF(TRIM(ORIGIN_STATE_FIPS), '')      as origin_state_fips
    ,NULLIF(TRIM(ORIGIN_STATE_NM), '')        as origin_state_nm
    ,SAFE_CAST(NULLIF(TRIM(ORIGIN_WAC), '') AS NUMERIC)            as origin_wac
    ,SAFE_CAST(NULLIF(TRIM(DEST_AIRPORT_ID), '') AS NUMERIC)       as dest_airport_id
    ,SAFE_CAST(NULLIF(TRIM(DEST_AIRPORT_SEQ_ID), '') AS NUMERIC)   as dest_airport_seq_id
    ,SAFE_CAST(NULLIF(TRIM(DEST_CITY_MARKET_ID), '') AS NUMERIC)   as dest_city_market_id
    ,NULLIF(TRIM(DEST), '')                   as dest
    ,NULLIF(TRIM(DEST_CITY_NAME), '')         as dest_city_name
    ,NULLIF(TRIM(DEST_STATE_ABR), '')         as dest_state_abr
    ,NULLIF(TRIM(DEST_STATE_FIPS), '')        as dest_state_fips
    ,NULLIF(TRIM(DEST_STATE_NM), '')          as dest_state_nm
    ,SAFE_CAST(NULLIF(TRIM(DEST_WAC), '') AS NUMERIC)              as dest_wac
    ,NULLIF(TRIM(CRS_DEP_TIME), '')           as crs_dep_time
    ,NULLIF(TRIM(DEP_TIME), '')               as dep_time
    ,SAFE_CAST(NULLIF(TRIM(DEP_DELAY), '') AS NUMERIC)             as dep_delay
    ,SAFE_CAST(NULLIF(TRIM(DEP_DELAY_NEW), '') AS NUMERIC)         as dep_delay_new
    ,SAFE_CAST(NULLIF(TRIM(DEP_DEL15), '') AS NUMERIC)             as dep_del15
    ,SAFE_CAST(NULLIF(TRIM(DEP_DELAY_GROUP), '') AS NUMERIC)       as dep_delay_group
    ,NULLIF(TRIM(DEP_TIME_BLK), '')           as dep_time_blk
    ,SAFE_CAST(NULLIF(TRIM(TAXI_OUT), '') AS NUMERIC)              as taxi_out
    ,NULLIF(TRIM(WHEELS_OFF), '')             as wheels_off
    ,NULLIF(TRIM(WHEELS_ON), '')              as wheels_on
    ,SAFE_CAST(NULLIF(TRIM(TAXI_IN), '') AS NUMERIC)               as taxi_in
    ,NULLIF(TRIM(CRS_ARR_TIME), '')           as crs_arr_time
    ,NULLIF(TRIM(ARR_TIME), '')               as arr_time
    ,SAFE_CAST(NULLIF(TRIM(ARR_DELAY), '') AS NUMERIC)             as arr_delay
    ,SAFE_CAST(NULLIF(TRIM(ARR_DELAY_NEW), '') AS NUMERIC)         as arr_delay_new
    ,SAFE_CAST(NULLIF(TRIM(ARR_DEL15), '') AS NUMERIC)             as arr_del15
    ,SAFE_CAST(NULLIF(TRIM(ARR_DELAY_GROUP), '') AS NUMERIC)       as arr_delay_group
    ,NULLIF(TRIM(ARR_TIME_BLK), '')           as arr_time_blk
    ,CASE 
        WHEN SAFE_CAST(NULLIF(TRIM(CANCELLED), '') AS NUMERIC) = 1 THEN TRUE 
        WHEN SAFE_CAST(NULLIF(TRIM(CANCELLED), '') AS NUMERIC) = 0 THEN FALSE
        ELSE NULL
    END as is_cancelled
    ,NULLIF(TRIM(CANCELLATION_CODE), '')      as cancellation_code
    ,CASE 
        WHEN SAFE_CAST(NULLIF(TRIM(DIVERTED), '') AS NUMERIC) = 1 THEN TRUE
        WHEN SAFE_CAST(NULLIF(TRIM(DIVERTED), '') AS NUMERIC) = 0 THEN FALSE
        ELSE NULL
    END as is_diverted
    ,NULLIF(TRIM(DUP), '')                    as dup
    ,SAFE_CAST(NULLIF(TRIM(CRS_ELAPSED_TIME), '') AS NUMERIC)      as crs_elapsed_time
    ,SAFE_CAST(NULLIF(TRIM(ACTUAL_ELAPSED_TIME), '') AS NUMERIC)   as actual_elapsed_time
    ,SAFE_CAST(NULLIF(TRIM(AIR_TIME), '') AS NUMERIC)              as air_time
    ,SAFE_CAST(NULLIF(TRIM(FLIGHTS), '') AS NUMERIC)               as flights
    ,SAFE_CAST(NULLIF(TRIM(DISTANCE), '') AS NUMERIC)              as distance
    ,SAFE_CAST(NULLIF(TRIM(DISTANCE_GROUP), '') AS NUMERIC)        as distance_group
    ,SAFE_CAST(NULLIF(TRIM(CARRIER_DELAY), '') AS NUMERIC)         as carrier_delay
    ,SAFE_CAST(NULLIF(TRIM(WEATHER_DELAY), '') AS NUMERIC)         as weather_delay
    ,SAFE_CAST(NULLIF(TRIM(NAS_DELAY), '') AS NUMERIC)             as nas_delay
    ,SAFE_CAST(NULLIF(TRIM(SECURITY_DELAY), '') AS NUMERIC)        as security_delay
    ,NULLIF(TRIM(FIRST_DEP_TIME), '')         as first_dep_time
    ,SAFE_CAST(NULLIF(TRIM(TOTAL_ADD_GTIME), '') AS NUMERIC)       as total_add_gtime
    ,SAFE_CAST(NULLIF(TRIM(LONGEST_ADD_GTIME), '') AS NUMERIC)     as longest_add_gtime
    ,SAFE_CAST(NULLIF(TRIM(DIV_AIRPORT_LANDINGS), '') AS NUMERIC)  as div_airport_landings

FROM source_data