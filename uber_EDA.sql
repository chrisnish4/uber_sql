select count(*)
from uber.import 

select count(distinct MyUnknownColumn)
from uber.import; -- All are distinct 

select * 
from uber.import
limit 10;

-- Finding all rides with no location data: 3587 records
select count(*)
from uber.import
where
	pickup_longitude=0
	and pickup_latitude=0
    and dropoff_longitude=0
    and dropoff_latitude=0
;

-- eliminating UTC to convert to datetime 
select cast(left(pickup_datetime, 19) as datetime)
from uber.import
limit 10;


drop table if exists uber.data; 
create table uber.data as 
select MyUnknownColumn as idx 
	,cast(left(pickup_datetime, 19) as datetime) as pickup_datetime
    ,passenger_count
    ,fare_amount
    ,pickup_longitude 
    ,pickup_latitude 
    ,dropoff_longitude 
    ,dropoff_latitude
from uber.import;

select passenger_count, count(*)
from uber.data
group by 1
order by 2 desc;
-- Single rider is most popular, followed by 2, 5, 3, 4, 6, 0. 208 has a ct of 1, seems to be an error 

select min(fare_amount)
	, max(fare_amount)
    , avg(fare_amount)
from uber.data;
-- min is -52 (refund?), max is 499, avg is 11.36

select *
from uber.data
where fare_amount < 0;
-- Seem to be refunds 

select min(fare_amount)
	, max(fare_amount)
    , avg(fare_amount)
from uber.data
where fare_amount >= 0;
-- values are same, except min which is 0

select *
from uber.data
where fare_amount=0;
-- when fare = 0 Seems to be cancellations, 5 instances 

with cte as (
select case when passenger_count > 4 then 1 else 0
    end as uber_xl
    , case when passenger_count <= 4 then 1 else 0 
    end as uber_x
from uber.data
)
select sum(uber_xl), sum(uber_x)
from cte
-- 181,718 uber X, 18,281 uber XL 

select *
from uber.data
limit 10;

select hour(pickup_datetime), count(*)
from uber.data
group by 1
order by 2 desc;
-- Top 5 hours: 7pm, 6pm, 8pm, 9pm, 10pm

select weekday(date(pickup_datetime)), count(*)
from uber.data
group by 1
order by 2 desc;
-- Most popular days in desc order: thurs, fri, wed, tues, mon, sat, sun

select weekday(date(pickup_datetime))
	, hour(pickup_datetime)
    , count(*)
from uber.data
group by 1, 2
order by 3 desc
limit 5;
-- Top 5 day of week and hour combinations in UTC: Thurs@7pm, Wed@7pm, Tues@7pm, Wed@8pm, Wed@9pm UTC
-- In local time EST: Thurs@2pm, Wed@2pm, Tues@2pm, Wed@3pm, Wed@4pm EST 


-- Trying to find area of operation by finding extreme pickup and dropoff locations 
with cte as ( 
select pickup_longitude
	, pickup_latitude
    , dropoff_longitude
    , dropoff_latitude
    , rank() over (order by pickup_longitude desc) as max_pickup_lon
    , rank() over (order by pickup_longitude asc) as min_pickup_lon
    , rank() over (order by pickup_latitude desc) as max_pickup_lat
    , rank() over (order by pickup_latitude asc) as min_pickup_lat
    , rank() over (order by dropoff_longitude desc) as max_dropoff_lon
    , rank() over (order by dropoff_longitude asc) as min_dropoff_lon
    , rank() over (order by dropoff_latitude desc) as max_dropoff_lat
    , rank() over (order by dropoff_latitude asc) as min_dropoff_lat
from uber.data
where pickup_longitude between -180 and 180
	and dropoff_longitude between -180 and 180
    and pickup_latitude between -90 and 90
    and dropoff_latitude between -90 and 90
)
select * 
from cte 
where max_pickup_lon = 1
	or min_pickup_lon = 1
    or max_pickup_lat = 1
    or min_pickup_lat = 1
    or max_dropoff_lon = 1
    or min_dropoff_lon = 1
    or max_dropoff_lat = 1
    or min_dropoff_lat = 1
;
-- min dropoff lat: Lenox hill --> battery park 
-- min pick up lat: 

select *
from uber.data
limit 100;