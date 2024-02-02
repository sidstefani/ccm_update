include: "/views/applications.view.lkml"
view: gcp_billing_export {
  view_label: "Billing"
  derived_table: {
    partition_keys: ["partition_date"]
    cluster_keys: ["usage_start_time","service_description","sku_description", "project_name"]
    datagroup_trigger: daily_datagroup
    increment_key: "partition_date"
    increment_offset: 1
    sql: select *, generate_uuid() as pk, _PARTITIONTIME as partition_date,
         service.description as service_description, sku.description as sku_description, project.name as project_name,
         --- Project Labels
         (SELECT value FROM UNNEST(billing_export.project.labels) WHERE key = "app_id") AS gcp_billing_export_project_app_id,
         (SELECT value FROM UNNEST(billing_export.project.labels) WHERE key = "department_name") AS gcp_billing_export_project_department_name,
         (SELECT value FROM UNNEST(billing_export.project.labels) WHERE key = "environment") AS gcp_billing_export_project_environment,
         (SELECT value FROM UNNEST(billing_export.project.labels) WHERE key = "managed_by") AS gcp_billing_export_project_managed_by,
         (SELECT value FROM UNNEST(billing_export.project.labels) WHERE key = "contact_name") AS gcp_billing_export_project_contact_name,
         (SELECT value FROM UNNEST(billing_export.project.labels) WHERE key = "created_date") AS gcp_billing_export_project_created_date,
         (SELECT value FROM UNNEST(billing_export.project.labels) WHERE key = "originator") AS gcp_billing_export_project_originator,
         --- Resource Labels
         (SELECT value FROM UNNEST(billing_export.labels) WHERE key = "originator") AS gcp_billing_export_resource_originator,
         (SELECT value FROM UNNEST(billing_export.labels) WHERE key = "contact_name") AS gcp_billing_export_resource_contact_name,
         (SELECT value FROM UNNEST(billing_export.labels) WHERE key = "deployment_type") AS gcp_billing_export_resource_deployment_type,
         (SELECT value FROM UNNEST(billing_export.labels) WHERE key = "environment") AS gcp_billing_export_resource_environment,
         (SELECT value FROM UNNEST(billing_export.labels) WHERE key = "app_name") AS gcp_billing_export_resource_app_name,
         (SELECT value FROM UNNEST(billing_export.labels) WHERE key = "department_name") AS gcp_billing_export_resource_department_name,
         (SELECT value FROM UNNEST(billing_export.labels) WHERE key = "component_id") AS gcp_billing_export_resource_component_id,
         (SELECT value FROM UNNEST(billing_export.labels) WHERE key = "created_date") AS gcp_billing_export_resource_created_date,
         (SELECT value FROM UNNEST(billing_export.labels) WHERE key = "project_id") AS gcp_billing_export_resource_project_id,
         (SELECT value FROM UNNEST(billing_export.labels) WHERE key = "cme_project_id") AS gcp_billing_export_resource_cme_project_id,
         (SELECT value FROM UNNEST(billing_export.labels) WHERE key = "app_id") AS gcp_billing_export_resource_app_id,
--         (SELECT value  FROM UNNEST(billing_export.labels) WHERE key = "resource.name") AS gcp_billing_export_resource_name,
         (SELECT UPPER(value) FROM UNNEST(billing_export.labels) WHERE key = "business_object_id") AS gcp_billing_export_resource_business_object_id,
         (SELECT UPPER(value) FROM UNNEST(billing_export.labels) WHERE key = "business_data_id") AS gcp_billing_export_resource_business_data_id,
        ---- K8 Labels
         (SELECT value FROM UNNEST(billing_export.labels) WHERE key = "goog-k8s-namespace") AS gcp_billing_export_goog_k8s_namespace,
         (SELECT value FROM UNNEST(billing_export.labels) WHERE key = "goog-k8s-cluster-name") AS gcp_billing_export_goog_k8s_cluster_name,
         (SELECT value FROM UNNEST(billing_export.labels) WHERE key = "k8s-label/scorecard_sub_product") AS gcp_billing_export_k8s_label_scorecard_sub_product,
         (SELECT value FROM UNNEST(billing_export.labels) WHERE key = "k8s-label/scorecard_service_stream") AS gcp_billing_export_k8s_label_scorecard_service_stream,
         (SELECT value FROM UNNEST(billing_export.labels) WHERE key = "k8s-label/app_id") AS gcp_billing_export_k8s_label_app_id,
         (SELECT value FROM UNNEST(billing_export.labels) WHERE key = "k8s-label/component_id") AS gcp_billing_export_k8s_label_component_id,
         (SELECT value FROM UNNEST(billing_export.labels) WHERE key = "k8s-label/contact_name") AS gcp_billing_export_k8s_fq_contact_name,
         (SELECT value FROM UNNEST(billing_export.labels) WHERE key = "k8s-label/cme_project_id") AS gcp_billing_export_k8s_fq_cme_project_id,
         (SELECT value FROM UNNEST(billing_export.labels) WHERE key = "k8s-label/environment") AS gcp_billing_export_k8s_fq_environment,
         (SELECT value FROM UNNEST(billing_export.labels) WHERE key = "k8s-label/department_name") AS gcp_billing_export_k8s_fq_department_name,
        ---- System Labels
         (SELECT value FROM UNNEST(billing_export.system_labels) WHERE key = "compute.googleapis.com/cores") AS gcp_billing_export_cores,
         (SELECT value FROM UNNEST(billing_export.system_labels) WHERE key = "compute.googleapis.com/is_unused_reservation") AS gcp_billing_export_is_unused_reservation,
         (SELECT value FROM UNNEST(billing_export.system_labels) WHERE key = "compute.googleapis.com/machine_spec") AS gcp_billing_export_machine_spec,
         (SELECT value FROM UNNEST(billing_export.system_labels) WHERE key = "compute.googleapis.com/memory") AS gcp_billing_export_memory
         from @{BILLING_TABLE} as billing_export
         WHERE {% incrementcondition %} _PARTITIONDATE {% endincrementcondition %} ;;
  }

  #### Unnested Labels in PDT ###
  #### System LABELS #######

  dimension: cores {
    view_label: "Labels"
    group_label: "System"
    type: string
    sql:${TABLE}.gcp_billing_export_cores ;;
  }

  dimension: is_unused_reservation {
    view_label: "Labels"
    label: "Is Unused Reservation?"
    group_label: "System"
    type: string
    sql:${TABLE}.gcp_billing_export_is_unused_reservation ;;
  }

  dimension: machine_spec {
    view_label: "Labels"
    group_label: "System"
    type: string
    sql:${TABLE}.gcp_billing_export_machine_spec ;;
  }

  dimension: memory {
    view_label: "Labels"
    group_label: "System"
    type: string
    sql:${TABLE}.gcp_billing_export_memory ;;
  }

  #### Resource Labels ###

  dimension: originator {
    label: "Originator"
    view_label: "Labels"
    hidden: yes
    group_label: "Resource"
    type: string
    sql: ${TABLE}.gcp_billing_export_resource_originator ;;
  }

  dimension: contact_name {
    label: "Contact Name"
    view_label: "Labels"
    group_label: "Resource"
    type: string
    sql: ${TABLE}.gcp_billing_export_resource_contact_name ;;
  }

  dimension: resource__name {
    label: "Resource Name"
    type:  string
    sql:  ${TABLE}.resource.name ;;
    view_label: "Labels"
    group_label: "Resource"
  }

  dimension: deployment_type {
    label: "Deployment Type"
    view_label: "Labels"
    group_label: "Resource"
    hidden:  yes
    type: string
    sql: ${TABLE}.gcp_billing_export_resource_deployment_type ;;
  }

  dimension: environment {
    label: "Environment"
    view_label: "Labels"
    group_label: "Resource"
    type: string
    sql: ${TABLE}.gcp_billing_export_resource_environment ;;
  }

  dimension: app_name {
    label: "App Name"
    view_label: "Labels"
    group_label: "Resource"
    hidden: yes
    type: string
    sql: ${TABLE}.gcp_billing_export_resource_app_name ;;
  }

  dimension: department_name {
    label: "Department Name"
    view_label: "Labels"
    group_label: "Resource"
    type: string
    sql: ${TABLE}.gcp_billing_export_resource_department_name ;;
  }

  dimension: component_id {
    label: "Component ID"
    view_label: "Labels"
    group_label: "Resource"
    type: string
    sql: ${TABLE}.gcp_billing_export_resource_component_id ;;
  }

  dimension: component_id_upper {
    hidden: yes
    sql: UPPER(${component_id_with_unallocated_and_k8}) ;;
  }

  dimension: created_date {
    label: "Created Date"
    view_label: "Labels"
    hidden: yes
    group_label: "Resource"
    type: string
    sql: ${TABLE}.gcp_billing_export_resource_created_date ;;
  }

  dimension: project_id {
    view_label: "Labels"
    label: "Project ID (PMGT - old)"
    group_label: "Resource"
    type: string
    sql: ${TABLE}.gcp_billing_export_resource_project_id ;;
  }

  dimension: cme_project_id {
    view_label: "Labels"
    label: "Project ID (PMGT - new)"
    group_label: "Resource"
    type: string
    sql: ${TABLE}.gcp_billing_export_resource_cme_project_id ;;
  }

  dimension: cme_project_id_upper {
    hidden: yes
    #Sidney Stefani - field used to join with the forecast data
    sql: UPPER(${cme_project_id}) ;;
  }

  dimension: app_id_resource {
    view_label: "Labels"
    label: "Resource App ID"
    group_label: "Resource"
    type: string
    sql: ${TABLE}.gcp_billing_export_resource_app_id ;;
  }

  #Rishi Ghai - Update dimension to include ProjectAppId if ResourceAppId is null
  dimension: app_id_with_unallocated {
    type: string
    label: "App ID (Resource & Project)"
    description: "This field pulls from the resource app ID, if null then the project app ID"
    group_label: "Resource"
    view_label: "Labels"
    link: {
      label: "Usage Deep Dive"
      url: "https://cmegroup.cloud.looker.com/dashboards/29?Project+ID=&Service+Type=&Application+Name=&App+ID+%28Resource%29={{ app_id_with_unallocated._value }}"
    }
    sql: CASE
            WHEN ${app_id_resource} IS NULL AND ${app_id} IS NOT NULL THEN ${app_id}
            WHEN ${app_id_resource} IS NULL AND ${app_id} IS NULL THEN 'Unallocated App ID'
            ELSE ${app_id_resource} END;;
  }

  dimension: business_object_id {
    type:  string
    label: "Business Object ID"
    group_label: "Resource"
    view_label: "Labels"
    sql: ${TABLE}.gcp_billing_export_resource_business_object_id ;;
  }

  dimension: business_data_id {
    type:  string
    label: "Business Data ID (old)"
    hidden: yes
    group_label: "Resource"
    view_label: "Labels"
    sql: ${TABLE}.gcp_billing_export_resource_business_data_id ;;
  }

  #Jonathan Morley - Used to join forecasts with billing (harmonization)
  dimension: environment_shortname {
    type: string
    label: "Environment (Inferred)"
    group_label: "Resource"
    view_label: "Labels"
    #Case statements return the first condition to evaluate to TRUE
    #If both RESOURCE environment and PROJECT environment are null, make the environment 'Unknown'
    #Otherwise, checks the RESOURCE environment; if missing, uses the project environment
    sql:  CASE
      WHEN ${environment} IS NULL AND ${project_environment} IS NULL THEN "Unknown"
      WHEN ${environment} IS NULL AND (${project_environment} LIKE 'pr%' OR ${project_environment} = "dr") THEN "Prod"
      WHEN ${environment} IS NULL AND ${project_environment} IS NOT NULL THEN "Non-Prod"
      WHEN ${environment} LIKE "pr%" OR ${environment} = "dr" THEN "Prod"
      ELSE "Non-Prod" END;;
  }

  ####### K8 Labels ##########

  # #2022-01-23 jm to support Trading FINOPS-38 (needs to come from detailed billing)
  dimension: goog_k8s_namespace {
    type:  string
    label: "Goog-K8s Namespace"
    group_label: "Kubernetes"
    view_label: "Labels"
    sql: ${TABLE}.gcp_billing_export_goog_k8s_namespace ;;
  }

  dimension: goog_k8s_cluster_name {
    type:  string
    label: "Goog-K8s Cluster Name"
    group_label: "Kubernetes"
    view_label: "Labels"
    sql: ${TABLE}.gcp_billing_export_goog_k8s_cluster_name ;;
  }

  dimension: k8s_fq_scorecard_sub_product {
    type:  string
    label: "Sub-Product (k8s-label)"
    group_label: "Kubernetes"
    view_label: "Labels"
    sql: ${TABLE}.gcp_billing_export_k8s_label_scorecard_sub_product ;;
  }

  dimension: k8s_fq_scorecard_service_stream {
    type:  string
    label: "Service Stream (k8s-label)"
    group_label: "Kubernetes"
    view_label: "Labels"
    sql: ${TABLE}.gcp_billing_export_k8s_label_scorecard_service_stream ;;
  }

  dimension: k8s_fq_app_id {
    type:  string
    label: "App ID (k8s-label)"
    group_label: "Kubernetes"
    view_label: "Labels"
    sql: ${TABLE}.gcp_billing_export_k8s_label_app_id ;;
  }

  dimension: app_id_with_unallocated_and_k8 {
    type: string
    label: "App ID (K8 & Resource & Project)"
    description: "This field pulls from the resource app ID, if null then the project app ID"
    group_label: "Kubernetes"
    view_label: "Labels"
    # link: {
    #   label: "Usage Deep Dive"
    #   url: "https://cmegroup.cloud.looker.com/dashboards/18?Project+ID=&Service+Type=&Application+Name=&App+ID+%28Resource%29={{ app_id_with_unallocated._value }}"
    # }
    sql: CASE
      WHEN ${k8s_fq_app_id} IS NOT NULL THEN ${k8s_fq_app_id}
      WHEN ${app_id_resource} IS NULL AND ${app_id} IS NOT NULL THEN ${app_id}
      WHEN ${app_id_resource} IS NULL AND ${app_id} IS NULL THEN 'Unallocated App ID'
      ELSE ${app_id_resource} END;;
  }

  #2023-10-04 jm - Update dimension to include K8 Label if not null and ProjectAppId if ResourceAppId is null

  dimension: component_id_with_unallocated_and_k8 {
    type: string
    label: "Component ID (K8 & Resource)"
    description: "This field pulls from the K8s value, if available. If it's not, we take the resource's Component ID"
    group_label: "Kubernetes"
    view_label: "Labels"
    sql: CASE
      WHEN ${k8s_fq_component_id} IS NOT NULL THEN ${k8s_fq_component_id}
      WHEN ${component_id} IS NULL THEN 'Unallocated Component ID'
      ELSE ${component_id} END;;
  }

  dimension: app_name_k8_resource_project {
    type: string
    label: "App Name (K8 & Resource & Project)"
    description: "Looks up App Name based on K8_Resource_Project App ID"
    group_label: "Kubernetes"
    view_label: "Labels"
    sql:  case
          when ${applications.app_portfolio_id_nbr}=${app_id_with_unallocated_and_k8}
          then ${applications.name}
          else NULL END;;
    }

  dimension: k8s_fq_component_id {
    type:  string
    label: "Component ID (k8s-label)"
    group_label: "Kubernetes"
    view_label: "Labels"
    sql: ${TABLE}.gcp_billing_export_k8s_label_component_id ;;
  }

  dimension: k8s_fq_contact_name {
    type:  string
    label: "Contact Name (k8s-label)"
    view_label: "Labels"
    group_label: "Kubernetes"
    sql: ${TABLE}.gcp_billing_export_k8s_fq_contact_name ;;
  }

  dimension: k8s_fq_cme_project_id {
    type:  string
    label: "CME Project ID (k8s-label)"
    view_label: "Labels"
    group_label: "Kubernetes"
    sql: ${TABLE}.gcp_billing_export_k8s_fq_cme_project_id ;;
  }

  dimension: k8s_fq_environment {
    type:  string
    label: "Environment (k8s-label)"
    view_label: "Labels"
    group_label: "Kubernetes"
    sql: ${TABLE}.gcp_billing_export_k8s_fq_environment ;;
  }

  dimension: k8s_fq_department_name {
    type:  string
    label: "Department Name (k8s-label)"
    view_label: "Labels"
    group_label: "Kubernetes"
    sql: ${TABLE}.gcp_billing_export_k8s_fq_department_name ;;
  }

  ##### Project Labels ####

  dimension: app_id {
    label: "App ID"
    view_label: "Labels"
    group_label: "Project"
    type: string
    sql: ${TABLE}.gcp_billing_export_project_app_id ;;
  }

  dimension: project_department_name {
    label: "Department Name"
    view_label: "Labels"
    group_label: "Project"
    type: string
    sql: ${TABLE}.gcp_billing_export_project_department_name ;;
  }

  dimension: project_environment {
    label: "Environment"
    view_label: "Labels"
    group_label: "Project"
    type: string
    sql: ${TABLE}.gcp_billing_export_project_environment  ;;
  }

  dimension: project_managed_by {
    label: "Managed By"
    view_label: "Labels"
    group_label: "Project"
    type: string
    sql: ${TABLE}.gcp_billing_export_project_managed_by  ;;
  }

  dimension: project_contact_name {
    label: "Contact Name"
    view_label: "Labels"
    group_label: "Project"
    type: string
    sql: ${TABLE}.gcp_billing_export_project_contact_name  ;;
  }

  dimension: project_created_date {
    label: "Created Date"
    view_label: "Labels"
    group_label: "Project"
    type: string
    sql: ${TABLE}.gcp_billing_export_project_created_date  ;;
  }

  dimension: project_originator {
    label: "Originator"
    view_label: "Labels"
    group_label: "Project"
    type: string
    sql: ${TABLE}.gcp_billing_export_project_originator  ;;
  }

  ################

  dimension: pk {
    hidden: yes
    primary_key: yes
    sql: ${TABLE}.pk ;;
  }

  dimension_group: partition {
    hidden: no
    type: time
    group_label: "Partition Fields"
    timeframes: [
      raw,
      date,
      week,
      month,
      quarter,
      year
    ]
    convert_tz: no
    datatype: date
    sql: ${TABLE}.partition_date ;;
  }

  dimension: project_ancestry {
    type: string
    hidden: no
     sql: TO_JSON_STRING(${TABLE}.project.ancestors) ;;
    }

  dimension: project_ancestry_folder {
    type: string
    hidden: no
    sql: REGEXP_EXTRACT(${project_ancestry}, r'folders/([^}]+)') ;;
  }

  dimension: project_ancestry_folder_display_name {
    type: string
    label: "Folder Display Name"
    sql: REGEXP_EXTRACT(${project_ancestry_folder}, r'display_name":"([^"]+)') ;;
  }

  #Technical Pod work to show GCP Folder names (CFPFIN-26)
  dimension: gcp_folder_level1_id {
    label: "Folder Level 1 ID"
    group_label: "GCP Folder ID"
    type: string
    sql: split( ${project__ancestry_numbers},"/")[safe_offset(2)] ;;
  }
  dimension: gcp_folder_level1_name {
    label: "Folder Level 1 Name"
    group_label: "GCP Folder Name"
    type: string
    sql: (SELECT display_name from UNNEST(${TABLE}.project.ancestors) WHERE ${gcp_folder_level1_id} = REGEXP_EXTRACT(resource_name, r'([0-9]+$)'));;
  }
  dimension: gcp_folder_level2_id {
    label: "Folder Level 2 ID"
    group_label: "GCP Folder ID"
    type: string
    sql: split( ${project__ancestry_numbers},"/")[safe_offset(3)] ;;
  }
  dimension: gcp_folder_level2_name {
    label: "Folder Level 2 Name"
    group_label: "GCP Folder Name"
    type: string
    sql: (SELECT display_name from UNNEST(${TABLE}.project.ancestors) WHERE ${gcp_folder_level2_id} = REGEXP_EXTRACT(resource_name, r'([0-9]+$)'));;
  }
  dimension: gcp_folder_level3_id {
    label: "Folder Level 3 ID"
    group_label: "GCP Folder ID"
    type: string
    sql: split( ${project__ancestry_numbers},"/")[safe_offset(4)] ;;
  }
  dimension: gcp_folder_level3_name {
    label: "Folder Level 3 Name"
    group_label: "GCP Folder Name"
    type: string
    sql: (SELECT display_name from UNNEST(${TABLE}.project.ancestors) WHERE ${gcp_folder_level3_id} = REGEXP_EXTRACT(resource_name, r'([0-9]+$)'));;
  }
  dimension: gcp_folder_level4_id {
    label: "Folder Level 4 ID"
    group_label: "GCP Folder ID"
    type: string
    sql: split( ${project__ancestry_numbers},"/")[safe_offset(5)] ;;
  }
  dimension: gcp_folder_level4_name {
    label: "Folder Level 4 Name"
    group_label: "GCP Folder Name"
    type: string
    sql: (SELECT display_name from UNNEST(${TABLE}.project.ancestors) WHERE ${gcp_folder_level4_id} = REGEXP_EXTRACT(resource_name, r'([0-9]+$)'));;
  }
  dimension: gcp_folder_level5_id {
    label: "Folder Level 5 ID"
    group_label: "GCP Folder ID"
    type: string
    sql: split( ${project__ancestry_numbers},"/")[safe_offset(6)] ;;
  }
  dimension: gcp_folder_level5_name {
    label: "Folder Level 5 Name"
    group_label: "GCP Folder Name"
    type: string
    sql: (SELECT display_name from UNNEST(${TABLE}.project.ancestors) WHERE ${gcp_folder_level5_id} = REGEXP_EXTRACT(resource_name, r'([0-9]+$)'));;
  }
  dimension: gcp_folder_level6_id {
    label: "Folder Level 6 ID"
    group_label: "GCP Folder ID"
    type: string
    sql: split( ${project__ancestry_numbers},"/")[safe_offset(7)] ;;
  }
  dimension: gcp_folder_level6_name {
    label: "Folder Level 6 Name"
    group_label: "GCP Folder Name"
    type: string
    sql: (SELECT display_name from UNNEST(${TABLE}.project.ancestors) WHERE ${gcp_folder_level6_id} = REGEXP_EXTRACT(resource_name, r'([0-9]+$)'));;
  }


  dimension_group: _partitiontime {
    description: "Partition column for the table - filter here to leverage partitions"
    group_label: "Partition Fields"
    type: time
    hidden: yes
    timeframes: [
      raw,
      date,
      week,
      month,
      quarter,
      year
    ]
    convert_tz: no
    datatype: date
    sql: ${TABLE}._PARTITIONTIME ;;
  }

        dimension: service_cost_category {
          description: "Used for join to Forecast Category"
          type: string
          sql: case when ${service__id} = "6F81-5844-456A" then "Compute"
                when ${service__id} = "95FF-2EF5-5EA1" then "Storage"
                when ${sku__description} LIKE "%Analysis%" AND  ${service__id} = "24E6-581D-38E5" then "Datebase"
                when ${sku__id} = "A1A2-4711-B376" then "Tax"
                when ${service__id} = "2062-016F-44A2" then "Support"
                when ${service__id} = "FBF2-FC68-171A" then "Security"
                when ${service__id} = "E505-1604-58F8" then "Networking Monitoring and Tools"
                else "Other GCP Services" end
                ;;
        }

        dimension: adjustment_info__description {
          type: string
          sql: ${TABLE}.adjustment_info.description ;;
          group_label: "Adjustment Info"
          group_item_label: "Description"
        }

        dimension: adjustment_info__id {
          type: string
          sql: ${TABLE}.adjustment_info.id ;;
          group_label: "Adjustment Info"
          group_item_label: "ID"
        }

        #Rishi Ghai - Updating for capitalization of values
        dimension: adjustment_info__mode {
          type: string
          sql:  CASE
                    WHEN ${TABLE}.adjustment_info.mode = 'MANUAL_ADJUSTMENT' THEN 'Manual Adjustment'
                    WHEN ${TABLE}.adjustment_info.mode = 'COMPLETE_NEGATION' THEN 'Complete Negation'
                    WHEN ${TABLE}.adjustment_info.mode = 'COMPLETE_NEGATION_WITH_REMONETIZATION' THEN 'Complete Negation with Remonetization'
                    ELSE ${TABLE}.adjustment_info.mode
                END ;;
          group_label: "Adjustment Info"
          group_item_label: "Mode"
        }

        dimension: adjustment_info__type {
          type: string
          sql: CASE
                    WHEN ${TABLE}.adjustment_info.type = 'USAGE_CORRECTION' THEN 'Usage Correction'
                    WHEN ${TABLE}.adjustment_info.type = 'GENERAL_ADJUSTMENT' THEN 'General Adjustment'
                    WHEN ${TABLE}.adjustment_info.type = 'GOODWILL' THEN 'Goodwill'
                    ELSE ${TABLE}.adjustment_info.type
                END ;;
          group_label: "Adjustment Info"
          group_item_label: "Type"
        }

        dimension: billing_account_id {
          type: string
          sql: ${TABLE}.billing_account_id ;;
        }

        dimension: cloud {
          type: string
          sql: 'GCPe' ;;
          link: {
            label: "{{ value }} Cost Management"
            url: "/dashboards/gcp_billing::gcp_summary"
            icon_url: "looker.com/favicon.ico"
          }
        }

        dimension: cost {
          type: number
          sql: ${TABLE}.cost ;;
        }

        dimension: cost_type {
          type: string
          sql: ${TABLE}.cost_type ;;
        }

        dimension: credits {
          hidden: yes
          sql: ${TABLE}.credits ;;
        }

        dimension: currency {
          group_label: "Currency"
          type: string
          sql: ${TABLE}.currency ;;
        }

        dimension: currency_conversion_rate {
          group_label: "Currency"
          type: number
          sql: ${TABLE}.currency_conversion_rate ;;
        }

        dimension_group: export {
          type: time
          timeframes: [
            raw,
            time,
            date,
            week,
            month,
            quarter,
            year
          ]
          sql: ${TABLE}.export_time ;;
        }

        dimension: invoice_month {
          type: string
          hidden: yes
          #Sidney Stefani - Hiding in order to convert to a date field
          sql: ${TABLE}.invoice.month ;;
          # group_label: "Invoice"
          # group_item_label: "Month"
        }

        dimension: labels {
          hidden: yes
          sql: ${TABLE}.labels ;;
        }

        dimension: location__country {
          type: string
          sql: ${TABLE}.location.country ;;
          group_label: "Location"
          group_item_label: "Country"
        }

        dimension: location__location {
          type: string
          sql: ${TABLE}.location.location ;;
          group_label: "Location"
          group_item_label: "Location"
        }

        dimension: location__region {
          type: string
          sql: ${TABLE}.location.region ;;
          group_label: "Location"
          group_item_label: "Region"
        }

        dimension: location__zone {
          type: string
          sql: ${TABLE}.location.zone ;;
          group_label: "Location"
          group_item_label: "Zone"
        }

        dimension: project__ancestry_numbers {
          type: string
          sql: ${TABLE}.project.ancestry_numbers ;;
          group_label: "Project"
          group_item_label: "Ancestry Numbers"
        }

        dimension: project__id {
          type: string
          sql: COALESCE(IF(${service__description} = 'Support', 'Support', ${TABLE}.project.id),"Unknown") ;;
          group_label: "Project"
          group_item_label: "ID"
          link: {
            label: "Usage Deep Dive"
            url: "https://cmegroup.cloud.looker.com/dashboards/18?Project+ID={{ project__id._value }}&Service+Type=&Application+Name=&App+ID+%28Resource%29="
          }
        }

        dimension: project__labels {
          hidden: yes
          sql: ${TABLE}.project.labels ;;
          group_label: "Project"
          group_item_label: "Labels"
        }

        dimension: project__name {
          type: string
          sql: ${TABLE}.project.name ;;
          group_label: "Project"
          group_item_label: "Name"
          link: {
            label: "{% if project__id._value != 'Support' and project__id._value  != 'Unknown' %} View Project in Console {% endif %}"
            url: "https://console.cloud.google.com/home/dashboard?project={{ project__id._value }}"
            icon_url: "https://i.pinimg.com/originals/92/b2/66/92b266df967b8540c94301eacdec391b.png"
          }
          link: {
            label: "Usage Deep Dive"
            url: "https://cmegroup.cloud.looker.com/dashboards/18?Project+ID={{ project__id._value }}&Service+Type=&Application+Name=&App+ID+%28Resource%29="
          }
        }

        dimension: project__number {
          type: string
          sql: ${TABLE}.project.number ;;
          group_label: "Project"
          group_item_label: "Number"
        }



        dimension: service__description {
          label: "Service Type"
          type: string
          sql: ${TABLE}.service.description ;;
          group_label: "Service"
          group_item_label: "Description"
          link: {
            label: "{% if value contains 'BigQuery' %} BigQuery Deep Dive {% endif %}"
            url: "https://cmegroup.cloud.looker.com/dashboards/21?GCP%20Project%20ID={{ _filters['gcp_billing_export.project__id'] | url_encode }}"
          }
          link: {
            label: "{% if value contains 'Compute Engine' %} Compute Engine Deep Dive {% endif %}"
            url: "https://cmegroup.cloud.looker.com/dashboards/23?GCP+Project+ID={{ _filters['gcp_billing_export.project__id'] | url_encode }}"
          }
          link: {
            label: "{% if value contains 'Cloud Storage' %} Cloud Storage Deep Dive {% endif %}"
            url: "https://cmegroup.cloud.looker.com/dashboards/22?GCP+Project+ID={{ _filters['gcp_billing_export.project__id'] | url_encode }}"
          }
          link: {
            label: "{% if value contains 'Networking' %} Networking Deep Dive {% endif %}"
            url: "https://cmegroup.cloud.looker.com/dashboards/68?Project+ID={{ _filters['gcp_billing_export.project__id'] | url_encode }}"
          }
          link: {
            label: "{% if value contains 'Kubernetes Engine' %} Kubernetes Engine Deep Dive {% endif %}"
            url: "https://cmegroup.cloud.looker.com/dashboards/67?Project+ID={{ _filters['gcp_billing_export.project__id'] | url_encode }}"
          }
          link: {
            label: "{% if value contains 'VMware Engine' %} VMware Engine Deep Dive {% endif %}"
            url: "https://cmegroup.cloud.looker.com/dashboards/69?Project+ID={{ _filters['gcp_billing_export.project__id'] | url_encode }}"
          }
        }

        dimension: service__id {
          type: string
          sql: ${TABLE}.service.id ;;
          group_label: "Service"
          group_item_label: "ID"
        }

        dimension: sku__description {
          type: string
          sql: ${TABLE}.sku.description ;;
          group_label: "SKU"
          group_item_label: "Description"
        }

        dimension: sku__id {
          type: string
          sql: ${TABLE}.sku.id ;;
          group_label: "SKU"
          group_item_label: "ID"
        }

        dimension: system_labels {
          hidden: yes
          sql: ${TABLE}.system_labels ;;
        }

        dimension: usage__amount {
          type: number
          sql: ${TABLE}.usage.amount ;;
          group_label: "CUD"
          group_item_label: "Amount"
        }

        dimension: usage__amount_in_pricing_units {
          type: number
          hidden: yes
          sql: ${TABLE}.usage.amount_in_pricing_units ;;
          group_label: "Usage"
          group_item_label: "Amount In Pricing Units"
        }

        dimension: usage__pricing_unit {
          type: string
          sql: ${TABLE}.usage.pricing_unit ;;
          group_label: "Usage"
          group_item_label: "Pricing Unit"
        }

        dimension: usage__unit {
          type: string
          sql: ${TABLE}.usage.unit ;;
          group_label: "Usage"
          group_item_label: "Unit"
        }

        dimension: usage__calculated_unit {
          type: string
          sql: CASE
                  -- VCPU RAM
                    WHEN ${usage__pricing_unit} = 'gibibyte hour' THEN 'GB'
                  -- VCPU Cores
                    WHEN ${usage__pricing_unit} = 'hour' THEN 'Count'
                  -- PD Storage
                  -- WHEN usage.pricing_unit = 'gibibyte month' THEN ROUND(SUM(usage.amount_in_pricing_units) * 30, 2)
                  ELSE ${usage__pricing_unit} END;;
          group_label: "Usage"
          group_item_label: "Calculated Unit"
        }

        dimension_group: usage_end {
          type: time
          timeframes: [
            raw,
            time,
            hour,
            date,
            week,
            month,
            quarter,
            year,
            month_name
          ]
          sql: ${TABLE}.usage_end_time ;;
        }

        dimension_group: usage_start {
          type: time
          timeframes: [
            raw,
            time,
            date,
            hour,
            week,
            month,
            quarter,
            year,
            month_name
          ]
          sql: ${TABLE}.usage_start_time ;;
        }

        dimension: cud_eligible {
          type: string
          label: "CUD Eligible"
          sql:  CASE WHEN ${sku__description} like "%Licensing Fee%" THEN "No"
                WHEN ${sku__description} like "%Network%" THEN "No"
                WHEN ${sku__description} like "%VM state%" THEN "No"
                WHEN ${sku__description} like "%Spot%" THEN "No"
                WHEN ${sku__description} like "%Instance Ram hosted on%" THEN "No"
                WHEN ${sku__description} like "%Instance Core hosted on%" THEN "No"
                WHEN ${sku__description} like "%Core%" THEN "Yes"
                WHEN ${sku__description} like "%Ram%" THEN "Yes"
                WHEN ${sku__description} like "%RAM%" THEN "Yes"
                ELSE "No" END;;
        }

        #${service__id} = "6F81-5844-456A"  AND

        measure: count {
          hidden: no
          type: count
          drill_fields: [project__name]
        }

  dimension: cost_at_list {
    type: number
    sql: ${TABLE}.cost_at_list ;;
  }

        measure: usage__amount_in_calculated_units {
          type: sum
          sql: CASE
                  -- VCPU RAM
                    WHEN usage.pricing_unit = 'gibibyte hour' THEN ${usage__amount_in_pricing_units}/24
                  -- VCPU Cores
                    WHEN usage.pricing_unit = 'hour' THEN ${usage__amount_in_pricing_units}/24
                  -- PD Storage
                  -- WHEN usage.pricing_unit = 'gibibyte month' THEN ROUND(SUM(usage.amount_in_pricing_units) * 30, 2)
                  ELSE ${usage__amount_in_pricing_units}
                END;;
                #html: <p> {{rendered_value}} {{usage__calculated_unit}} </p> ;;
            group_item_label: "Total Usage Amount in Calculated Units"
            value_format_name: decimal_0
            group_label: "Usage"
            drill_fields: [project__name,service__description,total_cost, total_usage_amount]
          }

          measure: total_usage_amount {
            type: sum
            group_label: "Usage"
            value_format_name: decimal_2
            sql: ${usage__amount} ;;
            drill_fields: [project__name,service__description,total_cost, total_usage_amount]
          }

          measure: total_usage_amount_in_pricing_units {
            type: sum
            group_label: "Usage"
            value_format_name: decimal_2
            sql: ${usage__amount_in_pricing_units} ;;
          }

          #Sidney Stefani - updating drill fields
          measure: total_cost {
            type: sum
            sql: ${cost} ;;
            value_format_name: usd_0
            #value_format: "#,##0.00"
            #html: <a href="#drillmenu" target="_self">{{ currency_symbol._value }}{{ rendered_value }}</a>;;
            drill_fields: [app_id_resource, environment, service__description,total_cost]
          }

          #Sidney Stefani - updating drill fields
          measure: total_net_cost {
            type: number
            sql: ${total_cost} - ${gcp_billing_export__credits.total_amount};;
            #value_format: "#,##0.00"
            value_format_name: usd_0
            # html: <a href="#drillmenu" target="_self">{{ currency_symbol._value }}{{ rendered_value }}</a>;;
            drill_fields: [app_id_resource, environment,total_cost, gcp_billing_export__credits.total_amount]
          }

          dimension: net_cost_dimension {
            type: number
            hidden: yes
            sql: ${cost} - ${gcp_billing_export__credits.amount} ;;
          }

###### LABELING STRATEGY######
          dimension: labeling_compliant {
            type: string
            sql: CASE
                ---ARTIFACT REGISTRY
                WHEN ${service__id} = "149C-F9EC-3994"
                AND ${app_id_resource} IS NOT NULL AND ${component_id} IS NOT NULL AND ${environment} IS NOT NULL
                 THEN "Yes"
                ---BIGTABLE
                WHEN ${service__id} = "C3BE-24A5-0975"
                AND ${app_id_resource} IS NOT NULL AND ${component_id} IS NOT NULL AND ${environment} IS NOT NULL
                THEN "Yes"
                ---DATAPROC
                 WHEN ${service__id} = "363B-8851-170D"
                 AND ${app_id_resource} IS NOT NULL AND ${component_id} IS NOT NULL AND ${environment} IS NOT NULL
                 THEN "Yes"
                 ---FILESTORE
                 WHEN ${service__id} = "D97E-AB26-5D95"
                 AND ${app_id_resource} IS NOT NULL AND ${component_id} IS NOT NULL AND ${environment} IS NOT NULL
                 THEN "Yes"
                 ---CLOUD FUNCTIONS
                 WHEN ${service__id} = "29E7-DA93-CA13"
                 AND ${app_id_resource} IS NOT NULL AND ${component_id} IS NOT NULL AND ${environment} IS NOT NULL
                 THEN "Yes"
                 ---CLOUD PUB/SUB
                 WHEN ${service__id} = "A1E8-BE35-7EBC"
                 AND ${app_id_resource} IS NOT NULL AND ${component_id} IS NOT NULL AND ${environment} IS NOT NULL
                 THEN "Yes"
                 ---CLOUD RUN
                 WHEN ${service__id} = "152E-C115-5142"
                 AND ${app_id_resource} IS NOT NULL AND ${component_id} IS NOT NULL  AND ${environment} IS NOT NULL
                 THEN "Yes"
                 ---CLOUD SPANNER
                 WHEN ${service__id} = "CC63-0873-48FD"
                 AND ${app_id_resource} IS NOT NULL AND ${component_id} IS NOT NULL AND ${environment} IS NOT NULL
                 THEN "Yes"
                 ---CLOUD SQL
                 WHEN ${service__id} = "9662-B51E-5089"
                 AND ${app_id_resource} IS NOT NULL AND ${component_id} IS NOT NULL AND ${environment} IS NOT NULL
                 THEN "Yes"
                 ---COMPUTE ENGINE
                 WHEN ${service__id} = "6F81-5844-456A"
                 AND ${app_id_resource} IS NOT NULL AND ${component_id} IS NOT NULL AND ${environment} IS NOT NULL
                 THEN "Yes"
                 ---DATAFLOW
                 WHEN ${service__id} = "57D6-8E6B-2DE0"
                 AND ${app_id_resource} IS NOT NULL AND ${component_id} IS NOT NULL AND ${environment} IS NOT NULL
                 THEN "Yes"
                 ---MEMORYSTORE REDIS
                 WHEN ${service__id} = "5AF5-2C11-D467"
                 AND ${app_id_resource} IS NOT NULL AND ${component_id} IS NOT NULL AND ${environment} IS NOT NULL
                 THEN "Yes"
                 ---CERTIFICATE AUTHORITY
                 WHEN ${service__id} = "BAE4-9668-BD24"
                 AND ${app_id_resource} IS NOT NULL AND ${component_id} IS NOT NULL AND ${environment} IS NOT NULL
                 THEN "Yes"
                 ---CLOUD KEY MANAGEMENT
                 WHEN ${service__id} = "EE2F-D110-890C"
                 AND ${cme_project_id} IS NOT NULL AND ${environment} IS NOT NULL
                 THEN "Yes"
                 ---CLOUD STORAGE
                 WHEN ${service__id} = "95FF-2EF5-5EA1"
                 AND (${app_id_resource} IS NOT NULL OR ${business_object_id} IS NOT NULL) AND ${environment} IS NOT NULL
                 THEN "Yes"
                 ---KUBERNETES
                 WHEN ${service__id} = "CCD8-9BF1-090E"
                 AND ${environment} IS NOT NULL
                 THEN "Yes"
                 ---NETWORKING
                 WHEN ${service__id} = "E505-1604-58F8"
                 AND ${app_id_resource} IS NOT NULL AND ${component_id} IS NOT NULL AND ${environment} IS NOT NULL
                 THEN "Yes"
                 ---VERTEX AI
                 WHEN ${service__id} = "C7E2-9256-1C43"
                 AND ${app_id_resource} IS NOT NULL AND ${component_id} IS NOT NULL AND ${environment} IS NOT NULL
                 THEN "Yes"
                 ---Cloud Composer
                 WHEN ${service__id} = "1992-3666-B975"
                 AND ${app_id_resource} IS NOT NULL AND ${component_id} IS NOT NULL AND ${environment} IS NOT NULL
                 THEN "Yes"
                 ---BIGQUERY ANALYSIS
                 WHEN ${sku__description} LIKE "%Analysis%" AND  ${service__id} = "24E6-581D-38E5"
                 AND ${app_id_resource} IS NOT NULL AND ${component_id} IS NOT NULL
                 THEN "Yes"
                 ---BIGQUERY Datasets
                 WHEN ${sku__description} LIKE "%Storage%" AND  ${service__id} = "24E6-581D-38E5"
                 AND ${business_object_id} IS NOT NULL AND ${environment} IS NOT NULL AND ${cme_project_id} IS NOT NULL
                 THEN "Yes"
                 ELSE "No" END ;;
              # ---Projects
              #   WHEN ${project_department_name} IS NOT NULL AND ${project_environment} IS NOT NULL
              #   THEN "Yes"
              #   ELSE "No" END ;;
            }

            dimension: app_id_compliant {
              type: string
              label: "App ID Compliant"
              drill_fields: [project__id, project__name, total_net_cost, sku__description ]
              sql: case when ${cme_labelable_services} = "Yes" AND ${app_id_resource} is NOT NULL then "Yes" Else "No" End ;;
            }

            dimension: component_id_compliant {
              type: string
              label: "Component ID Compliant"
              drill_fields: [project__id, project__name, total_net_cost, sku__description ]
              sql: case when ${cme_labelable_services} = "Yes" AND ${component_id} is NOT NULL then "Yes" Else "No" End ;;
            }

            dimension: environment_id_compliant {
              type: string
              label: "Environment ID Compliant"
              drill_fields: [project__id, project__name, total_net_cost, sku__description ]
              sql: case when ${cme_labelable_services} = "Yes" AND ${environment} is NOT NULL then "Yes" Else "No" End ;;
            }

####### PROJECT LABELS ########
  # dimension: app_id {
  #   view_label: "Labels"
  #   label: "App ID"
  #   group_label: "Project"
  #   type: string
  #   sql: (SELECT value FROM UNNEST(${project__labels}) WHERE key = 'app_id')  ;;
  # }

  # dimension: project_department_name {
  #   view_label: "Labels"
  #   group_label: "Project"
  #   label: "Department Name"
  #   type: string
  #   sql: (SELECT value FROM UNNEST(${project__labels}) WHERE key = 'department_name')  ;;
  # }

  # dimension: project_environment {
  #   view_label: "Labels"
  #   group_label: "Project"
  #   type: string
  #   sql: (SELECT value FROM UNNEST(${project__labels}) WHERE key = 'environment')  ;;
  # }

  # dimension: project_managed_by {
  #   view_label: "Labels"
  #   group_label: "Project"
  #   type: string
  #   sql: (SELECT value FROM UNNEST(${project__labels}) WHERE key = 'managed_by')  ;;
  # }

  # dimension: project_contact_name {
  #   view_label: "Labels"
  #   group_label: "Project"
  #   type: string
  #   sql: (SELECT value FROM UNNEST(${project__labels}) WHERE key = 'contact_name')  ;;
  # }

  # dimension: project_created_date {
  #   view_label: "Labels"
  #   group_label: "Project"
  #   hidden:  yes
  #   type: string
  #   sql: (SELECT value FROM UNNEST(${project__labels}) WHERE key = 'created_date')  ;;
  # }

  # dimension: project_originator{
  #   view_label: "Labels"
  #   group_label: "Project"
  #   type:  string
  #   sql:  (SELECT value FROM UNNEST(${project__labels}) WHERE key = 'originator') ;;
  # }

#####RESOURCE LABELS#######
  # dimension: originator {
  #   view_label: "Labels"
  #   group_label: "Resource"
  #   hidden:  yes
  #   type: string
  #   sql: (SELECT value FROM UNNEST(${labels}) WHERE key = 'originator') ;;
  # }

  # dimension: contact_name {
  #   view_label: "Labels"
  #   group_label: "Resource"
  #   type: string
  #   sql: (SELECT value FROM UNNEST(${labels}) WHERE key = 'contact_name') ;;
  # }

  # dimension: deployment_type {
  #   view_label: "Labels"
  #   group_label: "Resource"
  #   hidden:  yes
  #   type: string
  #   sql: (SELECT value FROM UNNEST(${labels}) WHERE key = 'deployment_type') ;;
  # }

  # dimension: environment {
  #   view_label: "Labels"
  #   group_label: "Resource"
  #   type: string
  #   sql: (SELECT value FROM UNNEST(${labels}) WHERE key = 'environment') ;;
  # }

  # dimension: app_name {
  #   view_label: "Labels"
  #   group_label: "Resource"
  #   hidden:  yes
  #   type: string
  #   sql: (SELECT value FROM UNNEST(${labels}) WHERE key = 'app_name')  ;;
  # }

  # dimension: department_name {
  #   view_label: "Labels"
  #   group_label: "Resource"
  #   type: string
  #   sql: (SELECT value FROM UNNEST(${labels}) WHERE key = 'department_name')  ;;
  # }

  # dimension: component_id {
  #   view_label: "Labels"
  #   group_label: "Resource"
  #   type: string
  #   sql: (SELECT value FROM UNNEST(${labels}) WHERE key = 'component_id') ;;
  # }

  # dimension: component_id_upper {
  #   hidden: yes
  #   sql: UPPER(${component_id}) ;;
  # }

  # dimension: created_date {
  #   view_label: "Labels"
  #   group_label: "Resource"
  #   hidden:  yes
  #   type: string
  #   sql: (SELECT value FROM UNNEST(${labels}) WHERE key = 'created_date') ;;
  # }

  # dimension: project_id {
  #   view_label: "Labels"
  #   label: "Project ID (PMGT - old)"
  #   group_label: "Resource"
  #   type: string
  #   sql: (SELECT value FROM UNNEST(${labels}) WHERE key = 'project_id') ;;
  # }

  # dimension: cme_project_id {
  #   view_label: "Labels"
  #   label: "Project ID (PMGT - new)"
  #   group_label: "Resource"
  #   type: string
  #   sql: (SELECT value FROM UNNEST(${labels}) WHERE key = 'cme_project_id') ;;
  # }

  # dimension: cme_project_id_upper {
  #   hidden: yes
  #   #Sidneyh Stefani - field used to join with the forecast data
  #   sql: UPPER(${cme_project_id}) ;;
  # }

  # dimension: app_id_resource {
  #   type: string
  #   label: "Resource App ID"
  #   view_label: "Labels"
  #   group_label: "Resource"
  #   sql:(SELECT value FROM UNNEST(${labels}) WHERE key = 'app_id')  ;;
  # }

  # #Rishi Ghai - Update dimension to include ProjectAppId if ResourceAppId is null
  # dimension: app_id_with_unallocated {
  #   type: string
  #   label: "App ID (Resource & Project)"
  #   description: "This field pulls from the resource app ID, if null then the project app ID"
  #   group_label: "Resource"
  #   view_label: "Labels"
  #   link: {
  #     label: "Usage Deep Dive"
  #     url: "https://cmegroup.cloud.looker.com/dashboards/18?Project+ID=&Service+Type=&Application+Name=&App+ID+%28Resource%29={{ app_id_with_unallocated._value }}"
  #   }
  #   sql: CASE
  #           WHEN ${app_id_resource} IS NULL AND ${app_id} IS NOT NULL THEN ${app_id}
  #           WHEN ${app_id_resource} IS NULL AND ${app_id} IS NULL THEN 'Unallocated App ID'
  #           ELSE ${app_id_resource} END;;
  # }


  # dimension: business_object_id {
  #   type:  string
  #   label: "Business Object ID"
  #   group_label: "Resource"
  #   view_label: "Labels"
  #   sql: (SELECT UPPER(value) FROM UNNEST(${labels}) WHERE key = 'business_object_id') ;;
  # }

  # dimension: business_data_id {
  #   type:  string
  #   label: "Business Data ID (old)"
  #   group_label: "Resource"
  #   view_label: "Labels"
  #   sql: (SELECT UPPER(value) FROM UNNEST(${labels}) WHERE key = 'business_data_id') ;;
  # }

  #2022-01-23 jm to support Trading FINOPS-38
  #commenting out the ones that weren't correct.
  #dimension: scorecard_sub_product {
  #  type:  string
  #  label: "Sub-Product"
  #  group_label: "Resource"
  #  view_label: "Labels"
  #  sql: (SELECT value FROM UNNEST(${labels}) WHERE key = 'scorecard_sub_product') ;;
  #}

  #dimension: scorecard_service_stream {
  #  type:  string
  #  label: "Service Stream"
  #  group_label: "Resource"
  #  view_label: "Labels"
  #  sql: (SELECT value FROM UNNEST(${labels}) WHERE key = 'scorecard_service_stream') ;;
  #}

  #2022-01-23 jm to support Trading FINOPS-38 (needs to come from detailed billing)
  # dimension: goog_k8s_namespace {
  #   type:  string
  #   label: "Goog-K8s Namespace"
  #   group_label: "Kubernetes"
  #   view_label: "Labels"
  #   sql:  (SELECT value FROM UNNEST(${labels}) WHERE key = 'goog-k8s-namespace');;
  # }

  # dimension: goog_k8s_cluster_name {
  #   type:  string
  #   label: "Goog-K8s Cluster Name"
  #   group_label: "Kubernetes"
  #   view_label: "Labels"
  #   sql:  (SELECT value FROM UNNEST(${labels}) WHERE key = 'goog-k8s-cluster-name');;
  # }

  # dimension: k8s_fq_scorecard_sub_product {
  #   type:  string
  #   label: "Sub-Product (k8s-label)"
  #   group_label: "Kubernetes"
  #   view_label: "Labels"
  #   sql: (SELECT value FROM UNNEST(${labels}) WHERE key = 'k8s-label/scorecard_sub_product') ;;
  # }

  # dimension: k8s_fq_scorecard_service_stream {
  #   type:  string
  #   label: "Service Stream (k8s-label)"
  #   group_label: "Kubernetes"
  #   view_label: "Labels"
  #   sql: (SELECT value FROM UNNEST(${labels}) WHERE key = 'k8s-label/scorecard_service_stream') ;;
  # }

  # dimension: k8s_fq_app_id {
  #   type:  string
  #   label: "App ID (k8s-label)"
  #   group_label: "Kubernetes"
  #   view_label: "Labels"
  #   sql: (SELECT value FROM UNNEST(${labels}) WHERE key = 'k8s-label/app_id') ;;
  # }

  #Tim Heyen - Update dimension to include K8 Label if not null and ProjectAppId if ResourceAppId is null

  # dimension: app_id_with_unallocated_and_k8 {
  # type: string
  # label: "App ID (K8 & Resource & Project)"
  # description: "This field pulls from the resource app ID, if null then the project app ID"
  # group_label: "Kubernetes"
  # view_label: "Labels"
  # link: {
  # label: "Usage Deep Dive"
  # url: "https://cmegroup.cloud.looker.com/dashboards/18?Project+ID=&Service+Type=&Application+Name=&App+ID+%28Resource%29={{ app_id_with_unallocated._value }}"
  # }
  # sql: CASE
  #     WHEN ${k8s_fq_app_id} IS NOT NULL THEN ${k8s_fq_app_id}
  #     WHEN ${app_id_resource} IS NULL AND ${app_id} IS NOT NULL THEN ${app_id}
  #     WHEN ${app_id_resource} IS NULL AND ${app_id} IS NULL THEN 'Unallocated App ID'
  #     ELSE ${app_id_resource} END;;
  # }

  # Start of new App Name Code

  # dimension: app_name_k8_resource_project {
  # type: string
  # label: "App Name (K8 & Resource & Project)"
  # description: "Looks up App Name based on K8_Resource_Project App ID"
  # group_label: "Kubernetes"
  # view_label: "Labels"
  # sql:  case
  #       when ${applications.app_portfolio_id_nbr}=${app_id_with_unallocated_and_k8}
  #       then ${applications.name}
  #       else NULL END;;
  # #sql: select name from applications.view where app_portfolio_id_numeric = ${app_id_with_unallocated_and_k8} ;;
  # }
  #End of new app name code


  # dimension: k8s_fq_component_id {
  #   type:  string
  #   label: "Component ID (k8s-label)"
  #   group_label: "Kubernetes"
  #   view_label: "Labels"
  #   sql: (SELECT value FROM UNNEST(${labels}) WHERE key = 'k8s-label/component_id') ;;
  # }

  # dimension: k8s_fq_contact_name {
  #             type:  string
  #             label: "Contact Name (k8s-label)"
  #             group_label: "Kubernetes"
  #             view_label: "Labels"
  #             sql: (SELECT value FROM UNNEST(${labels}) WHERE key = 'k8s-label/contact_name') ;;
  #           }

  # dimension: k8s_fq_cme_project_id {
  #             type:  string
  #             label: "CME Project ID (k8s-label)"
  #             group_label: "Kubernetes"
  #             view_label: "Labels"
  #             sql: (SELECT value FROM UNNEST(${labels}) WHERE key = 'k8s-label/cme_project_id') ;;
  #           }

  # dimension: k8s_fq_environment {
  #             type:  string
  #             label: "Environment (k8s-label)"
  #             group_label: "Kubernetes"
  #             view_label: "Labels"
  #             sql: (SELECT value FROM UNNEST(${labels}) WHERE key = 'k8s-label/environment') ;;
  #           }

  # dimension: k8s_fq_department_name {
  #             type:  string
  #             label: "Department Name (k8s-label)"
  #             group_label: "Kubernetes"
  #             view_label: "Labels"
  #             sql: (SELECT value FROM UNNEST(${labels}) WHERE key = 'k8s-label/department_name') ;;
  #           }

  #Update alias for this value
  dimension: kubernetes_cluser_name {
    type:  string
    label: "Cluster Name (Kubernetes)"
    hidden: yes
    view_label: "Labels"
    group_label: "Kubernetes"
    sql: (SELECT value from UNNEST(${labels}) WHERE key = 'goog-k8s-cluster-name') ;;
  }
  #Update alias for this value
  dimension: kubernetes_namespace {
    type:  string
    label: "Namespace (Kubernetes)"
    hidden: yes
    view_label: "Labels"
    group_label: "Resource"
    sql: (SELECT value from UNNEST(${labels}) WHERE key = 'k8s-namespace') ;;
  }

 #### System LABELS ######

  # dimension: cores {
  #   view_label: "Labels"
  #   group_label: "System"
  #   type: string
  #   sql: (SELECT value FROM UNNEST(${system_labels}) WHERE key = 'compute.googleapis.com/cores') ;;
  # }

  # dimension: is_unused_reservation {
  #   view_label: "Labels"
  #   label: "Is Unused Reservation?"
  #   group_label: "System"
  #   type: string
  #   sql: (SELECT value FROM UNNEST(${system_labels}) WHERE key = 'compute.googleapis.com/is_unused_reservation') ;;
  # }

  # dimension: machine_spec {
  #   view_label: "Labels"
  #   group_label: "System"
  #   type: string
  #   sql: (SELECT value FROM UNNEST(${system_labels}) WHERE key = 'compute.googleapis.com/machine_spec') ;;
  # }

  # dimension: memory {
  #   view_label: "Labels"
  #   group_label: "System"
  #   type: string
  #   sql: (SELECT value FROM UNNEST(${system_labels}) WHERE key = 'compute.googleapis.com/memory') ;;
  # }

####DEVELOPMENT ON EXISTING FIELDS######

            measure: total_marketplace_cost {
              type: sum
              value_format_name: usd_0
              filters: [pricing_mapping.marketplace_purchase: "Yes"]
              sql: ${cost} ;;
            }

#Tim Heyen adding another method to display whether marketplace or not
            # dimension: marketplace_indicator {
            #  type: string
            # label: "Marketplace Indicator"
            #sql: if(${total_marketplace_cost}>0,"Marketplace","Consumption");;
            #}

            #Sidney Stefani - Creating Usage & CUD Metrics
            measure: all_usage {
              type: sum
              group_label: "CUD"
              value_format_name: decimal_0
              sql: ${usage__amount}/86400 ;;
            }

  dimension: gibbybyte_month{
    type: number
    hidden: yes
    value_format_name: decimal_0
    sql: CASE WHEN ${usage__calculated_unit} = "gibibyte month" THEN ${TABLE}.usage.amount_in_pricing_units ELSE 0 END ;;
  }

  measure: gibbyte_month_stored {
    type: sum
    label: "Gibibyte Month Stored"
    group_label: "Storage Calculations"
    value_format_name: decimal_0
    sql: ${gibbybyte_month} ;;
  }

  measure: cost_per_gb {
    type: number
    label: "Cost per GB"
    group_label: "Storage Calculations"
    value_format_name: decimal_4
    sql: ${total_net_cost}/NULLIF(${gibbyte_month_stored},0)  ;;
  }

  dimension: storage_tiers {
    type: string
    sql: case when
    ${service__id} = "95FF-2EF5-5EA1"
    THEN (
      CASE WHEN ${sku__description} LIKE "%Standard%" then "Standard"
      WHEN ${sku__description} LIKE "%Nearline%" then "Nearline"
      WHEN ${sku__description} LIKE "%Coldline%" then "Coldline"
      WHEN ${sku__description} LIKE "%Archive%" then "Archive"
      ELSE NULL END
    )
    else null end ;;
  }

            measure: total_cud_credits {
              label: "Total CUD Credits"
              type: sum
              hidden: yes
              group_label: "CUD"
              value_format_name: decimal_0
              filters: [gcp_billing_export__credits.id: "Committed Usage Discount: CPU"]
              sql: ${usage__amount}/86400 ;;
            }

            measure: cud_amount_in_billing_units {
              type: sum
              hidden: yes
              group_label: "CUD"
              label: "CUD Amount in Billing Units"
              filters: [gcp_billing_export__credits.type: "Committed Usage Discount"]
              sql: ${gcp_billing_export__credits.amount} ;;
            }

            dimension: machine_type {
              type: string
              sql: case when ${sku__description} like"%N1%" then "N1"
                          when ${sku__description} like "%N2D%" then "N2D"
                          when ${sku__description} like "%N2%" then "N2"
                          when ${sku__description} like "%E2%" then "E2"
                          when ${sku__description} like "%Sole Tenant%" then "Sole Tenant"
                          when ${sku__description} like "%C2%" then "C2"
                          when ${sku__description} like "%M2%" then "M2"
                          when ${sku__description} like "%Commitment v1: Cpu in%" then "N1"
                          when ${sku__description} like "%Commitment v1: Ram in%" then "N1"
                          when ${sku__description} like "%C3%" then "C3"
                          else "Other" end;;
            }

            measure: active_commitment{
              type: sum
              value_format_name: decimal_0
              group_label: "CUD"
              sql: ${usage__amount}/86400 ;;
              filters: [sku__description: "Commitment%",
                pricing.pricing_usage_type: "Commitment"]
            }

            measure: utilizied_commitment{
              type: number
              hidden: yes
              group_label: "CUD"
              value_format_name: decimal_2
              sql: ${usage_costs}*ABS(${cud_amount_in_billing_units}) ;;
            }

            measure: usage_costs {
              type: number
              hidden: yes
              sql: case when ${total_cost} != 0 then ${all_usage}/${total_cost} else 0 end ;;
            }

            measure: eligible_on_demand_usage {
              type: number
              hidden: yes
              group_label: "CUD"
              value_format_name: decimal_2
              sql: ${all_usage}-NullIF(${utilizied_commitment},0) ;;
            }

            measure: total_cud_cost {
              type: sum
              group_label: "CUD"
              label: "Total CUD Cost"
              sql: case when LOWER(${sku__description}) LIKE "commitment%" then ${cost} else 0 end;;
              value_format_name: usd
            }

            measure: total_non_cud_cost {
              type: number
              group_label: "CUD"
              value_format_name: usd
              sql:${total_cost}-${total_cud_cost};;
              label: "Total Non CUD Cost"
            }

            measure: total_cost_at_on_demand_rates {
              type: sum
              value_format_name: usd
              group_label: "CUD"
              sql: case when LOWER(${sku__description}) LIKE "commitment%" then 0 else ${cost} end  ;;
            }

            measure: commitment_on_demand {
              type: number
              value_format_name: usd
              label: "Commitment at on Demand Rates"
              group_label: "CUD"
              sql: ${total_cost_at_on_demand_rates} - ${total_non_cud_cost} ;;
            }

            measure: cud_coverage {
              type: number
              value_format_name: percent_0
              group_label: "CUD"
              label: "CUD Coverage"
              sql: ${total_cud_cost}/NullIF(${total_cost_at_on_demand_rates},0) ;;
            }

            #Rishi Ghai - String to Date
            dimension_group: invoice_month {
              label: "Invoice"
              type: time
              #sql: ${TABLE}.invoice.month ;;
              datatype: date
              timeframes: [
                month,
                quarter,
                year
              ]
              sql: date(CAST(substring(${TABLE}.invoice.month,1,4) AS int),CAST(substring(${TABLE}.invoice.month,5,2) AS int),01);;
            }


            #Rishi Ghai- Org ID
            dimension: gcp_org_id {
              label: "GCP Org ID"
              type: string
              sql: REGEXP_EXTRACT( ${project__ancestry_numbers},"^/([0-9]+)") ;;
            }

#Tim Heyen - Org Name
            dimension: gcp_org_name {
              label: "GCP Org Name"
              type: string
              sql: case when ${gcp_org_id} = "1036178998277" then "cmegroup"
                              when ${gcp_org_id} = "1061028459868" then "sandbox"
                              else "unknown" end;;
            }

            #Sidney Stefani Adding CME Eligible Serices to be Labeled
            dimension: cme_labelable_services {
              type: string
              label: "CME Labelable Services"
              sql: case when ${service__id} = "6F81-5844-456A" then "Yes" -- Compute Engine
                    when ${service__id} = "9662-B51E-5089" then "Yes" -- Cloud SQL
                    when ${service__id} = "A1E8-BE35-7EBC" then "Yes" -- Cloud Pub/Sub
                    when ${service__id} = "BAE4-9668-BD24" then "Yes" -- Authority Service
                    when ${service__id} = "57D6-8E6B-2DE0" then "Yes" -- Cloud Dataflow
                    when ${service__id} = "5AF5-2C11-D467" then "Yes" -- Cloud Memorystore
                    when ${service__id} = "C3BE-24A5-0975" then "Yes" -- Cloud BigTable
                    when ${service__id} = "152E-C115-5142" then "Yes" -- Cloud Run
                    when ${service__id} = "E505-1604-58F8" then "Yes" -- Networking
                    when ${service__id} = "149C-F9EC-3994" then "Yes" -- Artifact Registry
                    when ${service__id} = "29E7-DA93-CA13" then "Yes" -- Cloud Functions
                    when ${service__id} = "F17B-412E-CB64" then "Yes" -- App Engine
                    when ${service__id} = "24E6-581D-38E5" then "Yes" -- BigQuery
                    when ${service__id} = "1992-3666-B975" then "Yes" -- Cloud Composer
                    when ${service__id} = "363B-8851-170D" then "Yes" -- Cloud Dataproc
                    when ${service__id} = "D97E-AB26-5D95" then "Yes" -- Cloud Filestore
                    when ${service__id} = "29E7-DA93-CA13" then "Yes" -- Cloud Functions
                    when ${service__id} = "CC63-0873-48FD" then "Yes" -- Cloud Spanner
                    when ${service__id} = "EE2F-D110-890C" then "Yes" -- Cloud KMS
                    when ${service__id} = "95FF-2EF5-5EA1" then "Yes" -- Cloud Storage
                    when ${service__id} = "CCD8-9BF1-090E" then "Yes" -- Cloud Kubernetes
                    when ${service__id} = "C7E2-9256-1C43" then "Yes" -- Vertex AI
                    else "No" end;;
            }

            dimension: before_current_month {
              type: string
              hidden: yes
              sql:  case when EXTRACT(MONTH FROM ${usage_start_raw}) < EXTRACT(MONTH FROM current_timestamp) then "Yes" else "No" end   ;;
            }

            measure: total_before_current_month {
              type: sum
              hidden: yes
              #filters: [before_current_month: "Yes"]
              sql:case when ${before_current_month} = "Yes" then (${net_cost_dimension})
                else 0 end;;
              value_format_name: usd_0
            }

          }

view: gcp_billing_export__labels {
            view_label: "Labels"

            dimension: key {
              group_label: "Billing Export"
              type: string
              sql: ${TABLE}.key ;;
            }

            dimension: value {
              group_label: "Billing Export"
              type: string
              sql: ${TABLE}.value ;;
            }}

view: gcp_billing_export__credits {
            view_label: "Credits"
            drill_fields: [id]

            dimension: pk {
              primary_key: yes
              hidden: yes
              sql: concat(${name},${gcp_billing_export.pk},${amount}) ;;
            }

            dimension: id {
              type: string
              sql: ${TABLE}.id ;;
            }

            dimension: amount {
              type: number
              sql: ${TABLE}.amount ;;
            }

            dimension: full_name {
              type: string
              sql: ${TABLE}.full_name ;;
            }

            dimension: name {
              type: string
              sql: ${TABLE}.name ;;
            }

            #Rishi Ghai - Updating for capitalization of values
            dimension: type {
              type: string
              #   sql: case when ${name} like "%Committed Usage%" then "COMMITTED_USAGE_DISCOUNT"
              #             when ${name} like "%Sustained Usage%" then "SUSTAINED_USAGE_DISCOUNT"
              #             else ${TABLE}.type end;;
              sql: case when ${TABLE}.type = 'DISCOUNT' then 'Discount'
                              when ${TABLE}.type = 'PROMOTION' then 'Promotion'
                              when ${name} like '%Committed Usage%' then 'Committed Usage Discount'
                              when ${name} like '%Sustained Usage%' then 'Sustained Usage Discount'
                              else ${TABLE}.type end;;
              drill_fields: [name]
            }

            measure: total_amount {
              label: "Total Credit Amount"
              type: sum
              #value_format: "#,##0.00"
              value_format_name: usd_0
              #html: <a href="#drillmenu" target="_self">{{ gcp_billing_export.currency_symbol._value }}{{ rendered_value }}</a>;;
              sql: -1*${amount} ;;
              drill_fields: [gcp_billing_export__credits.type,gcp_billing_export__credits.total_amount]
            }

            measure: total_sustained_use_discount {
              view_label: "Credits"
              type: sum
              value_format_name: usd_0
              #value_format: "#,##0.00"
              #html: <a href="#drillmenu" target="_self">{{ gcp_billing_export.currency_symbol._value }}{{ rendered_value }}</a>;;
              sql: -1*${amount} ;;
              filters: [gcp_billing_export__credits.type: "Sustained Usage Discount"]
              drill_fields: [gcp_billing_export__credits.id,gcp_billing_export__credits.name,total_amount]
            }

            measure: total_committed_use_discount {
              view_label: "Credits"
              type: sum
              value_format_name: usd_0
              #html: <a href="#drillmenu" target="_self">{{ gcp_billing_export.currency_symbol._value }}{{ rendered_value }}</a>;;
              sql: -1*${amount} ;;
              filters: [gcp_billing_export__credits.type: "Committed Usage Discount, COMMITTED_USAGE_DISCOUNT_DOLLAR_BASE"]
              drill_fields: [gcp_billing_export__credits.id,gcp_billing_export__credits.name,total_amount]
            }

            measure: total_promotional_credit {
              view_label: "Credits"
              type: sum
              #value_format: "#,##0.00"
              value_format_name: usd_0
              #html: <a href="#drillmenu" target="_self">{{ gcp_billing_export.currency_symbol._value }}{{ rendered_value }}</a>;;
              sql: -1*${amount} ;;
              filters: [gcp_billing_export__credits.type: "Promotion"]
              drill_fields: [gcp_billing_export__credits.id,gcp_billing_export__credits.name,total_amount]
            }

            #Rishi Ghai - Updating for capitalization of values
          }

view: gcp_billing_export__system_labels {
            view_label: "Labels"
            dimension: key {
              group_label: "System"
              type: string
              sql: ${TABLE}.key ;;
            }

            dimension: value {
              group_label: "System"
              type: string
              sql: ${TABLE}.value ;;
            }}

view: gcp_billing_export__project__labels {
            view_label: "Labels"
            dimension: key {
              group_label: "Project"
              type: string
              sql: ${TABLE}.key ;;
            }

            dimension: value {
              group_label: "Project"
              type: string
              sql: ${TABLE}.value ;;
            }}

view:  gcp_billing_export__project_ancestors {
    view_label: "Billing"
    dimension: resourceName {
      hidden:  yes
      type:  string
      sql: ${TABLE}.resource_name ;;
    }
    dimension: folderIDs {
      hidden:  yes
      type:  string
      sql: REGEXP_EXTRACT(${resourceName},r'folders/[0-9]+') ;;
    }
    dimension: displayName {
      hidden:  yes
      type:  string
      sql: ${TABLE}.display_name ;;
    }

  dimension: gcp_folders {
    label: "GCP Folders"
    type:  string
    sql: ${gcp_billing_export__project_ancestors.folderIDs} ;;
  }
}
