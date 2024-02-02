view: eligible_labels {
  sql_table_name: `cmegroup-billing-export.gcp_services_labeled.eligible_labels`
    ;;

  dimension: service_id {
    type: string
    sql: ${TABLE}.service_id ;;
  }

  dimension: service_name {
    type: string
    sql: ${TABLE}.service_name ;;
  }

  dimension: labeling_supported {
    label: "Is Labeling Supported?"
    description: "Mapped on a service level"
    type: yesno
    sql: ${gcp_billing_export.service__id} = ${eligible_labels.service_id}  ;;
  }
}
