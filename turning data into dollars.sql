---Inspecting Data
select 
  * 
from 
  [dbo].[sales_data_sample] 

select 
  distinct status 
from 
  [dbo].[sales_data_sample] 
select 
  distinct YEAR_ID 
from 
  [dbo].[sales_data_sample] 
select 
  distinct PRODUCTLINE 
from 
  [dbo].[sales_data_sample] 
select 
  distinct COUNTRY 
from 
  [dbo].[sales_data_sample] 
select 
  distinct DEALSIZE 
from 
  [dbo].[sales_data_sample] 
select 
  distinct TERRITORY 
from 
  [dbo].[sales_data_sample] 
select 
  distinct MONTH_ID 
from 
  [dbo].[sales_data_sample] 
where 
  YEAR_ID = 2005 ---ANALYSIS
  -------Let's start by grouping sales by productline
select 
  PRODUCTLINE, 
  sum(sales) Revenue 
from 
  [dbo].[sales_data_sample] 
group by 
  PRODUCTLINE 
order by 
  2 desc 
select 
  YEAR_ID, 
  sum(sales) Revenue 
from 
  [dbo].[sales_data_sample] 
group by 
  YEAR_ID 
order by 
  2 desc 
select 
  DEALSIZE, 
  sum(sales) Revenue 
from 
  [dbo].[sales_data_sample] 
group by 
  DEALSIZE 
order by 
  2 desc -----What was the best month for sales in a specific year
select 
  MONTH_ID, 
  sum(sales) Revenue, 
  count(ORDERNUMBER) Frequency 
from 
  [dbo].[sales_data_sample] 
Where 
  YEAR_ID = 2003 --Change year to see the rest
group by 
  MONTH_ID 
Order by 
  2 desc ----November seems to the best month, what products do they sell in November
select 
  MONTH_ID, 
  PRODUCTLINE, 
  SUM(sales) Revenue, 
  count(ORDERNUMBER) FREQUENCY 
from 
  [dbo].[sales_data_sample] 
Where 
  YEAR_ID = 2003 
  and MONTH_ID = 11 --Change year to see the rest
group by 
  MONTH_ID, 
  PRODUCTLINE 
order by 
  3 desc 
---- Who is our best customer (this could be answered with RFM)
DROP 
  TABLE IF EXISTS #rfm
  ;
with rfm as (
  select 
    CUSTOMERNAME, 
    sum(sales) Monetaryvalue, 
    avg(sales) AvgMonetaryValue, 
    count(ORDERNUMBER) FREQUENCY, 
    max(ORDERDATE) last_order_date, 
    (
      Select 
        max(ORDERDATE) 
      from 
        [dbo].[sales_data_sample]
    ) max_order_date, 
    DATEDIFF(
      DD, 
      max(ORDERDATE), 
      (
        select 
          max(ORDERDATE) 
        from 
          [dbo].[sales_data_sample]
      )
    ) Recency 
  from 
    [PortfolioProject].[dbo].[sales_data_sample] 
  group by 
    CUSTOMERNAME
), 
rfm_calc as (
  select 
    r.*, 
    NTILE(4) OVER (
      order by 
        Recency desc
    ) rfm_recency, 
    NTILE(4) OVER (
      order by 
        Frequency
    ) rfm_Frequency, 
    NTILE(4) OVER (
      order by 
        MonetaryValue
    ) rfm_monetary 
  from 
    rfm r
) 
select 
  c.*, 
  rfm_recency + rfm_Frequency + rfm_monetary as rfm_cell, 
  cast(rfm_recency as varchar)+ cast(rfm_Frequency as varchar)+ cast (rfm_monetary as varchar) rfm_cell_string into #rfm  
from 
  rfm_calc c 
select 
  CUSTOMERNAME, 
  rfm_recency, 
  rfm_Frequency, 
  rfm_monetary, 
  case when rfm_cell_string in (
    111, 112, 121, 122, 123, 132, 211, 212, 
    114, 141
  ) then 'lost customers' ---lost customers
  when rfm_cell_string in (
    133, 134, 143, 244, 334, 343, 344, 144
  ) then 'slipping away,cannot lose' ---Big spenders who havent purchased lately
  when rfm_cell_string in (311, 411, 331) then 'new customers'
  when rfm_cell_string in (222, 223, 233, 322) then 'potential customers' 
  when rfm_cell_string in (323, 333, 321, 422, 332, 432) then 'active' ---(customers who buy often & recently, but at low price points)
  when rfm_cell_string in (433, 434, 443, 444) then 'loyal' end rfm_segment 
from 
  #rfm
  --  what products are most often sold together?
  --select* from [PortfolioProject].[dbo].[sales_data_sample] where ORDERNUMBER = 10411
select 
  distinct OrderNumber, 
  stuff(
    (
      select 
        ',' + PRODUCTCODE 
      from 
        [dbo].[sales_data_sample] p 
      where 
        ORDERNUMBER in (
          select 
            ORDERNUMBER 
          FROM 
            (
              select 
                ORDERNUMBER, 
                count(*) rn 
              from 
                [PortfolioProject].[dbo].[sales_data_sample] 
              where 
                STATUS = 'Shipped' 
              group by 
                ORDERNUMBER
            ) m 
          where 
            rn = 3
        ) 
        and p.ORDERNUMBER = s.ORDERNUMBER for xml path ('')
    ), 
    1, 
    1, 
    ''
  ) ProductCodes 
from 
  [dbo].[sales_data_sample] s 
order by 
  2 desc
