#connection: "cmegroup-billing-export-bq-sa-finops"
connection: "looker-bq-sa-finops"
label: "Google Cloud Billing"
persist_with: daily_datagroup
include: "/datagroups.lkml"
include: "/views/*.view.lkml"
include: "/views/migration_model/*.view.lkml"
include: "/anomaly_detection/explores/**/*"

explore: gcp_billing_export {
  label: "Billing"
  hidden: no
  join: gcp_billing_export__labels {
    sql:LEFT JOIN UNNEST(${gcp_billing_export.labels}) as gcp_billing_export__labels ;;
    relationship: one_to_many
  }

  join: gcp_billing_export__system_labels {
    sql:LEFT JOIN UNNEST(${gcp_billing_export.system_labels}) as gcp_billing_export__system_labels ;;
    relationship: one_to_many
  }

  join: gcp_billing_export__project__labels {
    sql:LEFT JOIN UNNEST(${gcp_billing_export.project__labels}) as gcp_billing_export__project__labels ;;
    relationship: one_to_many
  }

  join: gcp_billing_export__credits {
    sql:LEFT JOIN UNNEST(${gcp_billing_export.credits}) as gcp_billing_export__credits ;;
    relationship: one_to_many
  }

  join: pricing {
    relationship: many_to_many
    sql_on: ${pricing.sku__id} = ${gcp_billing_export.sku__id} ;;
  }

  join: billing_lookup {
    type: left_outer
    relationship: many_to_one
    sql_on: ${billing_lookup.sku_id} = ${gcp_billing_export.sku__id} ;;
  }

  join: applications {
    type:  left_outer
    relationship:  one_to_one
    sql_on: ${gcp_billing_export.app_id_with_unallocated_and_k8} = cast(${applications.app_portfolio_id_numeric} as string) ;;
  }

  join: application_domains {
    type:  left_outer
    relationship:  one_to_one
    sql_on: ${gcp_billing_export.app_id_with_unallocated_and_k8} = cast(${application_domains.app_portfolio_id_numeric} as string) ;;
  }

  join: deployable_components {
    type:  left_outer
    relationship:  many_to_one
    sql_on:  ${gcp_billing_export.component_id_upper} = ${deployable_components.deployable_component_id} ;;
  }

  join: eligible_labels {
    type:  left_outer
    view_label: "Billing"
    fields: [eligible_labels.labeling_supported]
    relationship:  one_to_one
    sql_on:  ${gcp_billing_export.service__id} = ${eligible_labels.service_id} ;;
  }

  join: pricing_mapping {
    type: left_outer
    view_label: "Pricing Taxonomy"
    relationship: many_to_many
    fields: [pricing_mapping.marketplace_purchase]
    sql_on: ${pricing_mapping.sku__id} = ${gcp_billing_export.sku__id} ;;
  }

  #Jonathan Morley - Used to join forecasts with billing (WIP)
  join: forecasts {
    type:  full_outer
    #Sidney Stefani - Updated to one to one relationship...
    relationship:  one_to_one
    #Sidney Stefani - Mapped to label instead of deployable components
    sql_on:  ${gcp_billing_export.cme_project_id_upper} = ${forecasts.move_group} and
      ${gcp_billing_export.component_id_upper} = ${forecasts.component_id} ;;
  }

  #jm added 2/10 to support business objects FINOPS-74
  join: business_objects {
    type:  left_outer
    view_label: "Business Objects"
    relationship:  many_to_one
    sql_on: ${gcp_billing_export.business_object_id} = ${business_objects.bo_id};;
  }

  #rishi ghai - 3/21/2023 - Added Product Forecasting and Financial forecasting data
  join: product_forecasting_2023 {
    type: full_outer
    view_label: "Product Forecasting 2023"
    relationship: many_to_many
    sql_on: ${gcp_billing_export.app_id_resource} = ${product_forecasting_2023.app_id} and
            ${gcp_billing_export.service__description} = ${product_forecasting_2023.service} and
            ${gcp_billing_export.invoice_month_month} = ${product_forecasting_2023.date_month};;
  }

  join: gcp_financial_forecasting_2023 {
    type: full_outer
    view_label: "Financial Forecasting 2023"
    relationship: many_to_many
    sql_on: ${gcp_billing_export.app_id_resource} = ${gcp_financial_forecasting_2023.app_id} and
      ${gcp_billing_export.invoice_month_month} = ${gcp_financial_forecasting_2023.date_month} and
      ${gcp_billing_export.service_cost_category} = ${gcp_financial_forecasting_2023.cost_category} ;;
  }
}


########## AGG AWARENESS #############

#Product Forecasting Dashboard
explore: +gcp_billing_export {
  aggregate_table: rollup__product_forecasting_2023_application_id__product_forecasting_2023_application_name__0 {
    query: {
      dimensions: [product_forecasting_2023.application_id, product_forecasting_2023.application_name]
      measures: [product_forecasting_2023.sum_projected_monthly_cost]
      filters: [
        # "product_forecasting_2023.date_month" was filtered by dashboard. The aggregate table will only optimize against exact match queries.
        product_forecasting_2023.date_month: "2023-05"
      ]
      timezone: "America/Los_Angeles"
    }

    materialization: {
      datagroup_trigger: daily_datagroup
    }
  }

  # aggregate_table: rollup__app_id_resource__product_forecasting_2023_app_id__product_forecasting_2023_application_id__product_forecasting_2023_application_name {
  #   query: {
  #     dimensions: [app_id_resource, product_forecasting_2023.app_id, product_forecasting_2023.application_id, product_forecasting_2023.application_name]
  #     measures: [product_forecasting_2023.sum_projected_monthly_cost, total_cost, total_net_cost]
  #     filters: [
  #       gcp_billing_export.app_id_resource: "-NULL",
  #       # "product_forecasting_2023.date_month" was filtered by dashboard. The aggregate table will only optimize against exact match queries.
  #       product_forecasting_2023.date_month: "2023-05"
  #     ]
  #     timezone: "America/Los_Angeles"
  #   }

  #   materialization: {
  #     datagroup_trigger: daily_datagroup
  #   }
  # }

  aggregate_table: rollup__product_forecasting_2023_service__2 {
    query: {
      dimensions: [product_forecasting_2023.service]
      measures: [product_forecasting_2023.sum_projected_monthly_cost]
      filters: [
        # "product_forecasting_2023.date_month" was filtered by dashboard. The aggregate table will only optimize against exact match queries.
        product_forecasting_2023.date_month: "2023-05",
        product_forecasting_2023.service: "-NULL"
      ]
      timezone: "America/Los_Angeles"
    }

    materialization: {
      datagroup_trigger: daily_datagroup
    }
  }

  # aggregate_table: rollup__product_forecasting_2023_date_month__3 {
  #   query: {
  #     dimensions: [product_forecasting_2023.date_month]
  #     measures: [product_forecasting_2023.sum_projected_monthly_cost]
  #     filters: [product_forecasting_2023.date_month: "NOT NULL"]
  #     timezone: "America/Los_Angeles"
  #   }

  #   materialization: {
  #     datagroup_trigger: daily_datagroup
  #   }
  # }

  aggregate_table: rollup__product_forecasting_2023_sum_projected_monthly_cost__total_cost__4 {
    query: {
      measures: [product_forecasting_2023.sum_projected_monthly_cost, total_cost]
      filters: [
        eligible_labels.labeling_supported: "Yes",
        # "product_forecasting_2023.date_month" was filtered by dashboard. The aggregate table will only optimize against exact match queries.
        product_forecasting_2023.date_month: "2023-05"
      ]
      timezone: "America/Los_Angeles"
    }

    materialization: {
      datagroup_trigger: daily_datagroup
    }
  }

  aggregate_table: rollup__product_forecasting_2023_sum_projected_monthly_cost__total_cost__5 {
    query: {
      measures: [product_forecasting_2023.sum_projected_monthly_cost, total_cost]
      filters: [
        eligible_labels.labeling_supported: "Yes",
        # "product_forecasting_2023.date_month" was filtered by dashboard. The aggregate table will only optimize against exact match queries.
        product_forecasting_2023.date_month: "2023-05",
        product_forecasting_2023.service: "-NULL"
      ]
      timezone: "America/Los_Angeles"
    }

    materialization: {
      datagroup_trigger: daily_datagroup
    }
  }

  aggregate_table: rollup__product_forecasting_2023_sum_projected_monthly_cost__total_cost__6 {
    query: {
      measures: [product_forecasting_2023.sum_projected_monthly_cost, total_cost]
      filters: [
        eligible_labels.labeling_supported: "Yes",
        gcp_billing_export.environment_shortname: "Prod",
        # "product_forecasting_2023.date_month" was filtered by dashboard. The aggregate table will only optimize against exact match queries.
        product_forecasting_2023.date_month: "2023-05"
      ]
      timezone: "America/Los_Angeles"
    }

    materialization: {
      datagroup_trigger: daily_datagroup
    }
  }
}

#Financial Forecasting Dashboard
explore: +gcp_billing_export {
  aggregate_table: rollup__gcp_financial_forecasting_2023_date_month__0 {
    query: {
      dimensions: [gcp_financial_forecasting_2023.date_month]
      measures: [gcp_financial_forecasting_2023.monthly_forecast]
      timezone: "America/Los_Angeles"
    }

    materialization: {
      datagroup_trigger: daily_datagroup
    }
  }

  aggregate_table: rollup__gcp_financial_forecasting_2023_app_id__gcp_financial_forecasting_2023_application_name__gcp_financial_forecasting_2023_date_month__1 {
    query: {
      dimensions: [gcp_financial_forecasting_2023.app_id, gcp_financial_forecasting_2023.application_name, gcp_financial_forecasting_2023.date_month]
      measures: [gcp_financial_forecasting_2023.monthly_forecast]
      timezone: "America/Los_Angeles"
    }

    materialization: {
      datagroup_trigger: daily_datagroup
    }
  }

  # aggregate_table: rollup__gcp_financial_forecasting_2023_app_id__gcp_financial_forecasting_2023_date_month__2 {
  #   query: {
  #     dimensions: [gcp_financial_forecasting_2023.app_id, gcp_financial_forecasting_2023.date_month]
  #     measures: [gcp_financial_forecasting_2023.monthly_forecast, total_net_cost]
  #     timezone: "America/Los_Angeles"
  #   }

  #   materialization: {
  #     datagroup_trigger: daily_datagroup
  #   }
  # }

  # aggregate_table: rollup__billing_lookup_FinalCostCategory__gcp_financial_forecasting_2023_date_month__3 {
  #   query: {
  #     dimensions: [billing_lookup.FinalCostCategory, gcp_financial_forecasting_2023.date_month]
  #     measures: [gcp_financial_forecasting_2023.monthly_forecast, total_net_cost]
  #     timezone: "America/Los_Angeles"
  #   }

  #   materialization: {
  #     datagroup_trigger: daily_datagroup
  #   }
  # }
}

#Apptio Tower lookup #152
explore: +gcp_billing_export {
  aggregate_table: rollup__billing_lookup_FinalCostCategory__billing_lookup_service_name__billing_lookup_sku_id__0 {
    query: {
      dimensions: [billing_lookup.FinalCostCategory, billing_lookup.service_name, billing_lookup.sku_id]
      timezone: "America/Los_Angeles"
    }

    materialization: {
      datagroup_trigger: daily_datagroup
    }
  }

  aggregate_table: rollup__billing_lookup_FinalCostCategory__invoice_month_month__1 {
    query: {
      dimensions: [billing_lookup.FinalCostCategory, invoice_month_month]
      measures: [total_net_cost]
      filters: [gcp_billing_export.invoice_month_month: "after 2023/01/01"]
      timezone: "America/Los_Angeles"
    }

    materialization: {
      datagroup_trigger: daily_datagroup
    }
  }

  aggregate_table: rollup__billing_lookup_FinalCostCategory__gcp_financial_forecasting_2023_month_date_month__2 {
    query: {
      dimensions: [billing_lookup.FinalCostCategory, gcp_financial_forecasting_2023.date_month]
      measures: [gcp_financial_forecasting_2023.monthly_forecast]
      filters: [gcp_financial_forecasting_2023.date_month: "NOT NULL"]
      timezone: "America/Los_Angeles"
    }

    materialization: {
      datagroup_trigger: daily_datagroup
    }
  }
}

#Executive Summary Dashboard
explore: +gcp_billing_export {
  aggregate_table: rollup__invoice_month_month__0 {
    query: {
      dimensions: [invoice_month_month]
      measures: [gcp_billing_export__credits.total_amount, total_cost, total_net_cost]
      filters: [
        gcp_billing_export.invoice_month_month: "12 months",
        # "pricing_mapping.marketplace_purchase" was filtered by dashboard. The aggregate table will only optimize against exact match queries.
        pricing_mapping.marketplace_purchase: "No,Yes"
      ]
      timezone: "America/Chicago"
    }

    materialization: {
      datagroup_trigger: daily_datagroup
    }
  }

  aggregate_table: rollup__invoice_month_quarter__1 {
    query: {
      dimensions: [invoice_month_quarter]
      measures: [total_net_cost]
      filters: [
        gcp_billing_export.usage_start_date: "2 quarters",
        # "pricing_mapping.marketplace_purchase" was filtered by dashboard. The aggregate table will only optimize against exact match queries.
        pricing_mapping.marketplace_purchase: "No,Yes"
      ]
      timezone: "America/Chicago"
    }

    materialization: {
      datagroup_trigger: daily_datagroup
    }
  }

  aggregate_table: rollup__invoice_month_month__2 {
    query: {
      dimensions: [invoice_month_month]
      measures: [total_net_cost]
      filters: [
        gcp_billing_export.usage_start_date: "2 months",
        # "pricing_mapping.marketplace_purchase" was filtered by dashboard. The aggregate table will only optimize against exact match queries.
        pricing_mapping.marketplace_purchase: "No,Yes"
      ]
      timezone: "America/Chicago"
    }

    materialization: {
      datagroup_trigger: daily_datagroup
    }
  }

  aggregate_table: rollup__invoice_month_month__3 {
    query: {
      dimensions: [invoice_month_month]
      measures: [total_net_cost]
      filters: [
        gcp_billing_export.usage_start_date: "2 weeks",
        # "pricing_mapping.marketplace_purchase" was filtered by dashboard. The aggregate table will only optimize against exact match queries.
        pricing_mapping.marketplace_purchase: "No,Yes"
      ]
      timezone: "America/Chicago"
    }

    materialization: {
      datagroup_trigger: daily_datagroup
    }
  }

  aggregate_table: rollup__invoice_month_month__4 {
    query: {
      dimensions: [invoice_month_month]
      measures: [gcp_billing_export__credits.total_amount, total_cost, total_net_cost]
      filters: [
        gcp_billing_export.invoice_month_month: "1 years",
        gcp_billing_export.service__description: "Support",
        # "pricing_mapping.marketplace_purchase" was filtered by dashboard. The aggregate table will only optimize against exact match queries.
        pricing_mapping.marketplace_purchase: "No,Yes"
      ]
      timezone: "America/Chicago"
    }

    materialization: {
      datagroup_trigger: daily_datagroup
    }
  }

  aggregate_table: rollup__invoice_month_month__5 {
    query: {
      dimensions: [invoice_month_month]
      measures: [total_net_cost]
      filters: [
        gcp_billing_export.invoice_month_month: "10 months ago for 10 months",
        # "pricing_mapping.marketplace_purchase" was filtered by dashboard. The aggregate table will only optimize against exact match queries.
        pricing_mapping.marketplace_purchase: "No,Yes"
      ]
      timezone: "America/Chicago"
    }

    materialization: {
      datagroup_trigger: daily_datagroup
    }
  }
}

#KPI Dashboard
explore: +gcp_billing_export {
  aggregate_table: rollup__usage_start_month__0 {
    query: {
      dimensions: [usage_start_month]
      measures: [gcp_billing_export__credits.total_committed_use_discount, total_cost, total_cud_cost, total_net_cost, total_non_cud_cost]
      filters: [
        gcp_billing_export.service__description: "Compute Engine",
        gcp_billing_export.usage_start_month: "6 months",
        gcp_billing_export__credits.type: "-Discount"
      ]
      timezone: "America/Los_Angeles"
    }

    materialization: {
      datagroup_trigger: daily_datagroup
    }
  }

  aggregate_table: rollup__pricing_pricing_type__usage_start_month__1 {
    query: {
      dimensions: [pricing.pricing_type, usage_start_month]
      measures: [total_net_cost, usage__amount_in_calculated_units]
      filters: [
        gcp_billing_export.service__description: "Cloud Storage",
        gcp_billing_export.sku__description: "%Storage%",
        gcp_billing_export.usage__calculated_unit: "gibibyte month",
        gcp_billing_export.usage_start_month: "6 months"
      ]
      timezone: "America/Los_Angeles"
    }

    materialization: {
      datagroup_trigger: daily_datagroup
    }
  }

  aggregate_table: rollup__cud_eligible__machine_type__pricing_pricing_type__usage_start_month__2 {
    query: {
      dimensions: [cud_eligible, machine_type, pricing.pricing_type, usage_start_month]
      measures: [total_cost]
      filters: [
        gcp_billing_export.service__description: "Cloud Storage",
        gcp_billing_export.usage_start_date: "6 months",
        pricing.pricing_category: "Data Retrieval,Early Deletes"
      ]
      timezone: "America/Los_Angeles"
    }

    materialization: {
      datagroup_trigger: daily_datagroup
    }
  }
}

explore: +gcp_billing_export {
  #FinOps Operational Metrics
  aggregate_table: rollup__eligible_labels_labeling_supported__usage_start_date__0 {
    query: {
      dimensions: [eligible_labels.labeling_supported, usage_start_date]
      measures: [total_net_cost]
      filters: [
        gcp_billing_export.gcp_org_id: "1036178998277",
        gcp_billing_export.usage_start_date: "10 days ago for 10 days"
      ]
      timezone: "America/Chicago"
    }

    materialization: {
      datagroup_trigger: daily_datagroup
    }
  }
  aggregate_table: rollup__eligible_labels_labeling_supported__usage_start_date__1 {
    query: {
      dimensions: [eligible_labels.labeling_supported, usage_start_date]
      measures: [total_net_cost]
      filters: [
        gcp_billing_export.gcp_org_id: "1061028459868",
        gcp_billing_export.usage_start_date: "10 days ago for 10 days"
      ]
      timezone: "America/Chicago"
    }

    materialization: {
      datagroup_trigger: daily_datagroup
    }
  }
  #Kevin's First Dashboard
  aggregate_table: rollup__usage_start_date__0 {
    query: {
      dimensions: [usage_start_date]
      measures: [gcp_billing_export__credits.total_amount, total_cost, total_net_cost]
      filters: [
        gcp_billing_export.invoice_month_month: "1 months",
        gcp_billing_export.sku__description: "-Tax"
      ]
      timezone: "America/Chicago"
    }

    materialization: {
      datagroup_trigger: daily_datagroup
    }
  }
  aggregate_table: rollup__service__description__sku__description__usage_start_month__1 {
    query: {
      dimensions: [service__description, sku__description, usage_start_month]
      measures: [total_cost]
      filters: [
        gcp_billing_export.sku__description: "%Support%",
        gcp_billing_export.usage_start_month: "after 2022/01/01",
        gcp_billing_export__project__labels.key: "EMPTY"
      ]
      timezone: "America/Chicago"
    }

    materialization: {
      datagroup_trigger: daily_datagroup
    }
  }
  aggregate_table: rollup__gcp_billing_export__credits_type__usage_start_month__2 {
    query: {
      dimensions: [gcp_billing_export__credits.type, usage_start_month]
      measures: [gcp_billing_export__credits.total_amount]
      filters: [gcp_billing_export.usage_start_month: "after 2022/01/01"]
      timezone: "America/Chicago"
    }

    materialization: {
      datagroup_trigger: daily_datagroup
    }
  }
  #BigQuery Deep Dive
  aggregate_table: rollup__billing_lookup_category_resource_group__usage_start_month__0 {
    query: {
      dimensions: [billing_lookup.category_resource_group, usage_start_month]
      measures: [total_net_cost]
      filters: [
        gcp_billing_export.service__description: "%BigQuery%",
        gcp_billing_export.usage_start_month: "after 2022/01/01"
      ]
      timezone: "America/Chicago"
    }

    materialization: {
      datagroup_trigger: daily_datagroup
    }
  }
  aggregate_table: rollup__billing_lookup_category_resource_group__usage_start_date__1 {
    query: {
      dimensions: [billing_lookup.category_resource_group, usage_start_date]
      measures: [total_usage_amount]
      filters: [
        billing_lookup.category_resource_group: "-%Streaming%,-NULL",
        gcp_billing_export.service__description: "%BigQuery%",
        gcp_billing_export.sku__description: "%Storage%",
        gcp_billing_export.usage_start_date: "120 days"
      ]
      timezone: "America/Chicago"
    }

    materialization: {
      datagroup_trigger: daily_datagroup
    }
  }
  aggregate_table: rollup__project__name__usage_start_date__2 {
    query: {
      dimensions: [project__name, usage_start_date]
      measures: [total_usage_amount]
      filters: [
        billing_lookup.category_resource_group: "-%Streaming%",
        gcp_billing_export.service__description: "%BigQuery%",
        gcp_billing_export.sku__description: "%Storage%",
        gcp_billing_export.usage_start_date: "120 days"
      ]
      timezone: "America/Chicago"
    }

    materialization: {
      datagroup_trigger: daily_datagroup
    }
  }
  aggregate_table: rollup__sku__description__usage_start_date__3 {
    query: {
      dimensions: [sku__description, usage_start_date]
      measures: [total_usage_amount]
      filters: [
        gcp_billing_export.service__description: "%BigQuery%",
        gcp_billing_export.sku__description: "%Physical%",
        gcp_billing_export.usage_start_date: "120 days"
      ]
      timezone: "America/Chicago"
    }

    materialization: {
      datagroup_trigger: daily_datagroup
    }
  }
  aggregate_table: rollup__location__region__usage_start_date__4 {
    query: {
      dimensions: [location__region, usage_start_date]
      measures: [total_cost]
      filters: [
        gcp_billing_export.service__description: "%BigQuery%",
        gcp_billing_export.sku__description: "-%Storage%,-%Streaming%,-%Engine%,-%Attribution%",
        gcp_billing_export.usage_start_date: "120 days"
      ]
      timezone: "America/Chicago"
    }

    materialization: {
      datagroup_trigger: daily_datagroup
    }
  }
  aggregate_table: rollup__business_object_id__usage_start_date__5 {
    query: {
      dimensions: [business_object_id, usage_start_date]
      measures: [total_usage_amount]
      filters: [
        billing_lookup.category_resource_group: "-%Streaming%,-NULL",
        gcp_billing_export.service__description: "%BigQuery%",
        gcp_billing_export.sku__description: "%Storage%",
        gcp_billing_export.usage_start_date: "120 days"
      ]
      timezone: "America/Chicago"
    }

    materialization: {
      datagroup_trigger: daily_datagroup
    }
  }
}

######################################


explore: recommendations_export {
  label: "Recommendations"
  hidden: no
  sql_always_where:
  -- Show only the latest recommendations. Use a grace period of 3 days to avoid data export gaps.
  --_PARTITIONDATE = DATE_SUB(CURRENT_DATE(), INTERVAL 3 DAY)
  IFNULL(_PARTITIONDATE, DATE_SUB(CURRENT_DATE(), INTERVAL 4 DAY)) = DATE_SUB(CURRENT_DATE(), INTERVAL 3 DAY);;
  #     ${last_refresh_date} =  DATE_SUB(CURRENT_DATE(), INTERVAL 3 DAY) ;;
  # --  AND ${cloud_entity_type} = 'PROJECT_NUMBER'
  # --  AND ${state} = 'ACTIVE'
  # --  AND ${recommender} IN ('google.compute.commitment.UsageCommitmentRecommender',
  # --    'google.compute.disk.IdleResourceRecommender',
  # --    'google.compute.instance.IdleResourceRecommender',
  # --    'google.compute.instance.MachineTypeRecommender' )
  # --  AND ${primary_impact__cost_projection__cost__units} IS NOT NULL ;;

    join: recommendations_export__target_resources {
      view_label: "Recommendations Export"
      sql: LEFT JOIN UNNEST(${recommendations_export.target_resources}) as recommendations_export__target_resources ;;
      relationship: one_to_many
    }

    join: recommendations_export__associated_insights {
      view_label: "Recommendations Export"
      sql: LEFT JOIN UNNEST(${recommendations_export.associated_insights}) as recommendations_export__associated_insights ;;
      relationship: one_to_many
    }

    join: tickets {
      type: full_outer
      relationship: one_to_one
      sql_on: ${recommendations_export.ticket_id} = ${tickets.recommendations_id};;
    }
  }

  explore: forecasting {
    from: billing_lookup

    join: gcp_financial_forecasting_2023 {
      type: left_outer
      relationship: many_to_many
      sql_on: ${forecasting.FinalCostCategory} = ${gcp_financial_forecasting_2023.cost_category} ;;
    }

    join: gcp_billing_export {
      type: left_outer
      relationship: one_to_many
      sql_on: ${forecasting.sku_id} = ${gcp_billing_export.sku__id} ;;
      fields: [gcp_billing_export.sku__id, gcp_billing_export.sku__description, gcp_billing_export.total_net_cost, gcp_billing_export.app_id_resource, gcp_billing_export.invoice_month_month]
    }

    join: gcp_billing_export__credits {
      sql:LEFT JOIN UNNEST(${gcp_billing_export.credits}) as gcp_billing_export__credits ;;
      relationship: one_to_many
    }
  }

  explore: cloud_pricing_export {
    label: "Pricing Taxonomy"
    hidden: yes
    # right now only supporting BigQuery, Compute Engine and Cloud Storage for product specific analysis
    sql_always_where: ${service__description} IN (
        'Compute Engine',
        'Cloud Storage',
        'BigQuery',
        'BigQuery Reservation API',
        'BigQuery Storage API') ;;

    join: cloud_pricing_export__product_taxonomy {
      view_label: "Cloud Pricing Export: Product Taxonomy"
      sql: ,UNNEST(${cloud_pricing_export.product_taxonomy}) as cloud_pricing_export__product_taxonomy ;;
      relationship: one_to_many
    }

    join: cloud_pricing_export__geo_taxonomy__regions {
      view_label: "Cloud Pricing Export: Geo Taxonomy Regions"
      sql: ,UNNEST(${cloud_pricing_export.geo_taxonomy__regions}) as cloud_pricing_export__geo_taxonomy__regions ;;
      relationship: one_to_many
    }

    join: cloud_pricing_export__list_price__tiered_rates {
      view_label: "Cloud Pricing Export: List Price Tiered Rates"
      sql: ,UNNEST(${cloud_pricing_export.list_price__tiered_rates}) as cloud_pricing_export__list_price__tiered_rates ;;
      relationship: one_to_many
    }

    join: cloud_pricing_export__sku__destination_migration_mappings {
      view_label: "Cloud Pricing Export: Sku Destination Migration Mappings"
      sql: ,UNNEST(${cloud_pricing_export.sku__destination_migration_mappings}) as cloud_pricing_export__sku__destination_migration_mappings ;;
      relationship: one_to_many
    }

    join: cloud_pricing_export__billing_account_price__tiered_rates {
      view_label: "Cloud Pricing Export: Billing Account Price Tiered Rates"
      sql: ,UNNEST(${cloud_pricing_export.billing_account_price__tiered_rates}) as cloud_pricing_export__billing_account_price__tiered_rates ;;
      relationship: one_to_many
    }
  }

  explore: cloud_pricing {
    from: cloud_pricing_export
    hidden: yes
  }

  explore: consumption_model_high_level {}

  explore:  consumption_model_summary {}

  explore: aws_savings_plans {
    from: aws_savings_plans
    hidden:  no
    label: "AWS Savings Plans"
  }
