include: "/views/*.view.lkml"

view: +gcp_billing_export {
### Created by Tim Heyen to be able to switch between cost and usage in reports

parameter: metric {
  label: "Metric"
  view_label: "Metric Picker"
  type: unquoted
  allowed_value: {
    label: "Total Cost"
    value: "total_cost"
  }
  allowed_value: {
    label: "Usage in Pricing Units"
    value: "usage__amount_in_pricing_units"
  }
}

measure: metric_selected {
  view_label: "Metric Picker"
  sql:
    {% if metric._parameter_value == 'total_cost' %} ${total_cost}
    {% elsif metric._parameter_value == 'usage__amount_in_pricing_units' %} ${usage__amount_in_calculated_units}
    {% else %} ${total_cost}
    {% endif %} ;;
}

}
