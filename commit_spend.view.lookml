explore: partner_and_commit_spend {}
include: "/views/gcp_billing_export.view.lkml"
view: partner_and_commit_spend {
  sql_table_name: `cmegroup-billing-export.migration_model.partner_and_commit_spend`
    ;;

  dimension: actual_spend {
    type: number
    hidden: yes
    value_format_name: usd_0
    label: "Partner Spend"
    sql: ${TABLE}.actual_spend ;;
  }
  measure: sum_spend {
    type: sum
    label: "Total Partner Spend"
    value_format_name: usd_0
    sql:${actual_spend} ;;
  }

  measure: partner_spend {
    type: running_total
    label: "Running Total Partner Spend"
    value_format_name: usd_0
    sql:${sum_spend} ;;
  }

  dimension: commit_size {
    type: number
    sql: ${TABLE}.commit_size ;;
  }

  dimension: cumulative_forecast {
    type: number
    sql: ${TABLE}.cumulative_forecast ;;
  }

  measure: marketplace_forecast {
    hidden: yes
    type: sum
    sql: ${TABLE}.marketplace_forecast ;;
  }

  measure: partner_forecast {
    hidden: yes
    type: sum
    sql: ${TABLE}.partner_forecast ;;
  }

  measure: marketplace_forecast_running_total {
    type: running_total
    label: "Marketplace Forecast"
    sql: ${marketplace_forecast} ;;
    value_format_name: usd_0
  }

  measure: partner_forecast_running_total {
    type: running_total
    label: "Partner Forecast"
    sql: ${partner_forecast} ;;
    value_format_name: usd_0
  }

  dimension: pk {
    primary_key: yes
    type: string
    sql: CONCAT(${month_month}, ${commit_size}, ${actual_spend}) ;;
  }

  dimension_group: month {
    type: time
    label: "Forecast"
    timeframes: [
      date,
      month,
      quarter,
      year
    ]
    convert_tz: no
    datatype: date
    sql: ${TABLE}.month ;;
  }

  dimension: product {
    type: string
    sql: ${TABLE}.Product ;;
  }

  dimension: provider {
    type: string
    sql: ${TABLE}.Provider ;;
  }

  measure: count {
    type: count
    drill_fields: []
  }

  measure: total_forecast {
    type: max
    value_format_name: usd_0
    sql: ${cumulative_forecast} ;;
  }
}
