resource "aws_cloudwatch_dashboard" "security_dashboard" {
  dashboard_name = "SecurityDashboard"

  dashboard_body = jsonencode({
    "widgets" = [
      {
        "type"   = "metric",
        "x"      = 0,
        "y"      = 0,
        "width"  = 12,
        "height" = 6,
        "properties" = {
          "metrics" = [
            [{ "expression" : "SEARCH('{Security,SAST_Vulnerabilities,Build} MetricName=\"SAST_Vulnerabilities\"', 'Sum', 300)" }]
          ],
          "title"  = "SAST Vulnerabilities per Build",
          "stat"   = "Sum",
          "region" = var.region,
          "period" = 300,
          "view"   = "timeSeries"
        }
      },
      {
        "type"   = "metric",
        "x"      = 0,
        "y"      = 6,
        "width"  = 12,
        "height" = 6,
        "properties" = {
          "metrics" = [
            [{ "expression" : "SEARCH('{Security,DepScan_Vulnerabilities,Build} MetricName=\"DepScan_Vulnerabilities\"', 'Sum', 300)" }]
          ],
          "title"  = "Dependency Scan Vulnerabilities per Build",
          "stat"   = "Sum",
          "region" = var.region,
          "period" = 300,
          "view"   = "timeSeries"
        }
      }
    ]
  })
}
