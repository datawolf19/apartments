select * from apartment_attrs



CREATE OR REPLACE VIEW housing.cv_apt_attr_data
AS WITH apt_calcs AS (
         SELECT t1.id,
            t1.name,
            t1.floor_plan,
            t1.advertised_sqft,
            t1.rent,
            t1.date,
            t1.unit,
            t1.source,
            t2.area,
            t2.city,
            t2.length,
            t2.width,
            sum(t2.width / 12::numeric * t2.length / 12::numeric) OVER (PARTITION BY t1.date, t1.unit ORDER BY t1.unit) AS actual_sqft,
            sum(t2.width / 12::numeric * t2.length / 12::numeric) OVER (PARTITION BY t1.date, t1.unit, t2.area ORDER BY t1.unit) AS area_sqft
           FROM cv_apt t1
             LEFT JOIN apartment_attrs t2 ON t1.id = t2.id
          ORDER BY t1.date, t1.unit
        ), 
        
        unallocated_sqft AS (
        
        SELECT 
        'unallocated' area,	
        sqrt(t1.advertised_sqft - (sum(t2.width / 12::numeric * t2.length / 12::numeric) OVER (PARTITION BY t1.id, t1.date, t1.unit, t1.floor_plan, t1.move_in_date ORDER BY t1.unit))) width,
        sqrt(t1.advertised_sqft - (sum(t2.width / 12::numeric * t2.length / 12::numeric) OVER (PARTITION BY t1.id, t1.date, t1.unit, t1.floor_plan, t1.move_in_date ORDER BY t1.unit))) length,

		t2.city,
        t2.id,
        t2.floor_plan
           FROM cv_apt t1
             LEFT JOIN (SELECT * FROM apartment_attrs t2 WHERE area != 'unallocated') t2
             	ON t1.id = t2.id
             	AND t1.floor_plan = t2.floor_plan
          
			where t1.id = 1          
          ORDER BY t1.date, t1.unit
          
        )
        
        
        
        
        pct_sqft AS (
         SELECT apt_calcs.id,
            apt_calcs.name,
            apt_calcs.floor_plan,
            apt_calcs.advertised_sqft,
            apt_calcs.rent,
            apt_calcs.date,
            apt_calcs.unit,
            apt_calcs.source,
            apt_calcs.area,
            apt_calcs.city,
            apt_calcs.length,
            apt_calcs.width,
            apt_calcs.actual_sqft,
            apt_calcs.area_sqft,
            
            apt_calcs.area_sqft / apt_calcs.actual_sqft AS area_usage
           FROM apt_calcs
        )
 SELECT pct_sqft.id,
    pct_sqft.name,
    pct_sqft.floor_plan,
    pct_sqft.advertised_sqft,
    pct_sqft.rent,
    pct_sqft.date,
    pct_sqft.unit,
    pct_sqft.source,
    pct_sqft.area,
    pct_sqft.city,
    pct_sqft.length,
    pct_sqft.width,
    pct_sqft.actual_sqft,
    pct_sqft.area_sqft,
    pct_sqft.area_usage
   FROM pct_sqft;