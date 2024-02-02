explore: allocated_costs {
  join: total_usage {
    type: left_outer
    relationship: many_to_one
    sql_on: ${allocated_costs.usage_start_date}=${total_usage.usage_start_date} ;;
  }
  join: total_cost {
    type: left_outer
    relationship: many_to_one
    sql_on: ${allocated_costs.usage_start_date} = ${total_cost.usage_start_date} ;;
  }

}
view: allocated_costs {
  derived_table: {
    explore_source: gcp_billing_export {
      column: project__name {}
      #column: usage__amount_in_calculated_units {}
      column: sku__description {}
      #column: total_usage_amount_in_pricing_units {}
      column: total_usage_amount {}
      column: total_net_cost {}
      column: usage_start_date {}
      #column: usage__calculated_unit {}
      #column: usage__pricing_unit {}
      #column: usage__unit {}
      filters: {
        field: gcp_billing_export.project__name
        value: "cmegroup-billing-export,poc-gia-2034083092,prj-dv-proc-bizanlyt-d1ef,prj-dv-proc-dora-e34e,prj-dv-proc-ext-267a,prj-dv-proc-extdata-4bc3,
        prj-dv-proc-mkda-554b,prj-dv-proc-mmrincen-03e2,prj-dv-proc-orderentry-4290,prj-dv-proc-post-trade-8bfe,prj-pr-proc-marketdata-16fa,
        prj-pr-proc-post-trd-e4e2,prj-qa-proc-ext-f8a7,prj-qa-proc-extdata-b8ad,prj-ut-proc-marketdata-219b,prj-ss-bqresvtn-4645"
      }
      filters: {
        field: gcp_billing_export.usage_start_date
        value: "2023/05/21"
      }
      filters: {
        field: gcp_billing_export.sku__description
        value: "Analysis Slots Attribution"
      }
    }
  }
  dimension: project__name {
    label: "Shared Project Name"
    description: ""
  }
  # dimension: usage__amount_in_calculated_units {
  #   label: "Usage Amount In Calculated Units"
  #   description: ""
  #   value_format: "#,##0"
  #   type: number
  # }
  dimension: sku__description {
    label: "Shared SKU Description"
    description: ""
  }
  # dimension: total_usage_amount_in_pricing_units {
  #   label: "Total Usage Amount In Pricing Units"
  #   description: ""
  #   value_format_name: decimal_0
  #   type: number
  # }
  dimension: total_usage_amount {
    label: "Total Usage Amount"
    description: ""
    value_format_name: decimal_0
    type: number
  }

  measure: total_usage {
    type: sum_distinct
    value_format_name: decimal_0
    sql_distinct_key: ${project__name} ;;
    sql: ${total_usage_amount} ;;
  }

  # dimension: total_net_cost {
  #   label: " Total Net Cost"
  #   description: ""
  #   value_format: "$#,##0"
  #   type: number
  # }
  # dimension: usage__calculated_unit {
  #   label: "Usage Calculated Unit"
  #   description: ""
  # }
  # dimension: usage__pricing_unit {
  #   label: "Billing Usage Pricing Unit"
  #   description: ""
  # }
  # dimension: usage__unit {
  #   label: "Usage Unit"
  #   description: ""
  # }
  dimension: usage_start_date {
    label: "Usage Start Date"
    description: ""
    type: date
  }
  dimension: percentage_usage {
    type: number
    value_format_name: percent_0
    sql: ${total_usage_amount}/${total_usage.total_usage_amount} ;;
  }
  dimension: percentage_of_cost {
    label: "Cost by Usage Amount"
    type: number
    value_format_name: usd
    sql: ${percentage_usage}*${total_cost.total_net_cost}  ;;
  }
  measure: cost_by_usage {
    type: sum_distinct
    sql_distinct_key: ${project__name} ;;
    value_format_name: usd
    sql: ${percentage_of_cost} ;;
  }
}

view: total_usage {
  derived_table: {
    explore_source: gcp_billing_export {
      column: total_usage_amount {}
      column: usage_start_date {}
      filters: {
        field: gcp_billing_export.sku__description
        value: "Analysis Slots Attribution"
      }
      filters: {
        field: gcp_billing_export.usage_start_date
        value: "2023/05/21"
      }
      filters: {
        field: gcp_billing_export.project__name
        value: "poc-gia-2034083092,prj-dv-proc-bizanlyt-d1ef,prj-dv-proc-dora-e34e,prj-dv-proc-ext-267a,prj-dv-proc-extdata-4bc3,prj-dv-proc-mkda-554b,
        prj-dv-proc-mmrincen-03e2,prj-dv-proc-orderentry-4290,prj-dv-proc-post-trade-8bfe,prj-pr-proc-marketdata-16fa,prj-pr-proc-post-trd-e4e2,
        prj-qa-proc-ext-f8a7,prj-qa-proc-extdata-b8ad,prj-ut-proc-marketdata-219b,cmegroup-billing-export,prj-ss-bqresvtn-4645"
      }
    }
  }
  dimension: total_usage_amount {
    label: "Billing Total Usage Amount"
    description: ""
    value_format_name: decimal_0
    type: number
  }
  dimension: usage_start_date {
    label: "Billing Usage Start Date"
    description: ""
    type: date
  }
}

view: total_cost {
  derived_table: {
    explore_source: gcp_billing_export {
      #column: total_usage_amount {}
      column: usage_start_date {}
      column: project__name {}
      column: total_net_cost {}
      column: sku__description {}
      filters: {
        field: gcp_billing_export.sku__description
        value: "BigQuery Enterprise Edition for US (multi-region)"
      }
      filters: {
        field: gcp_billing_export.project__name
        value: "prj-ss-bqresvtn-4645"
      }
      filters: {
        field: gcp_billing_export.usage_start_date
        value: "2023/05/21"
      }
    }
  }
  # dimension: total_usage_amount {
  #   label: "Billing Total Usage Amount"
  #   hidden: yes
  #   value_format_name: decimal_0
  #   type: number
  # }
  dimension: usage_start_date {
    label: "Billing Usage Start Date"
    type: date
  }
  dimension: total_net_cost {
    label: "Billing Total Net Cost"
    value_format: "$#,##0"
    type: number
  }
  dimension: project__name {
    label: "Shared Cost Project Name"
  }
  dimension: sku__description {
    label: "Billing SKU Description"
  }
}

explore: total_cost {
  hidden: yes
}
