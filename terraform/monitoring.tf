resource "aws_cloudwatch_dashboard" "vulnerability_dashboard" {
  dashboard_name = "VulnerabilityHistoryDashboard"

  dashboard_body = jsonencode({
    "widgets" : [
      {
        "type" : "metric",
        "x" : 0,
        "y" : 0,
        "width" : 8,
        "height" : 6,
        "properties" : {
          "metrics" : [
            ["Security", "Vulnerabilities", "Type", "SAST"]
          ],
          "view" : "bar",
          "stacked" : false,
          "region" : "${var.region}",
          "stat" : "Sum",
          "period" : 300,
          "title" : "Vulnerabilities (SAST)"
        }
      },
      {
        "type" : "metric",
        "x" : 8,
        "y" : 0,
        "width" : 8,
        "height" : 6,
        "properties" : {
          "metrics" : [
            ["Security", "Vulnerabilities", "Type", "DAST"]
          ],
          "view" : "bar",
          "stacked" : false,
          "region" : "${var.region}",
          "stat" : "Sum",
          "period" : 300,
          "title" : "Vulnerabilities (DAST)"
        }
      },
      {
        "type" : "metric",
        "x" : 16,
        "y" : 0,
        "width" : 8,
        "height" : 6,
        "properties" : {
          "metrics" : [
            ["Security", "Vulnerabilities", "Type", "DependencyCheck"]
          ],
          "view" : "bar",
          "stacked" : false,
          "region" : "${var.region}",
          "stat" : "Sum",
          "period" : 300,
          "title" : "Vulnerabilities (Dependency Check)"
        }
      }
    ]
  })
}
