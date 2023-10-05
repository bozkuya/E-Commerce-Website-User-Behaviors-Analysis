WITH PreviousActions AS (
    SELECT 
        user_pseudo_id,
        event_name,
        event_timestamp,
        event_date
    FROM 
        `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
    WHERE 
        event_name IN ('view_item', 'user_engagement', 'add_to_cart')
),

CartActions AS (
    SELECT 
        user_pseudo_id,
        event_timestamp AS cart_timestamp
    FROM 
        `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
    WHERE 
        event_name = 'add_to_cart'
),

FilteredActions AS (
    SELECT 
        p.user_pseudo_id,
        p.event_name,
        p.event_timestamp,
        p.event_date
    FROM 
        PreviousActions p
    JOIN 
        CartActions c
    ON 
        p.user_pseudo_id = c.user_pseudo_id
    WHERE 
        p.event_timestamp <= c.cart_timestamp
),

DesiredPath AS (
    SELECT 
        user_pseudo_id,
        COUNTIF(event_name = 'view_item') AS view_count,
        COUNTIF(event_name = 'user_engagement') AS engagement_count,
        COUNTIF(event_name = 'add_to_cart') AS cart_count
    FROM 
        FilteredActions
    GROUP BY 
        user_pseudo_id
),

SessionData AS (
    SELECT 
        user_pseudo_id,
        event_timestamp,
        LAG(event_timestamp) OVER (PARTITION BY user_pseudo_id ORDER BY event_timestamp) AS prev_timestamp
    FROM
        `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
),

UserMetrics AS (
    SELECT
        e.user_pseudo_id,
        AVG(IFNULL(e.event_timestamp - s.prev_timestamp, 0)) AS avg_session_duration,
        COUNT(DISTINCT e.event_date) AS unique_days,
        COUNT(e.event_name) AS total_events,
        AVG(e.event_value_in_usd) AS avg_spend_per_event,
        ARRAY_AGG(e.event_name ORDER BY e.event_timestamp DESC LIMIT 1)[SAFE_OFFSET(0)] AS most_frequent_event
    FROM 
        `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*` e
    LEFT JOIN 
        SessionData s
    ON 
        e.user_pseudo_id = s.user_pseudo_id
    GROUP BY 
        e.user_pseudo_id
),

LastWeeksActivity AS (
    SELECT
        user_pseudo_id,
        COUNTIF(DATE_DIFF(CURRENT_DATE, PARSE_DATE('%Y%m%d', event_date), DAY) <= 7) AS last_week_activity_count,
        COUNTIF(DATE_DIFF(CURRENT_DATE, PARSE_DATE('%Y%m%d', event_date), DAY) <= 28) AS last_4weeks_activity_count
    FROM 
        `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
    GROUP BY 
        user_pseudo_id
),

DeviceUsage AS (
    SELECT
        user_pseudo_id,
        COUNTIF(device.category = 'mobile') AS mobile_usage_count,
        COUNTIF(device.category = 'desktop') AS desktop_usage_count,
        COUNT(*) AS total_counts
    FROM 
        `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
    GROUP BY 
        user_pseudo_id
),

FeatureData AS (
    SELECT
        m.user_pseudo_id,
        PARSE_DATE('%Y%m%d', event_date) AS date,
        m.avg_session_duration,
        m.unique_days,
        l.last_week_activity_count/m.total_events AS last_week_activity_ratio,
        l.last_4weeks_activity_count/m.total_events AS last_4weeks_activity_ratio,
        m.total_events,
        m.avg_spend_per_event,
        m.most_frequent_event,
        d.mobile_usage_count/d.total_counts AS mobile_usage_ratio,
        d.desktop_usage_count/d.total_counts AS desktop_usage_ratio,
        CASE 
            WHEN dp.view_count > 0 AND dp.engagement_count > 0 AND dp.cart_count > 0 THEN 1
            ELSE 0
        END AS target
    FROM 
        UserMetrics m
    LEFT JOIN 
        DesiredPath dp
    ON 
        m.user_pseudo_id = dp.user_pseudo_id
    LEFT JOIN
        LastWeeksActivity l
    ON
        m.user_pseudo_id = l.user_pseudo_id
    LEFT JOIN
        DeviceUsage d
    ON
        m.user_pseudo_id = d.user_pseudo_id
    JOIN 
        `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*` e
    ON
        e.user_pseudo_id = m.user_pseudo_id
),

WeeklyMetrics AS (
    SELECT
        DATE_TRUNC(date, WEEK(MONDAY)) as week_start,
        AVG(avg_session_duration) as weekly_avg_session_duration,
        AVG(unique_days) as weekly_unique_days,
        AVG(last_week_activity_ratio) as weekly_last_week_activity_ratio,
        AVG(last_4weeks_activity_ratio) as weekly_last_4weeks_activity_ratio,
        AVG(total_events) as weekly_total_events,
        AVG(avg_spend_per_event) as weekly_avg_spend_per_event,
        AVG(mobile_usage_ratio) as weekly_mobile_usage_ratio,
        AVG(desktop_usage_ratio) as weekly_desktop_usage_ratio,
        AVG(target) as weekly_target
    FROM 
        FeatureData
    GROUP BY 
        week_start
    ORDER BY 
        week_start
)

SELECT * FROM WeeklyMetrics;
